# Customer journey audit

## Investigation before implementation

The current app was traced from splash through authentication, questionnaire,
dashboard, checkout and logout before changing those screens.

| Entry/path | Current decision owner | Problem |
| --- | --- | --- |
| Splash/session restore | `SplashScreen._openAuthenticatedDestination` | Correctly distinguishes guest/restored session; restored session then enters the landing gate. |
| Phone login → OTP | `PhoneLoginPage`, `OtpVerificationPage._verify` | OTP goes directly to authenticated landing or Start Plan; it bypasses the legacy name gate. |
| Legacy login → `/post-login` | `PostLoginNameGate` | Separately fetches the name and can fall back to a device-wide cached name. This is not an authoritative per-customer onboarding decision. |
| Normal login and Start Plan | `AuthenticatedLandingScreen._resolve` | Checks questionnaire completion but never requires a name. Destination is carried partly in route extras. |
| Setup questionnaire | `PersonalizationScreen._loadProfile`, `_continueStep` | Independently loads, authenticates, decides completion, selects a page and redirects. |
| Dashboard | `CustomerDashboardController.initialize`, dashboard build callbacks | Another profile load/completion decision and redirect to setup; no name requirement. |
| Plan list/details and route guard | Widget guards and router guard | Repeat authentication/profile predicates rather than consume one onboarding policy. |
| Checkout entry | `CheckoutAccessService` and entry screen | Independently decides login/questionnaire/summary; must hand unmet onboarding to the same coordinator. |
| Logout/recovery | OTP sign-out, profile controller logout | Clear profile/session state; outstanding asynchronous checks need account-generation guards. |
| Tour | Dashboard callbacks and `AppTourController.maybeStart` | Already checks questionnaire and route readiness, but also needs the required-name policy. |

### Root causes

1. `DisplayNamePanel` exists, but active OTP routes bypass `PostLoginNameGate`.
   Missing names are not part of the current landing/dashboard/order predicates.
2. The actual questionnaire widgets are Goal (page 1), Basic Details/Measurements
   (page 2), Routine, Activity, Preferences, Allergens. The API's `NextStep` checks
   Basic Details before Goal. Setup follows that code, so a new customer sees page
   2, then page 1 after saving. Legacy initialization follows yet another rule.
3. Questionnaire UI is built with page 0 before the asynchronous load chooses a
   page. Progress is based on a physical page index across welcome/questions/BMI/
   success, rather than persisted required answers.
4. Multiple independent callbacks can re-evaluate state or navigate while another
   screen is active. Loading, saving and account changes need shared serialization
   and stale-result protection, not more independent route patches.
5. Legacy name loading treats any 404 as missing and can use a global local name
   after API failure. The consolidated flow must use the authenticated profile
   response and the existing stable `profile_not_found` code.

### API and PostgreSQL findings

Authentication creates `ApplicationUser`/`UserProfile`; a customer profile may
legitimately be absent. Existing authenticated GET/PUT `/api/v1/customer/profile`
and PATCH `/api/v1/customer/profile/preferred-name` cover retrieval, creation,
updates and name saving. The name PATCH creates a missing profile and preserves
questionnaire fields. No competing creation endpoint is needed.

`public.customer_profiles.user_id` references the authenticated user and has the
unique filtered index `ux_customer_profiles_user`. Writes use a per-user advisory
transaction lock and row locks. Existing create-only upserts preserve the winning
profile on retry. Names, demographics, preferences, allergens, confirmation flags,
onboarding status and completion timestamp already exist. No schema migration is
justified. Legacy completed profiles remain compatible; a new completion must
save both explicit confirmations.

The removed resume-plan controller/banner remain absent. Checkout selection is
transient state for an authenticated order, not an authentication return payload.
Order placement checks request idempotency and purchase eligibility, not absence
of other active/pending orders. Approval, payment and schedules are out of scope.

## Unified design

One Riverpod coordinator owns authentication/profile/name/questionnaire policy
and transient `NormalLogin`/`StartNewPlan` intent. Logical states are:

`Unauthenticated → LoadingProfile → ProfileRequired/NameRequired →
QuestionnaireRequired → Ready`, with `RecoverableError` for real failures.

