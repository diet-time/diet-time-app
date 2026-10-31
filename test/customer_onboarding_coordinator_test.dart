import 'dart:async';
import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/features/authentication/domain/auth_models.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/personalization/data/customer_profile_service.dart';
import 'package:diet_time/features/personalization/data/display_name_repository.dart';
import 'package:diet_time/features/personalization/domain/customer_onboarding.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:diet_time/features/personalization/presentation/customer_onboarding_coordinator.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:diet_time/features/personalization/presentation/profile_persistence_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _base = CustomerProfile(
  profileId: 'profile-a',
  userId: 'a',
  preferredName: 'Noor',
);
CustomerProfile _complete(String user) => _base.copyWith(
  profileId: 'profile-$user',
  userId: user,
  goalCode: 'LOSE_WEIGHT',
  genderCode: 'FEMALE',
  dateOfBirth: '1995-03-17',
  heightCm: 165,
  weightKg: 70,
  dailyRoutineCode: 'OFFICE_WORK',
  activityLevelCode: 'MOSTLY_SITTING',
  preferencesConfirmed: true,
  allergensConfirmed: true,
  onboardingStatus: 'COMPLETED',
  nextStepCode: 'PROFILE_COMPLETED',
  shouldShowOnboarding: false,
);

void main() {
  test(
    'disposing the journey ignores an outstanding profile response',
    () async {
      final remote = _Profiles(_base)..pending = Completer<CustomerProfile?>();
      final container = _container(remote);
      final request = container
          .read(customerOnboardingCoordinatorProvider.notifier)
          .check();
      await Future<void>.delayed(Duration.zero);
      container.dispose();
      remote.pending!.complete(_complete('a'));
      expect((await request).phase, CustomerOnboardingPhase.unauthenticated);
    },
  );

  test(
    'one required sequence selects the actual first incomplete question, not a late backend hint',
    () async {
      final profiles = <CustomerProfile>[_base];
      profiles.add(profiles.last.copyWith(goalCode: 'LOSE_WEIGHT'));
      profiles.add(
        profiles.last.copyWith(
          genderCode: 'FEMALE',
          dateOfBirth: '1995-03-17',
          heightCm: 165,
          weightKg: 70,
        ),
      );
      profiles.add(profiles.last.copyWith(dailyRoutineCode: 'OFFICE_WORK'));
      profiles.add(profiles.last.copyWith(activityLevelCode: 'MOSTLY_SITTING'));
      profiles.add(profiles.last.copyWith(preferencesConfirmed: true));
      for (var index = 0; index < profiles.length; index++) {
        final remote = _Profiles(
          profiles[index].copyWith(nextStepCode: 'ALLERGENS'),
        );
        final container = _container(remote);
        addTearDown(container.dispose);
        final result = await container
            .read(customerOnboardingCoordinatorProvider.notifier)
            .check();
        expect(result.phase, CustomerOnboardingPhase.questionnaireRequired);
        expect(result.questionnairePage, index + 1);
        expect(
          CustomerQuestionnaire.progress(result.profile),
          (index * 100 / 6).round(),
        );
        expect(
          CustomerQuestionnaire.previousPage(index + 1),
          index == 0 ? null : index,
        );
        expect(remote.loads, 1);
      }
    },
  );

  test(
    '100 percent and Ready require an acknowledged backend completion',
    () async {
      final captured = _complete('a').copyWith(
        onboardingStatus: 'IN_PROGRESS',
        nextStepCode: 'ALLERGENS',
        shouldShowOnboarding: true,
      );
      final remote = _Profiles(captured);
      final container = _container(remote);
      addTearDown(container.dispose);
      final coordinator = container.read(
        customerOnboardingCoordinatorProvider.notifier,
      );
      expect(
        (await coordinator.check()).phase,
        CustomerOnboardingPhase.questionnaireRequired,
      );
      expect(CustomerQuestionnaire.progress(captured), 83);
      container
          .read(personalizationControllerProvider.notifier)
          .replace(_complete('a'));
      expect(
        (await coordinator.check()).phase,
        CustomerOnboardingPhase.questionnaireRequired,
      );
      expect(container.read(customerOnboardingReadyProvider), isFalse);
      remote.profile = _complete('a');
      expect(
        (await coordinator.check(refresh: true)).phase,
        CustomerOnboardingPhase.ready,
      );
      expect(CustomerQuestionnaire.progress(remote.profile), 100);
    },
  );

  test(
    'concurrent checks share one profile request and keep the latest destination intent',
    () async {
      final remote = _Profiles(_base)..pending = Completer<CustomerProfile?>();
      final container = _container(remote);
      addTearDown(container.dispose);
      final coordinator = container.read(
        customerOnboardingCoordinatorProvider.notifier,
      );
      final first = coordinator.check();
      final second = coordinator.check();
      coordinator.begin(CustomerJourneyIntent.startNewPlan);
      await Future<void>.delayed(Duration.zero);
      expect(remote.loads, 1);
      remote.pending!.complete(_base);
      final results = await Future.wait([first, second]);
      expect(
        results.every(
          (result) =>
              result.phase == CustomerOnboardingPhase.questionnaireRequired,
        ),
        isTrue,
      );
      expect(
        container.read(customerOnboardingCoordinatorProvider).intent,
        CustomerJourneyIntent.startNewPlan,
      );
    },
  );

  test(
    'an old profile request cannot overwrite another customer after logout/login',
    () async {
      final remote = _Profiles(_base)..pending = Completer<CustomerProfile?>();
      final container = _container(remote);
      addTearDown(container.dispose);
      final coordinator = container.read(
        customerOnboardingCoordinatorProvider.notifier,
      );
      coordinator.begin(CustomerJourneyIntent.startNewPlan);
      final old = coordinator.check();
      await Future<void>.delayed(Duration.zero);
      (container.read(otpAuthControllerProvider.notifier) as _Auth).login('b');
      remote.pending!.complete(_complete('a'));
      await old;
      expect(
        container.read(profilePersistenceControllerProvider).persistedProfile,
        isNull,
      );
      remote.pending = null;
      remote.profile = _complete('b');
      final current = await coordinator.check();
      expect(current.profile!.userId, 'b');
      expect(current.intent, CustomerJourneyIntent.normalLogin);
    },
  );

  test('a late name save cannot hydrate a different customer', () async {
    final remote = _Profiles(
      const CustomerProfile(profileId: 'profile-a', userId: 'a'),
    );
    final names = _Names()..pending = Completer<CustomerProfile>();
    final container = _container(remote, names: names);
    addTearDown(container.dispose);
    final coordinator = container.read(
      customerOnboardingCoordinatorProvider.notifier,
    );
    await coordinator.check();
    final oldSave = coordinator.saveName('Noor');
    (container.read(otpAuthControllerProvider.notifier) as _Auth).login('b');
    names.pending!.complete(_base);
    expect(await oldSave, isFalse);
    expect(
      container.read(profilePersistenceControllerProvider).persistedProfile,
      isNull,
    );
    expect(
      container.read(customerOnboardingCoordinatorProvider).profile,
      isNull,
    );
  });

  test(
    'intent survives authentication recovery and is consumed only when ready',
    () async {
      final remote = _Profiles(_complete('a'));
      final container = _container(remote);
      addTearDown(container.dispose);
      final coordinator = container.read(
        customerOnboardingCoordinatorProvider.notifier,
      );
      coordinator.begin(CustomerJourneyIntent.startNewPlan);
      await coordinator.check();
      final auth = container.read(otpAuthControllerProvider.notifier) as _Auth;
      auth.expire();
      expect(
        container.read(customerOnboardingCoordinatorProvider).intent,
        CustomerJourneyIntent.startNewPlan,
      );
      expect(() => coordinator.consumeIntent(), throwsStateError);
      auth.login('a');
      await coordinator.check();
      expect(coordinator.consumeIntent(), CustomerJourneyIntent.startNewPlan);
      expect(
        container.read(customerOnboardingCoordinatorProvider).intent,
        CustomerJourneyIntent.normalLogin,
      );
      coordinator.begin(CustomerJourneyIntent.startNewPlan);
      auth.logout();
      expect(
        container.read(customerOnboardingCoordinatorProvider).intent,
        CustomerJourneyIntent.normalLogin,
      );
    },
  );

  for (final profile in <CustomerProfile?>[
    null,
    const CustomerProfile(profileId: 'profile-a', userId: 'a'),
    _base,
    _base.copyWith(goalCode: 'LOSE_WEIGHT'),
    _complete('a'),
  ]) {
    test(
      'fresh session restores persisted onboarding state: ${profile?.preferredName ?? 'no name'} / ${profile?.onboardingStatus}',
      () async {
        final remote = _Profiles(profile);
        final first = _container(remote);
        first
            .read(customerOnboardingCoordinatorProvider.notifier)
            .begin(CustomerJourneyIntent.startNewPlan);
        await first
            .read(customerOnboardingCoordinatorProvider.notifier)
            .check();
        first.dispose();
        final restored = _container(remote);
        addTearDown(restored.dispose);
        final result = await restored
            .read(customerOnboardingCoordinatorProvider.notifier)
            .check();
        expect(result.phase, CustomerOnboardingPolicy.phase(profile));
        expect(result.intent, CustomerJourneyIntent.normalLogin);
        expect(remote.loads, 2);
      },
    );
  }
}

