import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';

typedef TourNavigator = Future<void> Function(String destination);

class TourStep {
  const TourStep(
    this.id,
    this.destination,
    this.targets, {
    this.optional = false,
  });
  final String id;
  final String destination;
  final List<String> targets;
  final bool optional;
}

const basicTourSteps = [
  TourStep('welcome', 'home', ['dashboardHeaderControls']),
  TourStep('plans', 'home', [
    'activePlansCarousel',
    'activePlan-',
    'noActivePlan',
  ]),
  TourStep('tomorrow', 'home', ['tomorrowDeliveries'], optional: true),
  TourStep('navigation', 'home', ['dashboardNavigation']),
  TourStep('orders', 'orders', ['tourOrdersList']),
  TourStep('calendar', 'calendar', [
    'tourCalendarGrid',
    'emptyDashboardCalendar',
  ]),
  TourStep('profile', 'profile', ['customerProfileOption']),
  TourStep('questionnaire', 'profile', ['customerQuestionnaireOption']),
  TourStep('addresses', 'profile', ['customerAddressOption']),
  TourStep('language', 'home', ['dashboardLanguageSelector']),
  TourStep('menu', 'menu', ['guestMealPlanHeader', 'tourMenuScreen']),
  TourStep('choosePlan', 'plans', ['mealPlan-', 'tourPlanSelection']),
  TourStep('settings', 'profile', ['appTourSetting']),
];
const detailedTourSteps = [
  TourStep('confirmation', 'home', ['confirmTomorrowMeals'], optional: true),
  TourStep('orderDetails', 'orderDetails', [
    'orderDetailsHeader',
  ], optional: true),
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
  String? get owner {
    final auth = ref.read(otpAuthControllerProvider);
    final profile = ref.read(personalizationControllerProvider);
    if (!auth.isAuthenticated ||
        auth.session == null ||
        profile.profileId == null ||
        profile.userId != auth.user?.id) {
      return null;
    }
    return '${auth.user!.id}:${profile.profileId}';
  }

  @override
  AppTourState build() {
    ref.listen(otpAuthControllerProvider.select((v) => v.user?.id), (
      previous,
      next,
    ) {
      if (previous == next) return;
      _generation++;
      _attemptedOwner = null;
      navigate = null;
      state = const AppTourState();
    });
    return const AppTourState();
  }

  void maybeStart() {
    final current = owner;
    if (current == null ||
        current == _attemptedOwner ||
        state.running ||
        state.saving ||
        !ref.read(personalizationControllerProvider).isAppTourEnabled ||
        navigate == null) {
      return;
    }
    _attemptedOwner = current;
    state = const AppTourState(running: true);
  }

  void detail(bool enabled) {
    if (!state.running || state.index != 0) {
      return;
    }
    state = AppTourState(
      running: true,
      detailed: enabled,
      steps: [
        ...basicTourSteps.take(12),
        if (enabled) ...detailedTourSteps,
        basicTourSteps.last,
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

  Future<void> setEnabled(bool enabled) async {
    final current = owner;
    if (current == null || state.saving) return;
    final generation = ++_generation;
    if (!enabled && state.running) {
      unawaited(navigate?.call('home') ?? Future.value());
    }
    state = const AppTourState(saving: true);
    try {
      final result = await ref
          .read(appTourRepositoryProvider)
          .save(
            ref.read(otpAuthControllerProvider).session!.accessToken,
            enabled,
          );
      if (generation != _generation || current != owner) return;
      final profile = ref.read(personalizationControllerProvider);
      ref
          .read(personalizationControllerProvider.notifier)
          .replace(
            profile.copyWith(
              isAppTourEnabled: result['isAppTourEnabled'] as bool,
              rowVersion: (result['rowVersion'] as num?)?.toInt(),
              updatedAt: DateTime.tryParse('${result['updatedAt']}'),
            ),
          );
      if (enabled) _attemptedOwner = null;
      state = const AppTourState();
    } catch (_) {
      if (generation == _generation && current == owner) {
        state = AppTourState(failedValue: enabled);
      }
    }
  }
}