- One gateway renders the existing name panel or navigates to the existing
  questionnaire/final destination. Legacy automatic routes delegate to it.
- Persisted profile responses determine readiness. Device name caches and local
  questionnaire edits cannot mark onboarding complete.
- One questionnaire sequence matches the existing widgets: Goal, Basic Details,
  Routine, Activity, Preferences, Allergens. The API next-step ordering must agree.
  This sequence is compiled in the existing app, not database-configurable.
- Questionnaire data and initial page are resolved before questions render.
  Progress derives from saved required answers; 100% requires backend completion.
- Name saves use the existing PATCH and hydrate shared profile state from its
  response. Errors retain the entered name; repeated taps cannot duplicate saves.
- Concurrent checks share work. Account generation guards discard late responses
  after logout/account switch. Restart defaults to Dashboard and reloads backend
  state; the transient intent is consumed only at the final destination.
- Dashboard, route guards, order entry and tour use the same readiness policy.
  They do not independently decide which questionnaire step to open.

## Verification plan

Automate both intents for missing/existing profiles, missing/invalid/valid names,
each incomplete required step, completed questionnaires, request/save failures,
rapid taps, backward navigation, stale callbacks/account switch, cached-state
restarts, English/Arabic and existing-order/new-plan behavior. Retain checkout,
tour and profile regression tests. Record only tests actually executed.

Manual release verification still required: real OTP delivery and interrupted
OTP sessions, process termination during name/questionnaire saves, another device,
live PostgreSQL concurrency, iOS TestFlight and Android release navigation,
keyboard/back gestures, accessibility and real tour overlays. Windows unit/widget
tests cannot establish those device/release outcomes.

## Implementation and changed files

The coordinator and policy now own the automatic journey. Explicit profile editing
still uses the existing questionnaire UI. Removed the legacy independent name gate
and route resolver rather than retaining competing automatic decisions.

Flutter production files (paths relative to `lib/`):

- `app/app.dart`, `app/router/app_router.dart`
- `features/authentication/presentation/login_screen.dart`,
  `otp_auth_controller.dart`, `phone_login_page.dart`
- `features/personalization/domain/customer_onboarding.dart` (new);
  `onboarding_route_resolver.dart` (removed)
- `features/personalization/data/display_name_repository.dart`
- `features/personalization/presentation/customer_onboarding_coordinator.dart`
  (new), `authenticated_landing_screen.dart`, `display_name_panel.dart`,
  `profile_persistence_controller.dart`; `post_login_name_gate.dart` (removed)
- `features/onboarding/presentation/onboarding_screen.dart`
- `features/dashboard/presentation/customer_dashboard_controller.dart`,
  `customer_dashboard_screen.dart`
- `features/checkout/presentation/checkout_entry_screen.dart`
- `features/plans/presentation/meal_plan_screen.dart`,
  `meal_plan_details_screen.dart`
- `features/app_tour/app_tour_controller.dart`, `app_tour_host.dart`

Flutter regression files under `test/`: new `customer_name_onboarding_test.dart`
and `customer_onboarding_coordinator_test.dart`; updated `app_tour_test.dart`,
`customer_dashboard_test.dart`, `customer_profile_persistence_test.dart`,
`new_customer_onboarding_test.dart`, `otp_flow_test.dart`,
`questionnaire_checkout_flow_test.dart`, `support/ordering_customer.dart`,
`widget_test.dart`; removed obsolete `post_login_name_gate_test.dart`.

ASP.NET Core files in the sibling `diet-time-api` repository:

- `src/BuildingBlocks/DietTime.Domain/CustomerQuestionnaireRules.cs` aligns
  next-step ordering with the existing Goal-first UI.
- `src/BuildingBlocks/DietTime.Application/Validation.cs` validates meaningful
  names, including Arabic, without accepting a phone number as a name.
- `src/BuildingBlocks/DietTime.Persistence/CustomerProfileService.cs` requires
  both confirmations before a newly completed questionnaire can be persisted;
  preserves legacy completed profiles and existing transaction/identity rules.
- `tests/DietTime.UnitTests/CustomerOnboardingSequenceTests.cs` (new),
  `QuestionnaireCompletionTests.cs`, and
  `tests/DietTime.Meal.Api.IntegrationTests/CustomerProfileApiTests.cs`.

