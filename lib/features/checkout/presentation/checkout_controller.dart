import 'package:flutter/foundation.dart';
import 'dart:math';

import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/checkout/data/checkout_repository.dart';
import 'package:diet_time/features/checkout/data/orders_repository.dart';
import 'package:diet_time/features/checkout/domain/checkout_models.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/personalization/data/customer_profile_repository.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:diet_time/features/plans/data/meal_plan_repository.dart';
import 'package:diet_time/features/plans/domain/meal_plan_package.dart';
import 'package:diet_time/features/plans/domain/meal_plan_purchase_selection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final checkoutControllerProvider =
    NotifierProvider<CheckoutController, CheckoutState>(CheckoutController.new);

class CheckoutController extends Notifier<CheckoutState> {
  int _configurationEpoch = 0;
  @override
  CheckoutState build() => const CheckoutState();

  void selectFulfillmentMethod(String method) {
    if (method != 'TAKEAWAY' && method != 'HOME_DELIVERY') return;
    if (method == 'HOME_DELIVERY' && !state.isDeliveryEnabled) return;
    state = state.copyWith(
      fulfillmentMethod: method,
      idempotencyKey: null,
      placementError: null,
    );
  }

  void selectBranch(TakeawayBranch branch) {
    if (!state.branches.any((item) => item.id == branch.id)) return;
    state = state.copyWith(
      selectedBranch: branch,
      placementError: null,
      idempotencyKey: null,
    );
  }

  Future<void> loadBranches() async {
    if (state.isLoadingBranches) return;
    state = state.copyWith(isLoadingBranches: true, branchError: null);
    try {
      final branches = await ref
          .read(checkoutRepositoryProvider)
          .getTakeawayBranches();
      final selected = branches.where(
        (item) => item.id == state.selectedBranch?.id,
      );
      state = state.copyWith(
        branches: branches,
        selectedBranch: selected.isEmpty ? null : selected.first,
        isLoadingBranches: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingBranches: false,
        branchError: 'We could not load takeaway branches. Please try again.',
      );
    }
  }

  void clear() {
    _configurationEpoch++;
    state = const CheckoutState();
  }

  void useCustomerProfile(String? profileId) {
    if (state.customerProfileId == profileId) return;
    state = state.copyWith(
      customerProfileId: profileId,
      addresses: [],
      selectedAddressId: null,
      selectedAddress: null,
      selectedDeliveryTimeSlotId: null,
      selectedDeliveryTimeSlot: null,
      idempotencyKey: null,
    );
  }

  void selectPackage(MealPlanPurchaseSelection selection) {
    if (state.isPlacingOrder) return;
    _configurationEpoch++;
    final profile = ref.read(personalizationControllerProvider);
    if (ref.read(otpAuthControllerProvider).isAuthenticated &&
        profile.isCompleted) {
      useCustomerProfile(profile.profileId);
    }
    final samePrice =
        state.mealPlanPriceId == selection.pricingOption.mealPlanPriceId &&
        state.mealPlanTemplateId == selection.mealPlan.id &&
        state.selection?.mealCombination.id == selection.mealCombination.id;
    state = state.copyWith(
      selection: selection,
      configurationErrorCode: null,
      isResolvingOrderOptions: false,
      schedule: samePrice || state.schedule == null
          ? state.schedule
          : calculateMealPlanServiceSchedule(
              startDate: state.schedule!.startDate,
              serviceDays: selection.serviceDays,
              nonDeliveryWeekdays: {
                for (var day = 1; day <= 7; day++)
                  if (!selection.deliveryWeekdays.contains(day)) day,
              },
              unavailableDates: selection.pricingOption.unavailableDates,
            ),
      placementError: null,
      idempotencyKey: null,
      orderConfirmation: null,
    );
  }

  void beginNewOrder() {
    _configurationEpoch++;
    state = CheckoutState(
      customerProfileId: state.customerProfileId,
      addresses: state.addresses,
    );
  }

