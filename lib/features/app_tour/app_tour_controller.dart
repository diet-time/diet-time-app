import 'dart:async';
import 'dart:convert';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';

class AppTourIdentity {
  const AppTourIdentity(this.userId, this.accessToken);
  final String userId, accessToken;
}

// App restarts restore authentication from secure storage without recreating
// AuthSession. Use that existing credential source, just like the other APIs.
final appTourIdentityProvider = FutureProvider<AppTourIdentity?>((ref) async {
  final auth = ref.watch(otpAuthControllerProvider);
  if (!auth.isAuthenticated) return null;
  if (auth.session case final session?) {
    return AppTourIdentity(session.user.id, session.accessToken);
  }
  return _storedTourIdentity(ref.watch(secureStorageServiceProvider));
});

Future<AppTourIdentity?> _storedTourIdentity(
  SecureStorageService storage,
) async {
  final values = await Future.wait([
    storage.read(SecureStorageService.authenticatedUserIdKey),
    storage.read(SecureStorageService.accessTokenKey),
  ]);
  var userId = values[0]?.trim() ?? '';
  final token = values[1]?.trim() ?? '';
  if (token.isEmpty) return null;
  if (userId.isEmpty) {
    // Older sessions may predate the identity cache. Claims only scope local
    // state; the API still validates the token and authorizes every update.
    try {
      final claims =
          jsonDecode(
                utf8.decode(
                  base64Url.decode(base64Url.normalize(token.split('.')[1])),
                ),
              )
              as Map<String, dynamic>;
      userId =
          (claims['sub'] ??
                  claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'])
              ?.toString() ??
          '';
    } catch (_) {
      return null;
    }
  }
  return userId.isEmpty ? null : AppTourIdentity(userId, token);
}

typedef TourNavigator = Future<void> Function(String destination);

class TourStep {
  const TourStep(
    this.id,
    this.destination,
    this.targets, {
    this.optional = false,
    this.nextHint,
  });
  final String id;
  final String destination;
  final List<String> targets;
  final bool optional;
  final String? nextHint;
}

const basicTourSteps = [
  TourStep('welcome', 'home', ['dashboardHeaderControls']),
  TourStep('menuButton', 'home', [
    'dashboardMenuButton',
  ], nextHint: 'menuButton.hint'),
  TourStep('menu', 'menu', ['guestMealPlanHeader', 'tourMenuScreen']),
  TourStep('language', 'home', ['dashboardLanguageSelector']),
  TourStep('plans', 'home', [
    'activePlansCarousel',
    'activePlan-',
    'noActivePlan',
  ]),
  TourStep(
    'viewDetails',
    'home',
    ['viewOrder-'],
    optional: true,
    nextHint: 'viewDetails.hint',
  ),
  TourStep('orderDetails', 'orderDetails', [
    'orderDetailsHeader',
  ], optional: true),
  TourStep('newPlan', 'home', [
    'orderAnotherPlan',
    'choosePlan',
  ], nextHint: 'newPlan.hint'),
  TourStep('choosePlan', 'plans', ['mealPlan-', 'tourPlanSelection']),
  TourStep('tomorrow', 'home', ['tomorrowDeliveries'], optional: true),
  TourStep('chooseMeals', 'home', ['chooseTomorrowMeals'], optional: true),
  TourStep('navigation', 'home', ['dashboardHomeTab']),
  TourStep('orders', 'orders', ['dashboardOrdersTab']),
  TourStep('calendar', 'calendar', ['dashboardCalendarTab']),
  TourStep('profileTab', 'profile', ['dashboardProfileTab']),
  TourStep('profile', 'profile', ['customerProfileOption']),
  TourStep('questionnaire', 'profile', ['customerQuestionnaireOption']),
  TourStep('addresses', 'profile', ['customerAddressOption']),
  TourStep('settings', 'profile', ['appTourSetting']),
];
const detailedTourSteps = [
  TourStep('confirmation', 'home', ['confirmTomorrowMeals'], optional: true),
  TourStep('calendarNavigation', 'calendar', [
    'nextDeliveryMonth',
  ], optional: true),
  TourStep('calendarIndicators', 'calendar', [
    'tourCalendarLegend',
  ], optional: true),
  TourStep('calendarDetails', 'calendar', ['calendarOrder-'], optional: true),
  TourStep('assigned', 'calendar', ['assigned-'], optional: true),
  TourStep('customize', 'calendar', ['tourChangeMeal'], optional: true),
  TourStep('nutrition', 'calendar', ['tourDailyNutrition'], optional: true),
  TourStep('menuDates', 'menu', ['guestDateScroller'], optional: true),
  TourStep('menuFilters', 'menu', ['guestMealTypeScroller'], optional: true),
  TourStep('menuNutrition', 'menu', ['tourMenuNutrition-'], optional: true),
];

class AppTourState {
  const AppTourState({
    this.running = false,
    this.index = 0,
    this.steps = basicTourSteps,
    this.detailed = false,
    this.saving = false,
    this.failedValue,
  });
  final bool running, detailed, saving;
  final int index;
  final List<TourStep> steps;
  final bool? failedValue;
  TourStep get step => steps[index];
}

final appTourRepositoryProvider = Provider(
  (ref) => AppTourRepository(ref.read(apiClientProvider)),
);

class AppTourRepository {
  AppTourRepository(this.client);
  final ApiClient client;
  Future<Map<String, dynamic>> save(String token, bool enabled) async {
    final response = await client.request(
      method: 'PATCH',
      path: '/api/v1/customer/profile/app-tour',
      headers: {'Authorization': 'Bearer $token'},
      body: {'isAppTourEnabled': enabled},
    );
    if (!response.isSuccess) throw ApiException.fromResponse(response);
    final data = response.body['data'];
    if (data is! Map<String, dynamic> || data['isAppTourEnabled'] is! bool) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    return data;
  }
}

final appTourControllerProvider =
    NotifierProvider<AppTourController, AppTourState>(AppTourController.new);

class AppTourController extends Notifier<AppTourState> {
  TourNavigator? navigate;
  String? _attemptedOwner;
  int _generation = 0;
  List<TourStep> _baseSteps = basicTourSteps;
  bool? _hasActivePlan;
  String? get owner {
    final auth = ref.read(otpAuthControllerProvider);
    final profile = ref.read(personalizationControllerProvider);
    final identity = auth.session == null
        ? ref.read(appTourIdentityProvider).value
        : AppTourIdentity(auth.user!.id, auth.session!.accessToken);
    if (!auth.isAuthenticated ||
        identity == null ||
        profile.profileId == null ||
        profile.userId != identity.userId) {
      return null;
    }
    return '${identity.userId}:${profile.profileId}';
  }

  @override
  AppTourState build() {
    ref.listen(
      otpAuthControllerProvider.select((v) => (v.isAuthenticated, v.user?.id)),
      (previous, next) {
        if (previous == next) return;
        _generation++;
        _attemptedOwner = null;
        navigate = null;
        state = const AppTourState();
      },
    );
    return const AppTourState();
  }

  void maybeStart({bool? hasPlanCards, bool? hasActivePlan}) {
    final current = owner;
    if (current == null ||
        current == _attemptedOwner ||
        state.running ||
        state.saving ||
        !ref.read(personalizationControllerProvider).isCompleted ||
        !ref.read(personalizationControllerProvider).isAppTourEnabled ||
        navigate == null) {
      return;
    }
    _attemptedOwner = current;
    _hasActivePlan = hasActivePlan;
    _baseSteps = [
      for (final step in basicTourSteps)
        if (!(hasPlanCards == false &&
                const {'viewDetails', 'orderDetails'}.contains(step.id)) &&
            !(hasActivePlan == false &&
                const {'tomorrow', 'chooseMeals'}.contains(step.id)))
          step,
    ];
    state = AppTourState(running: true, steps: _baseSteps);
  }

  void detail(bool enabled) {
    if (!state.running || state.index != 0) {
      return;
    }
    state = AppTourState(
      running: true,
      detailed: enabled,
      steps: [
        ..._baseSteps.take(_baseSteps.length - 1),
        if (enabled)
          ...detailedTourSteps.where(
            (step) => _hasActivePlan != false || step.id != 'confirmation',
          ),
        _baseSteps.last,
      ],
    );
  }

  void move(int delta) {
    if (!state.running) return;
    final index = state.index + delta;
    if (index < 0 || index >= state.steps.length) return;
    state = AppTourState(
      running: true,
      index: index,
      steps: state.steps,
      detailed: state.detailed,
    );
  }

  void unavailable() {
    if (!state.running || !state.step.optional) return;
    final steps = [...state.steps]..removeAt(state.index);
    state = AppTourState(
      running: true,
      index: state.index.clamp(0, steps.length - 1),
      steps: steps,
      detailed: state.detailed,
    );
  }

  Future<void> finish() async {
    if (!state.running) return;
    state = const AppTourState();
    // Dismiss before awaiting network; keep the persisted switch value until save succeeds.
    unawaited(navigate?.call('home') ?? Future.value());
    await setEnabled(false);
  }

  Future<bool> setEnabled(bool enabled) async {
    if (state.saving) return false;
    final generation = ++_generation;
    final originalProfile = ref.read(personalizationControllerProvider);
    if (!enabled && state.running) {
      unawaited(navigate?.call('home') ?? Future.value());
    }
    state = const AppTourState(saving: true);
    try {
      final session = ref.read(otpAuthControllerProvider).session;
      final identity = session != null
          ? AppTourIdentity(session.user.id, session.accessToken)
          : await _storedTourIdentity(ref.read(secureStorageServiceProvider));
      if (generation != _generation) return false;
      final profile = ref.read(personalizationControllerProvider);
      if (identity == null ||
          !ref.read(otpAuthControllerProvider).isAuthenticated ||
          profile.profileId == null ||
          profile.profileId != originalProfile.profileId ||
          profile.userId != originalProfile.userId ||
          profile.userId != identity.userId) {
        throw const ApiException(ApiFailure.unauthorized);
      }
      final result = await ref
          .read(appTourRepositoryProvider)
          .save(identity.accessToken, enabled);
      if (generation != _generation) return false;
      final latestProfile = ref.read(personalizationControllerProvider);
      final latestAuth = ref.read(otpAuthControllerProvider);
      if (!latestAuth.isAuthenticated ||
          latestProfile.profileId != originalProfile.profileId ||
          latestProfile.userId != identity.userId ||
          latestAuth.user != null && latestAuth.user!.id != identity.userId) {
        state = AppTourState(failedValue: enabled);
        return false;
      }
      ref
          .read(personalizationControllerProvider.notifier)
          .replace(
            ref
                .read(personalizationControllerProvider)
                .copyWith(
                  isAppTourEnabled: result['isAppTourEnabled'] as bool,
                  rowVersion: (result['rowVersion'] as num?)?.toInt(),
                  updatedAt: DateTime.tryParse('${result['updatedAt']}'),
                ),
          );
      if (enabled) _attemptedOwner = null;
      state = const AppTourState();
      return result['isAppTourEnabled'] == enabled;
    } catch (_) {
      if (generation == _generation) state = AppTourState(failedValue: enabled);
      return false;
    }
  }
}
