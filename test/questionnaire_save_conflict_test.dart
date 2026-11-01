import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_time/features/personalization/data/customer_profile_repository.dart';
import 'package:diet_time/features/personalization/data/customer_profile_service.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:diet_time/features/personalization/presentation/profile_persistence_controller.dart';

const original = CustomerProfile(
  profileId: 'profile',
  userId: 'customer',
  preferredName: 'Noor',
  goalCode: 'LOSE_WEIGHT',
  genderCode: 'FEMALE',
  dateOfBirth: '1995-01-01',
  heightCm: 165,
  weightKg: 70,
  dailyRoutineCode: 'OFFICE_WORK',
  activityLevelCode: 'MOSTLY_SITTING',
  allergens: {'milk'},
  rowVersion: 1,
);

void main() {
  test(
    'disjoint conflict keeps local answers and unrelated latest profile fields',
    () async {
      final repository = _Repository()..conflicts = 1;
      final container = _setup(repository);
      addTearDown(container.dispose);
      editPreferences(container);
      expect(
        await container
            .read(profilePersistenceControllerProvider.notifier)
            .save(complete: false),
        isTrue,
      );
      expect(repository.requests.map((p) => p.rowVersion), [1, 4]);
      expect(repository.gets, 1);
      final saved = container
          .read(profilePersistenceControllerProvider)
          .persistedProfile!;
      expect(saved.rowVersion, 5);
      expect(saved.preferredName, 'Updated name');
      expect(saved.isAppTourEnabled, isFalse);
      expect(saved.preferredLanguage, 'ar');
      expect(saved.goalCode, 'MAINTAIN_WEIGHT');
      expect(saved.preferences, {'HIGH_PROTEIN'});
      expect(saved.allergens, {'peanuts'});
      expect(container.read(personalizationControllerProvider).rowVersion, 5);
      await container
          .read(profilePersistenceControllerProvider.notifier)
          .save(complete: false);
      expect(repository.requests.last.rowVersion, 5);
    },
  );

  test(
    'same-answer conflict preserves input for review without automatic overwrite',
    () async {
      final repository = _Repository()..conflicts = 1;
      repository.remote = repository.remote.copyWith(
        preferences: {'VEGETARIAN'},
        preferencesConfirmed: true,
      );
      final container = _setup(repository);
      addTearDown(container.dispose);
      editPreferences(container);
      final controller = container.read(
        profilePersistenceControllerProvider.notifier,
      );
      expect(await controller.save(complete: false), isFalse);
      expect(repository.requests.length, 1);
      expect(repository.remote.preferences, {'VEGETARIAN'});
      expect(container.read(personalizationControllerProvider).preferences, {
        'HIGH_PROTEIN',
      });
      expect(container.read(personalizationControllerProvider).rowVersion, 4);
      expect(
        container.read(profilePersistenceControllerProvider).errorMessage,
        isNotNull,
      );
      // The customer's explicit retry uses the newly retrieved version.
      expect(await controller.save(complete: false), isTrue);
      expect(repository.requests.last.rowVersion, 4);
      expect(repository.remote.preferences, {'HIGH_PROTEIN'});
    },
  );

  test('a repeated conflict stops after one retry and keeps answers', () async {
    final repository = _Repository()..conflicts = 10;
    final container = _setup(repository);
    addTearDown(container.dispose);
    editPreferences(container);
    expect(
      await container
          .read(profilePersistenceControllerProvider.notifier)
          .save(complete: false),
      isFalse,
    );
    expect(repository.requests.length, 2);
    expect(repository.gets, 1);
    expect(container.read(personalizationControllerProvider).preferences, {
      'HIGH_PROTEIN',
    });
  });

  test(
    'database constraint failures are not retried as concurrency conflicts',
    () async {
      final repository = _Repository()
        ..conflicts = 1
        ..code = 'database_conflict';
      final container = _setup(repository);
      addTearDown(container.dispose);
      editPreferences(container);
      expect(
        await container
            .read(profilePersistenceControllerProvider.notifier)
            .save(complete: false),
        isFalse,
      );
      expect(repository.requests.length, 1);
      expect(repository.gets, 0);
    },
  );

  test(
    'rapid saves and a profile reload cannot overlap a questionnaire write',
    () async {
      final repository = _Repository()..pending = Completer<void>();
      final container = _setup(repository);
      addTearDown(container.dispose);
      editPreferences(container);
      final controller = container.read(
        profilePersistenceControllerProvider.notifier,
      );
      final first = controller.save(complete: false);
      expect(await controller.save(complete: false), isFalse);
      final loading = controller.load();
      await Future<void>.delayed(Duration.zero);
      expect(repository.requests.length, 1);
      expect(repository.gets, 0);
      repository.pending!.complete();
      expect(await first, isTrue);
      expect((await loading)!.rowVersion, 5);
      expect(repository.maximumConcurrentWrites, 1);
    },
  );
}

void editPreferences(ProviderContainer container) {
  final controller = container.read(personalizationControllerProvider.notifier);
  controller.togglePreference('HIGH_PROTEIN');
  controller.confirmPreferences();
}

ProviderContainer _setup(_Repository repository) {
  final container = ProviderContainer(
    overrides: [
      customerProfileRepositoryProvider.overrideWithValue(repository),
      customerProfileServiceProvider.overrideWithValue(
        CustomerProfileService(customerRepository: repository),
      ),
    ],
  );
  container
      .read(profilePersistenceControllerProvider.notifier)
      .restore(original);
  return container;
}

class _Repository implements CustomerProfileRepository {
  CustomerProfile remote = original.copyWith(
    rowVersion: 4,
    preferredName: 'Updated name',
    isAppTourEnabled: false,
    preferredLanguage: 'ar',
    goalCode: 'MAINTAIN_WEIGHT',
    allergens: {'peanuts'},
  );
  final requests = <CustomerProfile>[];
  int conflicts = 0, gets = 0, active = 0, maximumConcurrentWrites = 0;
  String code = 'concurrency_conflict';
  Completer<void>? pending;
  @override
  Future<CustomerProfile?> getProfile() async {
    gets++;
    return remote;
  }

  @override
  Future<CustomerProfile> updateProfile(CustomerProfile profile) async {
    requests.add(profile);
    active++;
    if (active > maximumConcurrentWrites) maximumConcurrentWrites = active;
    try {
      if (pending != null) await pending!.future;
      if (conflicts-- > 0) {
        throw CustomerProfileException(statusCode: 409, code: code);
      }
      return remote = profile.copyWith(
        rowVersion: (remote.rowVersion ?? 0) + 1,
      );
    } finally {
      active--;
    }
  }
}