  void begin(
    MealPlanPurchaseSelection selection,
    MealPlanServiceSchedule schedule,
  ) {
    if (!eligibleDeliveryStart(schedule.startDate, selection.pricingOption)) {
      state = state.copyWith(
        schedule: null,
        placementError:
            'Choose a future delivery start date; today and Friday are unavailable.',
      );
      return;
    }
    state = state.copyWith(
      selection: selection,
      schedule: schedule,
      idempotencyKey: null,
      placementError: null,
      orderConfirmation: null,
      isResolvingOrderOptions: false,
    );
  }

  Future<void> prepareForOrder({required String language}) async {
    if (state.isResolvingOrderOptions ||
        state.selection == null ||
        state.isPlacingOrder) {
      return;
    }
    final selection = state.selection!;
    final epoch = ++_configurationEpoch;
    state = state.copyWith(
      isResolvingOrderOptions: true,
      placementError: null,
      configurationErrorCode: null,
    );
    void trace(String event, {String? code, int? status}) {
      if (kDebugMode) {
        debugPrint(
          '[CheckoutAvailability] $event planId=${selection.mealPlan.id} packageId=${selection.mealCombination.id} priceId=${selection.pricingOption.mealPlanPriceId} durationCode=${selection.pricingOption.packageCode} durationDays=${selection.serviceDays} status=$status code=$code',
        );
      }
    }

    trace('checking');
    try {
      final repository = ref.read(mealPlanRepositoryProvider);
      final configurations = selection.pricingOption.mealPlanPriceId.isNotEmpty
          ? await repository.getMealPlanConfigurations(
              mealPlanTemplateId: selection.mealPlan.id,
              language: language,
            )
          : await repository.getPurchaseOptions(
              mealPlanCode: selection.mealPlan.code,
              language: language,
              expectedTemplateId: selection.mealPlan.id,
            );
      if (epoch != _configurationEpoch ||
          !identical(state.selection, selection)) {
        return;
      }
      final matching = configurations.where(
        (item) => item.id == selection.mealCombination.id,
      );
      if (matching.isEmpty) {
        throw const _CheckoutException(
          'The selected meal package is unavailable. Please review your package.',
          code: 'package_not_available',
        );
      }
      final configuration = matching.first;
      final oldPackage = selection.pricingOption;
      final packages = configuration.packages.where(
        (item) => oldPackage.mealPlanPriceId.isNotEmpty
            ? item.mealPlanPriceId == oldPackage.mealPlanPriceId
            : item.serviceDays == oldPackage.serviceDays &&
                  item.currencyCode == oldPackage.currencyCode &&
                  (oldPackage.packageCode == null ||
                      item.packageCode == oldPackage.packageCode),
      );
      if (packages.isEmpty) {
        throw const _CheckoutException(
          'Pricing is unavailable for this duration. Please review your package.',
          code: 'pricing_not_available',
        );
      }
      final price = packages.first;
      if (price.mealPlanTemplateId != null &&
              price.mealPlanTemplateId != selection.mealPlan.id ||
          price.packageOptionId != null &&
              price.packageOptionId != configuration.id) {
        throw const _CheckoutException(
          'The selected plan and pricing do not match. Please review your package.',
        );
      }
      state = state.copyWith(
        selection: MealPlanPurchaseSelection(
          mealPlan: selection.mealPlan,
          mealCombination: MealPlanConfiguration(
            id: configuration.id,
            mealCount: configuration.mealCount,
            snackCount: configuration.snackCount,
            name: configuration.name,
            description: configuration.description,
            packages: configuration.packages,
            selectedMeals: configuration.selectedMeals.isEmpty
                ? selection.mealCombination.selectedMeals
                : configuration.selectedMeals,
          ),
          pricingOption: price,
          deliveryDaysPerWeek: selection.deliveryDaysPerWeek,
          selectedWeekdays: selection.selectedWeekdays,
        ),
        isResolvingOrderOptions: false,
        placementError: null,
        configurationErrorCode: null,
      );
      trace('validated');
    } catch (error) {
      if (epoch != _configurationEpoch ||
          !identical(state.selection, selection)) {
        return;
      }
      final code = error is _CheckoutException
          ? error.code
          : error is ApiException &&
                _configurationFailures.contains(error.code?.toLowerCase())
          ? error.code!.toLowerCase()
          : error is ApiException && error.failure == ApiFailure.notFound
          ? 'plan_not_found'
          : 'availability_check_failed';
      state = state.copyWith(
        isResolvingOrderOptions: false,
        configurationErrorCode: code,
        placementError: error is _CheckoutException
            ? error.message
            : _configurationMessage(code),
      );
      trace(
        'rejected',
        code: code,
        status: error is ApiException ? error.statusCode : null,
      );
    }
  }

