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
  @override
  CheckoutState build() => const CheckoutState();

  void beginNewOrder() {
    state = CheckoutState(
      customerProfileId: state.customerProfileId,
      addresses: state.addresses,
    );
  }

  void begin(
    MealPlanPurchaseSelection selection,
    MealPlanServiceSchedule schedule,
  ) {
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
        state.mealPlanPriceId?.trim().isNotEmpty == true) {
      return;
    }
    final snapshot = state;
    final selection = snapshot.selection!;
    state = state.copyWith(isResolvingOrderOptions: true, placementError: null);
    try {
      final configurations = await ref
          .read(mealPlanRepositoryProvider)
          .getPurchaseOptions(
            mealPlanCode: selection.mealPlan.code,
            language: language,
          );
      final matchingConfigurations = configurations.where(
        (item) => item.id == selection.mealCombination.id,
      );
      if (matchingConfigurations.isEmpty) {
        throw const _CheckoutException(
          'The selected meal configuration is no longer available.',
        );
      }
      final configuration = matchingConfigurations.first;
      final selectedPackage = selection.pricingOption;
      final matchingPackages = configuration.packages.where(
        (item) =>
            item.serviceDays == selectedPackage.serviceDays &&
            item.currencyCode == selectedPackage.currencyCode,
      );
      if (matchingPackages.isEmpty) {
        throw const _CheckoutException(
          'The selected plan duration is no longer available.',
        );
      }
      final authoritativePackage = matchingPackages.first;
      final authoritativeConfiguration = MealPlanConfiguration(
        id: configuration.id,
        name: configuration.name,
        description: configuration.description,
        packages: configuration.packages,
        selectedMeals: selection.mealCombination.selectedMeals,
      );
      state = state.copyWith(
        selection: MealPlanPurchaseSelection(
          mealPlan: selection.mealPlan,
          mealCombination: authoritativeConfiguration,
          pricingOption: authoritativePackage,
          deliveryDaysPerWeek: selection.deliveryDaysPerWeek,
          selectedWeekdays: selection.selectedWeekdays,
        ),
        isResolvingOrderOptions: false,
        placementError: null,
        idempotencyKey: null,
      );
    } catch (error) {
      state = state.copyWith(
        isResolvingOrderOptions: false,
        placementError: error is _CheckoutException
            ? error.message
            : 'We could not verify the selected plan. Please try again.',
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
        selectedDeliveryTimeSlot: selected.isEmpty
            ? state.selectedDeliveryTimeSlot
            : selected.first,
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
      final addresses = await ref
          .read(checkoutRepositoryProvider)
          .getAddresses(profileId);
      CustomerDeliveryAddress? selected = state.selectedAddress;
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

  void selectAddress(CustomerDeliveryAddress address) {
    state = state.copyWith(
      selectedAddress: address,
      selectedAddressId: address.id,
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
    state = state.copyWith(isSavingAddress: true, saveAddressError: null);
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
        saveAddressError: _message(
          error,
          fallback: 'Your address could not be saved. Please try again.',
        ),
      );
      return false;
    }
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
      customerAddressId: snapshot.selectedAddressId!,
      deliveryTimeSlotId: snapshot.selectedDeliveryTimeSlotId!,
      startDate: snapshot.startDate!,
      deliveryDays: snapshot.selectedWeekdays.toList()..sort(),
      meals: snapshot.selectedMeals
          .map(
            (meal) => PlaceOrderMealRequest(
              mealTypeId: meal.mealTypeId,
              quantity: meal.quantity,
            ),
          )
          .toList(growable: false),
      couponCode: snapshot.couponCode,
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
      );
      return confirmation;
    } catch (error) {
      if (_isPriceChange(error)) {
        await _refreshPricing(snapshot, language: language);
      }
      state = state.copyWith(
        isPlacingOrder: false,
        placementError: _orderMessage(error),
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
    if (error.failure == ApiFailure.conflict) {
      if (detail.contains('price') &&
          (detail.contains('change') || detail.contains('stale'))) {
        return 'The plan price has changed. Please review the updated total before placing your order.';
      }
      if (detail.contains('idempoten') || detail.contains('duplicate')) {
        return 'This order is already being processed. Please try again.';
      }
      return 'The selected plan is no longer available. Please choose another plan.';
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
      if (code == 'template_not_found' || code == 'price_not_found') {
        return 'The selected plan is no longer available. Please choose another plan.';
      }
      return 'A selected checkout option is no longer available. Please review your order.';
    }
    if (code == 'invalid_meal_configuration') {
      return error.message ?? 'Please review your selected meals.';
    }
    if (code == 'invalid_delivery_days') {
      return error.message ?? 'Please review your selected delivery days.';
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
  const _CheckoutException(this.message);
  final String message;
}
