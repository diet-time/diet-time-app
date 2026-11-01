# Three customer flow corrections

## 1. Questionnaire save conflict

Confirmed root cause in the API: `SynchronizePreferences` added a preference with
a supplied Guid to the collection of an existing tracked profile. EF inferred
`Modified`, issuing an UPDATE for a row that did not exist. A database-free test
against the actual Npgsql EF model reproduced `Expected: Added / Actual: Modified`.
Explicitly adding the new preference to the DbSet fixes its state to `Added`.
Existing preference edits/removals, per-customer locks, EF concurrency tokens,
questionnaire validation and completion criteria remain in place. No migration.

The API upsert contract does not consume Flutter's `rowVersion`; a stale client
version was not the cause of that false insert conflict. Flutter already adopts
the successful response version. Tests now verify consecutive outgoing versions.

Flutter previously surfaced 409 without retrieving the latest profile. It now
serializes questionnaire loads/saves, retains the saved baseline, and handles a
concurrency conflict with a three-way comparison of saved, edited and latest
answers. Only locally changed questionnaire fields are reapplied; unrelated
server fields and current version are retained. Disjoint changes receive one
automatic retry. Different concurrent edits to the same answer retain local input
and show the error for review and explicit retry. Repeated conflicts stop after
one retry; database-constraint conflicts are not retried as concurrency errors.
Profile failures retain their API error codes. The update also sends the profile's
language so a reconciled Arabic setting is not overwritten by the API's English
default. Authentication/session recovery behavior is unchanged.

## 2. Back to Dashboard

The existing meal-plan screen has a compact, localized Back to Dashboard header
action when the authenticated customer can access Dashboard. It uses the existing
home route. It does not select a package, submit an order, or modify plan cards,
prices or Continue. The ordinary back button remains for other pushed entries.

## 3. Questionnaire introduction and Not Now

Incomplete account setup opens the existing introduction (page 0) after the
unchanged authentication/name/profile flow. Start uses the existing authoritative
first-incomplete-step calculation. No question opens before that action.

Not Now uses the existing session-scoped deferral provider and goes directly to
Dashboard. It does not save answers, create a draft/order, or mark completion.
Dashboard and the existing Profile questionnaire route permit this explicit
deferral; checkout readiness still requires actual questionnaire completion.
Profile can reopen the existing introduction and resume saved answers. Completed
customers retain their existing destination and skip introduction/questions.
Logout continues to clear deferral using the existing authentication behavior.
App-tour logic, dashboard layout, payment, approval and calendar were not changed.

## Exact changed files

Flutter production paths relative to `diet-time-app`:

- `lib/app/router/app_router.dart`
- `lib/features/dashboard/presentation/customer_dashboard_controller.dart`
- `lib/features/onboarding/presentation/onboarding_screen.dart`
- `lib/features/personalization/data/customer_profile_repository.dart`
- `lib/features/personalization/domain/questionnaire_profile_merge.dart` (new)
- `lib/features/personalization/presentation/customer_onboarding_coordinator.dart`
- `lib/features/personalization/presentation/profile_persistence_controller.dart`
- `lib/features/personalization/presentation/questionnaire_deferral_controller.dart`
- `lib/features/plans/presentation/meal_plan_screen.dart`

Flutter tests:

- `test/questionnaire_save_conflict_test.dart` (new)
- `test/questionnaire_landing_test.dart` (new)
- `test/meal_plan_screen_test.dart`
- `test/widget_test.dart`

ASP.NET Core paths relative to the sibling `diet-time-api` repository:

- `src/BuildingBlocks/DietTime.Persistence/CustomerProfileService.cs`
- `tests/DietTime.UnitTests/QuestionnairePreferenceTrackingTests.cs` (new)

## Executed validation

- Preference tracking reproduction: 1 failing test before the API fix, 1 passing
  test after it. No PostgreSQL connection was used for this EF state test.
- Targeted Flutter suite: 35 passed (conflict handling, intro/deferral/Profile,
  dashboard controller, meal plans and profile persistence).
- Full Flutter suite: **461 passed**, including the existing ordering, OTP/name,
  dashboard, calendar and app-tour regressions.
- Full ASP.NET Core unit suite: **246 passed**.
- Dart static analysis with `--fatal-infos`: **no issues**.
- App/API `git diff --check`: no whitespace errors.

Logs: `artifacts/three-fixes-{tests,full-tests,api-tests,analysis}.log` and the
preference-before/after logs. Live PostgreSQL integration was not executed:
Docker Desktop's Linux-engine pipe is unavailable. Real-device/release validation
also remains outstanding. Deploy the API preference fix with the Flutter update;
the client conflict recovery does not replace the server insertion correction.