  Future<void> loadDeliveryTimeSlots() async {
    if (state.isLoadingDeliveryTimeSlots) return;
    state = state.copyWith(
      isLoadingDeliveryTimeSlots: true,
      deliveryTimeSlotError: null,
    );
    try {
      final slots = await ref
          .read(checkoutRepositoryProvider)
          .getDeliveryTimeSlots();
      final selected = slots.where(
        (item) => item.id == state.selectedDeliveryTimeSlotId,
      );
      state = state.copyWith(
        deliveryTimeSlots: slots,
        isLoadingDeliveryTimeSlots: false,
        selectedDeliveryTimeSlot: selected.isEmpty ? null : selected.first,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingDeliveryTimeSlots: false,
        deliveryTimeSlotError: _message(
          error,
          fallback: 'Delivery times could not be loaded. Please try again.',
        ),
      );
    }
  }

  Future<void> loadAddresses() async {
    if (state.isLoadingAddresses) return;
    state = state.copyWith(isLoadingAddresses: true, addressError: null);
    try {
      final inMemoryProfile = ref.read(personalizationControllerProvider);
      final authUser = ref.read(otpAuthControllerProvider).user;
      var profileId =
          state.customerProfileId ??
          inMemoryProfile.profileId ??
          authUser?.customerProfileId;
      if (profileId == null || profileId.isEmpty) {
        final profile = await ref
            .read(customerProfileRepositoryProvider)
            .getProfile();
        profileId = profile?.profileId;
        if (profile != null) {
          ref.read(personalizationControllerProvider.notifier).replace(profile);
        }
      }
      if ((profileId == null || profileId.isEmpty) && authUser != null) {
        // Some authentication payloads use the customer profile identifier as
        // the user ID and omit the explicit customerProfileId alias.
        profileId = authUser.id;
      }
      if (profileId == null || profileId.isEmpty) {
        throw const _CheckoutException(
          'We could not load your customer profile. Please sign in again.',
        );
      }
      await _loadAddressesForResolvedProfile(profileId);
    } catch (error) {
      state = state.copyWith(
        isLoadingAddresses: false,
        addressError: _message(
          error,
          fallback: 'Saved addresses could not be loaded. Please try again.',
        ),
      );
    }
  }

  Future<void> loadAddressesForProfile(String profileId) async {
    final normalized = profileId.trim();
    if (normalized.isEmpty || state.isLoadingAddresses) return;
    state = state.copyWith(isLoadingAddresses: true, addressError: null);
    try {
      await _loadAddressesForResolvedProfile(normalized);
    } catch (error) {
      state = state.copyWith(
        isLoadingAddresses: false,
        addressError: _message(
          error,
          fallback: 'Saved addresses could not be loaded. Please try again.',
        ),
      );
    }
  }

  Future<void> _loadAddressesForResolvedProfile(String profileId) async {
    state = state.copyWith(customerProfileId: profileId);
    final addresses = await ref
        .read(checkoutRepositoryProvider)
        .getAddresses(profileId);
    CustomerDeliveryAddress? selected = addresses
        .where((address) => address.id == state.selectedAddressId)
        .firstOrNull;
    if (selected == null && addresses.isNotEmpty) {
      selected = addresses.firstWhere(
        (item) => item.isDefault,
        orElse: () => addresses.first,
      );
    }
    state = state.copyWith(
      customerProfileId: profileId,
      addresses: addresses,
      isLoadingAddresses: false,
      selectedAddress: selected,
      selectedAddressId: selected?.id,
    );
    if (selected != null) selectAddress(selected);
  }