ProviderContainer _container(_Profiles remote, {_Names? names}) =>
    ProviderContainer(
      overrides: [
        otpAuthControllerProvider.overrideWith(_Auth.new),
        customerProfileServiceProvider.overrideWithValue(remote),
        if (names != null)
          displayNameRepositoryProvider.overrideWithValue(names),
      ],
    );

class _Profiles implements ProfilePersistenceService {
  _Profiles(this.profile);
  CustomerProfile? profile;
  Completer<CustomerProfile?>? pending;
  int loads = 0;
  @override
  Future<CustomerProfile?> load() async {
    loads++;
    return pending == null ? profile : pending!.future;
  }

  @override
  Future<CustomerProfile> saveProgress(CustomerProfile value) async =>
      profile = value;
  @override
  Future<CustomerProfile> complete(CustomerProfile value) async =>
      profile = _complete('a');
}

class _Auth extends OtpAuthController {
  @override
  OtpAuthState build() => _session('a');
  void _clear() {
    ref.invalidate(profilePersistenceControllerProvider);
    ref.invalidate(personalizationControllerProvider);
  }

  void login(String id) {
    _clear();
    state = _session(id);
  }

  void logout() {
    _clear();
    state = const OtpAuthState();
  }

  void expire() {
    _clear();
    state = const OtpAuthState(sessionExpired: true);
  }

  OtpAuthState _session(String id) => OtpAuthState(
    isAuthenticated: true,
    session: AuthSession(
      accessToken: 'token-$id',
      refreshToken: 'refresh-$id',
      accessTokenExpiresAt: DateTime(2099),
      refreshTokenExpiresAt: DateTime(2099),
      user: AuthUser(
        id: id,
        email: '',
        name: '',
        roles: const ['Customer'],
        phoneNumber: '+97474452435',
      ),
    ),
  );
}

class _Names extends DisplayNameRepository {
  _Names()
    : super(apiClient: ApiClient(), secureStorage: SecureStorageService());
  Completer<CustomerProfile>? pending;
  @override
  Future<CustomerProfile> saveAuthenticatedProfileName(String name) =>
      pending!.future;
}