No database migration, replacement screen, pending-plan record, automatic order,
payment change or approval change was introduced. The obsolete Resume Selected
Plan controller/banner remain absent. Name collection precedes all questions;
required questions follow Goal, Basic Details, Routine, Activity, Preferences,
Allergens. StartNewPlan finishes at Plan Selection; NormalLogin at Dashboard.

## Executed verification

- Full Flutter unit/widget suite: **438 passed**, including disposal of an
  outstanding onboarding request.
- Direct Dart static analysis with `--fatal-infos`: **no issues**.
- ASP.NET Core unit suite: **245 passed**.
- API database integration project: **build succeeded**, with eight existing
  unused-parameter/variable and async-without-await warnings in unrelated API
  controllers. This is compilation evidence, not a database test pass.
- Added English/Arabic tour route-suppression checks: **16 tour tests passed**.
- App and API `git diff --check`: no whitespace errors.

Logs are in local `artifacts/customer-journey-*.log` files. PostgreSQL integration
execution is unavailable: `docker info` fails because the Docker Desktop Linux
engine pipe does not exist. Tests guarded by `RUN_INTEGRATION_TESTS` were not
reported as executed. No physical-device, TestFlight or Android-release run was
performed. No live customer data was changed.

## Scenario coverage and remaining manual verification

Automated results below use fake profile APIs or test repositories unless stated.
They verify client state and navigation, not production database persistence.
Every row still requires a real-device/API pass before release.

| # | Scenario | Automated evidence | Additional manual verification |
| --- | --- | --- | --- |
| 1 | New number, Start Your Plan | OTP/navigation tests plus name-first setup and Plan Selection destination | Real OTP to complete order-entry journey |
| 2 | New number, normal login | Name-first setup and Dashboard destination | Real OTP and Dashboard data |
| 3 | Complete existing customer | Name/questions skipped for both intents | Existing production-compatible profile |
| 4 | Missing name | Both intents; completed questionnaire retained after name PATCH | Confirm database fields unchanged |
| 5 | Missing profile | Stable 404 classification, name creation, dashboard dependencies deferred | PostgreSQL creation/concurrency tests |
| 6 | Partial questionnaire | Every required first-incomplete step and saved answers | Actual draft after reconnect |
| 7 | Step 1 incomplete | Goal chosen despite misleading later hint; initial 0% | Device rendering |
| 8 | Step 2 incomplete | Basic Details after saved Goal; persisted 17% | Device rendering |
| 9 | Completed questionnaire | No questionnaire flash/redirect; backend completion required | Device cold start |
| 10 | Active subscription, new plan | Fresh plan action with ACTIVE/CONFIRMED orders | Actual new checkout beside active order |
| 11 | Pending order, new plan | Fresh plan action with PENDING_APPROVAL order | Actual new checkout beside pending order |
| 12 | Restart during name | Fresh provider container reloads missing-name profile, safe default intent | Process kill while PATCH is in flight |
| 13 | Restart during questionnaire | Fresh container reloads partial backend answers | Process kill during save; second device |
| 14 | Restart after completion | Fresh container reloads complete profile and skips questions | Real secure storage and server round trip |
| 15 | Profile network/API failure | Recoverable error; no false missing-profile/dashboard result | Airplane mode/reconnect |
| 16 | Name save failure | Input retained; retry and duplicate-tap prevention | Timeout/reconnect against API |
| 17 | Questionnaire save failure | Remains on question; incomplete response cannot grant access | Server/network interruption |
| 18 | Rapid navigation/taps | Shared checks, single name save, late OTP/name/profile callbacks rejected | Repeated device gestures |
| 19 | Back during onboarding | Saved answers retained; authoritative previous-step mapping; name cannot bypass | System back/edge gestures |
| 20 | Logout/another number | Old account responses cannot hydrate new account; late OTP cannot restore logout | Two real identities and stored tokens |
| 21 | English/Arabic | Name validation, RTL/compact layouts and tour checks | Keyboard, accessibility and localized devices |
| 22 | TestFlight/Android release | No release-device verification performed | Both release distributions, all above paths |

The automated scenarios passed. Full manual validation of every new and returning
customer scenario remains outstanding; it would be inaccurate to claim otherwise.