  void selectAddress(CustomerDeliveryAddress address) {
    state = state.copyWith(
      selectedAddress: address,
      selectedAddressId: address.id,
      selectedDeliveryTimeSlotId:
          address.deliveryTimeSlotId ?? state.selectedDeliveryTimeSlotId,
      selectedDeliveryTimeSlot: address.deliveryTimeSlotId == null
          ? state.selectedDeliveryTimeSlot
          : state.deliveryTimeSlots
                .where((slot) => slot.id == address.deliveryTimeSlotId)
                .firstOrNull,
      idempotencyKey: null,
      placementError: null,
    );
  }

  void selectDeliveryTimeSlot(DeliveryTimeSlot slot) {
    state = state.copyWith(
      selectedDeliveryTimeSlot: slot,
      selectedDeliveryTimeSlotId: slot.id,
      idempotencyKey: null,
      placementError: null,
    );
  }

  Future<bool> saveAddress(
    CustomerDeliveryAddress address, {
    required bool editing,
  }) async {
    if (state.isSavingAddress) return false;
    final profileId = state.customerProfileId;
    if (profileId == null || profileId.isEmpty) {
      state = state.copyWith(
        saveAddressError:
            'Your customer profile is unavailable. Please sign in again.',
      );
      return false;
    }
    final slotId =
        address.deliveryTimeSlotId ?? state.selectedDeliveryTimeSlotId;
    if (slotId == null ||
        !state.deliveryTimeSlots.any((slot) => slot.id == slotId)) {
      state = state.copyWith(
        saveAddressError: 'Select an active delivery time slot before saving.',
      );
      return false;
    }
    address = address.copyWith(deliveryTimeSlotId: slotId);
    state = state.copyWith(
      isSavingAddress: true,
      saveAddressError: null,
      saveAddressFieldErrors: const {},
    );
    try {
      final repository = ref.read(checkoutRepositoryProvider);
      final saved = editing
          ? await repository.updateAddress(profileId, address)
          : await repository.createAddress(profileId, address);
      final addresses = [...state.addresses];
      final index = addresses.indexWhere((item) => item.id == saved.id);
      if (index < 0) {
        addresses.add(saved);
      } else {
        addresses[index] = saved;
      }
      state = state.copyWith(
        addresses: List.unmodifiable(addresses),
        selectedAddress: saved,
        selectedAddressId: saved.id,
        isSavingAddress: false,
        idempotencyKey: null,
        placementError: null,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isSavingAddress: false,
        saveAddressFieldErrors: error is ApiException
            ? error.fieldErrors
            : const {},
        saveAddressError: _message(
          error,
          fallback: 'Your address could not be saved. Please try again.',
        ),
      );
      return false;
    }
  }

  void clearAddressFieldError(String field) {
    state = state.copyWith(
      saveAddressError: null,
      saveAddressFieldErrors: {
        for (final entry in state.saveAddressFieldErrors.entries)
          if (entry.key.toLowerCase() != field.toLowerCase())
            entry.key: entry.value,
      },
    );
  }

  void clearAddressErrors() {
    state = state.copyWith(
      saveAddressError: null,
      saveAddressFieldErrors: const {},
    );
  }

