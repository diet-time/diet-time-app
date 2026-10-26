import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/features/personalization/data/customer_profile_repository.dart';
import 'package:diet_time/features/personalization/data/customer_profile_service.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:diet_time/features/plans/domain/meal_plan_package.dart';
import 'package:diet_time/features/plans/domain/meal_plan_purchase_selection.dart';
import 'package:diet_time/features/checkout/domain/checkout_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'guest answers survive restart, then sync to authenticated profile once',
    () async {
      final storage = MemorySecureStorage();
      final repository = ProfileRepository();
      var service = CustomerProfileService(
        customerRepository: repository,
        storage: storage,
      );
      const answers = CustomerProfile(
        goalCode: 'LOSE_WEIGHT',
        allergens: {'NONE'},
        preferences: {'NONE'},
        allergensConfirmed: true,
        preferencesConfirmed: true,
      );
      await service.complete(answers);
      expect(repository.writes, 0);
      service = CustomerProfileService(
        customerRepository: repository,
        storage: storage,
      );
      final local = await service.load();
      expect(local!.allergens, {'NONE'});
      expect(local.allergensConfirmed, true);
      await storage.write(SecureStorageService.accessTokenKey, 'token');
      await storage.write(SecureStorageService.authenticatedUserIdKey, 'user');
      final saved = await service.load();
      expect(saved!.profileId, 'owned-profile');
      expect(repository.writes, 1);
      expect(repository.last!.allergensConfirmed, true);
      expect(repository.last!.toJson()['allergens'], isEmpty);
      await service.load();
      expect(repository.writes, 1);
    },
  );
  test(
    'failed authenticated save preserves answers for restart and retry',
    () async {
      final storage = MemorySecureStorage();
      await storage.write(SecureStorageService.accessTokenKey, 'token');
      await storage.write(SecureStorageService.authenticatedUserIdKey, 'user');
      final repository = ProfileRepository()..fail = true;
      final service = CustomerProfileService(
        customerRepository: repository,
        storage: storage,
      );
      const answers = CustomerProfile(
        allergens: {'allergen-id'},
        allergensConfirmed: true,
      );
      await expectLater(
        service.saveProgress(answers),
        throwsA(isA<CustomerProfileException>()),
      );
      expect(
        storage.values['questionnaire.user.user'],
        contains('allergen-id'),
      );
      repository.fail = false;
      final saved = await CustomerProfileService(
        customerRepository: repository,
        storage: storage,
      ).load();
      expect(saved!.allergens, {'allergen-id'});
      expect(saved.allergensConfirmed, true);
      expect(storage.values.containsKey('questionnaire.user.user'), false);
    },
  );
  test('No Allergies and individual allergens remain exclusive', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(
      personalizationControllerProvider.notifier,
    );
    controller.toggleAllergy('allergen-id');
    controller.toggleAllergy('NONE');
    expect(container.read(personalizationControllerProvider).allergens, {
      'NONE',
    });
    controller.toggleAllergy('allergen-id');
    expect(container.read(personalizationControllerProvider).allergens, {
      'allergen-id',
    });
  });
  test(
    'Qatar midnight, minimum lead one, Friday and duration stay consistent',
    () {
      final today = qatarToday(now: DateTime.utc(2026, 10, 25, 22));
      expect(today, DateTime(2026, 10, 26));
      const package = MealPlanPackage(
        mealPlanPriceId: 'price',
        name: 'Month',
        serviceDays: 24,
        totalPrice: 1000,
        dailyPrice: 40,
        currencyCode: 'QAR',
      );
      expect(
        eligibleDeliveryStart(DateTime(2026, 10, 26), package, today: today),
        false,
      );
      expect(
        eligibleDeliveryStart(DateTime(2026, 10, 27), package, today: today),
        true,
      );
      expect(
        eligibleDeliveryStart(DateTime(2026, 10, 30), package, today: today),
        false,
      );
      final schedule = calculateMealPlanServiceSchedule(
        startDate: DateTime(2026, 10, 27),
        serviceDays: 24,
        nonDeliveryWeekdays: {DateTime.friday},
      );
      expect(schedule!.serviceDates, hasLength(24));
      expect(
        schedule.serviceDates.any((d) => d.weekday == DateTime.friday),
        false,
      );
    },
  );
  test('slot labels use API times in 24-hour format', () {
    expect(
      const DeliveryTimeSlot(
        id: 'am',
        name: 'Morning',
        startTime: '07:00:00',
        endTime: '11:00:00',
      ).timeRange,
      '07:00 - 11:00',
    );
    expect(
      const DeliveryTimeSlot(
        id: 'pm',
        name: 'Evening',
        startTime: '16:00:00',
        endTime: '18:00:00',
      ).timeRange,
      '16:00 - 18:00',
    );
  });
  test('saved address slot survives JSON and edit copies', () {
    final address = CustomerDeliveryAddress.fromJson({
      'id': 'address',
      'deliveryTimeSlotId': 'pm',
    });
    expect(
      address.copyWith(isDefault: true).toRequestJson()['deliveryTimeSlotId'],
      'pm',
    );
  });
}

class MemorySecureStorage extends SecureStorageService {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

class ProfileRepository implements CustomerProfileRepository {
  int writes = 0;
  bool fail = false;
  CustomerProfile? last;
  @override
  Future<CustomerProfile?> getProfile() async =>
      last ?? const CustomerProfile(profileId: 'owned-profile');
  @override
  Future<CustomerProfile> updateProfile(CustomerProfile profile) async {
    writes++;
    if (fail) throw const CustomerProfileException();
    return last = profile.copyWith(profileId: 'owned-profile');
  }
}
