import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/checkout/data/checkout_repository.dart';
import 'package:diet_time/features/checkout/domain/checkout_models.dart';
import 'package:diet_time/features/personalization/data/customer_profile_repository.dart';
import 'package:diet_time/features/plans/domain/meal_plan_purchase_selection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final checkoutControllerProvider =
    NotifierProvider<CheckoutController, CheckoutState>(CheckoutController.new);

class CheckoutController extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutState();

  void begin(
    MealPlanPurchaseSelection selection,
    MealPlanServiceSchedule schedule,
  ) {
    state = state.copyWith(selection: selection, schedule: schedule);
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
      var profileId = state.customerProfileId;
      if (profileId == null || profileId.isEmpty) {
        final profile = await ref
            .read(customerProfileRepositoryProvider)
            .getProfile();
        profileId = profile?.profileId;
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
    );
  }

  void selectDeliveryTimeSlot(DeliveryTimeSlot slot) {
    state = state.copyWith(
      selectedDeliveryTimeSlot: slot,
      selectedDeliveryTimeSlotId: slot.id,
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

class _CheckoutException implements Exception {
  const _CheckoutException(this.message);
  final String message;
}