  Future<OrderConfirmation?> placeOrder({String language = 'en'}) async {
    if (state.isPlacingOrder) return null;
    final validationMessage = state.placeOrderValidationMessage;
    if (validationMessage != null) {
      state = state.copyWith(placementError: validationMessage);
      return null;
    }

    final idempotencyKey = state.idempotencyKey ?? _uuidV4();
    state = state.copyWith(
      isPlacingOrder: true,
      placementError: null,
      idempotencyKey: idempotencyKey,
    );
    final snapshot = state;
    final request = PlaceOrderRequest(
      customerProfileId: snapshot.customerProfileId!,
      mealPlanTemplateId: snapshot.mealPlanTemplateId!,
      mealPlanPriceId: snapshot.mealPlanPriceId!,
      customerAddressId: snapshot.isTakeaway
          ? null
          : snapshot.selectedAddressId,
      fulfillmentMethod: snapshot.isTakeaway ? 'TAKEAWAY' : 'HOME_DELIVERY',
      takeawayBranchId: snapshot.isTakeaway
          ? snapshot.selectedBranch?.id
          : null,
      deliveryTimeSlotId: snapshot.isTakeaway
          ? null
          : snapshot.selectedDeliveryTimeSlotId,
      startDate: snapshot.startDate!,
      serviceDates: snapshot.schedule!.serviceDates,
      deliveryDays: snapshot.selectedWeekdays.toList()..sort(),
      // The API snapshots the purchased entitlement from the validated price.
      // Daily dish choices belong to Tomorrow's Menu, after purchase.
      meals: const [],
      couponCode: snapshot.couponCode,
      expectedTotalAmount: snapshot.selection!.pricingOption.totalPrice,
      expectedRegularPrice: snapshot.selection!.pricingOption.originalPrice,
      expectedDiscountAmount: snapshot.selection!.pricingOption.discountAmount,
      expectedCurrencyCode: snapshot.selection!.pricingOption.currencyCode,
    );

    try {
      final confirmation = await ref
          .read(ordersRepositoryProvider)
          .placeOrder(request, idempotencyKey);
      state = state.copyWith(
        selection: null,
        schedule: null,
        selectedAddressId: null,
        selectedAddress: null,
        selectedDeliveryTimeSlotId: null,
        selectedDeliveryTimeSlot: null,
        couponCode: null,
        idempotencyKey: null,
        isPlacingOrder: false,
        placementError: null,
        orderConfirmation: confirmation,
        selectedBranch: null,
      );
      return confirmation;
    } catch (error) {
      if (_isPriceChange(error)) {
        await _refreshPricing(snapshot, language: language);
      }
      state = state.copyWith(
        isPlacingOrder: false,
        placementError: _orderMessage(error),
        configurationErrorCode:
            error is ApiException &&
                _configurationFailures.contains(error.code?.toLowerCase())
            ? error.code!.toLowerCase()
            : state.configurationErrorCode,
      );
      return null;
    }
  }

  void clearPlacementError() => state = state.copyWith(placementError: null);

  bool _isPriceChange(Object error) {
    if (error is! ApiException || error.failure != ApiFailure.conflict) {
      return false;
    }
    final detail = '${error.code ?? ''} ${error.message ?? ''}'.toLowerCase();
    return detail.contains('price') &&
        (detail.contains('change') || detail.contains('stale'));
  }

  Future<void> _refreshPricing(
    CheckoutState snapshot, {
    required String language,
  }) async {
    final selection = snapshot.selection;
    final schedule = snapshot.schedule;
    if (selection == null || schedule == null) return;
    try {
      final configurations = await ref
          .read(mealPlanRepositoryProvider)
          .getMealPlanConfigurations(
            mealPlanTemplateId: selection.mealPlan.id,
            language: language,
          );
      final matchingConfigurations = configurations.where(
        (configuration) => configuration.id == selection.mealCombination.id,
      );
      if (matchingConfigurations.isEmpty) return;
      if (!identical(state.selection, snapshot.selection)) return;
      final configuration = matchingConfigurations.first;
      final matchingPackages = configuration.packages.where(
        (package) =>
            package.mealPlanPriceId == selection.pricingOption.mealPlanPriceId,
      );
      if (matchingPackages.isEmpty) return;
      final package = matchingPackages.first;
      final refreshedSchedule = calculateMealPlanServiceSchedule(
        startDate: schedule.startDate,
        serviceDays: package.serviceDays,
        nonDeliveryWeekdays: package.nonDeliveryWeekdays,
        unavailableDates: package.unavailableDates,
      );
      state = state.copyWith(
        selection: MealPlanPurchaseSelection(
          mealPlan: selection.mealPlan,
          mealCombination: configuration,
          pricingOption: package,
          deliveryDaysPerWeek: selection.deliveryDaysPerWeek,
          selectedWeekdays: selection.selectedWeekdays,
        ),
        schedule: refreshedSchedule ?? schedule,
        idempotencyKey: null,
      );
    } catch (_) {
      // Keep the existing summary visible when a refresh is unavailable.
    }
  }

  String _orderMessage(Object error) {
    if (error is! ApiException) {
      return "We couldn't place your order. Please try again.";
    }
    final detail = '${error.code ?? ''} ${error.message ?? ''}'.toLowerCase();
    final code = error.code?.trim().toLowerCase();
    if (error.failure == ApiFailure.network ||
        error.failure == ApiFailure.timeout) {
      return 'Please check your connection and try again.';
    }
    if (code != null && _configurationFailures.contains(code)) {
      return _configurationMessage(code);
    }
    if (error.failure == ApiFailure.conflict) {
      if (code == 'price_changed') {
        return 'The plan price has changed. Please review the updated total before placing your order.';
      }
      if (code == 'idempotency_conflict' ||
          detail.contains('idempoten') ||
          detail.contains('duplicate')) {
        return 'This order is already being processed. Please try again.';
      }
      return 'Your order could not be saved. Please retry or contact Diet Time.';
    }
    if (error.failure == ApiFailure.notFound) {
      if (code == 'customer_not_found') {
        return 'Your customer profile is unavailable. Please sign in again.';
      }
      if (code == 'address_not_found' || detail.contains('address')) {
        return 'The selected delivery address is no longer available.';
      }
      if (code == 'delivery_time_slot_not_found') {
        return 'The selected delivery time is no longer available.';
      }
      if (code == 'template_not_found') {
        return 'The selected plan is no longer available. Please choose another plan.';
      }
      return 'A selected checkout option is no longer available. Please review your order.';
    }
    if (code == 'invalid_meal_configuration') {
      return error.message ?? 'Please review your selected meals.';
    }
    if (code == 'invalid_delivery_days') {
      return error.message ?? 'Please review your selected service days.';
    }
    if (code == 'invalid_start_date') {
      return error.message ?? 'Please select another plan start date.';
    }
    if (code == 'coupon_not_supported') {
      return 'Coupon codes are not supported yet. Remove the coupon and try again.';
    }
    if (error.failure == ApiFailure.validation &&
        error.message?.trim().isNotEmpty == true) {
      return error.message!;
    }
    if (error.failure == ApiFailure.invalidResponse) {
      return 'Your order response could not be confirmed. Please check your orders before trying again.';
    }
    if (error.message?.trim().isNotEmpty == true) return error.message!;
    return "We couldn't place your order. Please try again.";
  }

  static const _configurationFailures = {
    'plan_not_found',
    'plan_inactive',
    'plan_not_published',
    'plan_not_effective',
    'plan_version_changed',
    'package_not_available',
    'pricing_not_available',
    'invalid_plan_configuration',
    'template_not_found',
    'template_unavailable',
    'price_not_found',
    'price_unavailable',
  };

  String _configurationMessage(String code) => switch (code) {
    'plan_not_found' || 'template_not_found' =>
      'This meal plan was not found. Please choose another plan.',
    'plan_inactive' ||
    'plan_not_published' ||
    'plan_not_effective' ||
    'plan_version_changed' ||
    'template_unavailable' =>
      'This meal plan is no longer available. Please choose another plan.',
    'package_not_available' =>
      'The selected meal package is unavailable. Please review your package.',
    'pricing_not_available' || 'price_not_found' || 'price_unavailable' =>
      'Pricing is unavailable for this duration. Please review your package.',
    'invalid_plan_configuration' =>
      'The selected plan and pricing do not match. Please review your package.',
    _ => 'We could not verify this package. Check your connection and retry.',
  };

  String _message(Object error, {required String fallback}) {
    if (error is _CheckoutException) return error.message;
    if (error is ApiException) {
      if (error.message?.trim().isNotEmpty == true) return error.message!;
      return switch (error.failure) {
        ApiFailure.network ||
        ApiFailure.timeout => 'Please check your connection and try again.',
        ApiFailure.validation =>
          'Some address information was not accepted. Please review it.',
        ApiFailure.unauthorized =>
          'Your session expired. Please sign in again.',
        _ => fallback,
      };
    }
    return fallback;
  }
}

String _uuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0'));
  final value = hex.join();
  return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
      '${value.substring(12, 16)}-${value.substring(16, 20)}-'
      '${value.substring(20)}';
}

class _CheckoutException implements Exception {
  const _CheckoutException(
    this.message, {
    this.code = 'invalid_plan_configuration',
  });
  final String code;
  final String message;
}
