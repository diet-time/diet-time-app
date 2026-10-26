# Diet Time

Initial Flutter foundation for the Diet Time healthy meal subscription app.

## Included

- Native emerald launch screens for Android and iOS
- Animated, reduced-motion-aware Flutter splash and authentication routing
- Responsive English/Arabic login with immediate RTL switching
- Riverpod state management, `go_router`, and secure storage boundary
- Material 3 brand tokens and reusable form/button components
- Placeholder home route and mock unauthenticated service

## Required brand assets

The supplied brand-sheet logo is currently extracted to:

`assets/logo/diet_time_logo.png`

Replace it with the original client-approved SVG export when available. Add
licensed Bw Surco DEMO and Almarai files under `assets/fonts/`, register the font
weights in `pubspec.yaml`, and update the family constants in
`lib/app/theme/app_typography.dart`. Manrope is the temporary English family.

## Google Maps setup

Enable **Maps SDK for Android** and **Maps SDK for iOS** in Google Cloud. For
Android, copy the example secret file and replace its placeholder value:

- `android/local.properties.example` → `android/local.properties`
The Android destination file is ignored by Git. The current iOS key is embedded
in `ios/Runner/AppDelegate.swift`, so restrict it in Google Cloud to the iOS
bundle ID `com.diettime.dietTime`. Restrict the Android key to application ID
`com.diettime.diet_time` plus its signing SHA-1.

On macOS, install the native iOS dependencies and open the workspace:

```sh
cd ios
pod install
open Runner.xcworkspace
```

## TestFlight

The `iOS TestFlight` GitHub Actions workflow builds a signed IPA and uploads it
to App Store Connect on pushes to `main` or from **Actions → iOS TestFlight →
Run workflow**. It expects the app record and the `com.diettime.dietTime` App
Store bundle ID to already exist in Apple Developer and App Store Connect.

Configure these GitHub Actions variables:

- `APPSTORE_ISSUER_ID`
- `APPSTORE_API_KEY_ID`
- `APPSTORE_TEAM_ID`

Configure these GitHub Actions secrets:

- `APPSTORE_API_PRIVATE_KEY` — the contents of the App Store Connect `AuthKey_*.p8`
- `APPSTORE_CERTIFICATES_FILE_BASE64` — a base64-encoded Apple Distribution `.p12`
- `APPSTORE_CERTIFICATES_PASSWORD` — the `.p12` password

The workflow downloads the App Store provisioning profile named
`AppStore com.diettime.dietTime`; create that profile with the same bundle ID
and an Apple Distribution certificate. Never commit signing certificates,
private keys, provisioning profiles, or local API key files.

## Run

```sh
flutter pub get
flutter run
```

Use `flutter gen-l10n` after editing the ARB files.

## Connecting authentication

Implement `AuthenticationService` with the backend client, persist the returned
token through `SecureStorageService`, and override
`authenticationServiceProvider` with the real implementation. Keep token and
session decisions outside presentation widgets.

## Tomorrow’s Menu implementation

Implemented across `diet-time-app`, `diet-time-api`, and `diet-time-admin-spa` on 26 October 2026. The timestamp migration has already been applied to the database, as confirmed by the project owner.

The dashboard now loads tomorrow’s configured dishes through the authenticated API. Draft choices stay in Flutter state, with provisional defaults preselected only when still eligible. Customers choose the exact purchased quantities, review a confirmation sheet, and submit the complete set once. Success appears only after persisted confirmation is returned or verified by an authoritative refresh. Confirmed and automatically finalized dishes are read-only. Each active subscription has its own section.

Calendar layout, active-plan cards, subscription purchasing, pricing, and order creation were preserved. Calendar APIs now return saved meals read-only; the old per-dish PUT returns `409 confirmation_required`, preventing it from bypassing whole-day confirmation.

The API uses the repository’s existing order-to-subscription bridge and `/api/v1/orders` routes. New orders are never created by confirmation. Ownership checks require the authenticated user’s active customer profile. The saved service-day template ID and week number are used; missing week numbers fall back to the saved service sequence. The service checks the published saved template, actual weekday, active slots with a positive maximum, active meal types, available free options, availability dates, allergens, and dietary requirements. It does not query the entire catalog as selectable alternatives.

Qatar midnight opens tomorrow’s window. Exactly 21:00 Qatar (18:00 UTC) closes it. Friday deliveries are excluded; Friday can select Saturday. Dates beyond tomorrow expose no selectable alternatives. Server time controls eligibility. Flutter schedules refreshes using the server’s current time and cutoff, without a device-clock countdown, and refreshes after app resume and Qatar midnight.

Confirmation locks the service-day row with PostgreSQL `FOR UPDATE`, reloads current state, checks the clock after waiting, validates the complete set, and replaces provisional rows inside one transaction. Dish-index swaps are safe because existing rows are first marked cancelled inside the transaction and then reused by `(category, selection_number)`. Cancelled rows retain their occupied positions and are reused rather than blindly reinserted. Legacy rows and history remain present. An injected second-phase database failure is covered by a rollback test.

The hosted worker runs at startup and every 15 seconds. At or after the Qatar cutoff, it validates and finalizes eligible overdue days, including cutoffs missed during downtime. Existing eligible provisional dishes take priority; shortages use the existing eligibility and preference rules to fill defaults. It shares the row lock with confirmation, skips locked or timestamped days, and safely retries. A failing delivery is flagged and logged while other deliveries continue. Incomplete or unsafe defaults remain unfinalized and visible for operations review. Processing may begin up to 15 seconds after cutoff; customer confirmation closes at the exact server cutoff regardless of worker timing.

Kitchen JSON and PDF reports use only the same persisted finalized selection rows. Reports include actual dish names and quantities, order/customer references, requirements, source, and finalization status. Reports are explicitly preliminary before cutoff or while days remain unresolved. Uninitialized legacy orders and legacy locks without validated timestamps are flagged instead of having dishes regenerated from a template. Downloading a report no longer locks days or invents finalization.

Database assessment:

| Concern | Repository evidence and implementation |
| --- | --- |
| Existing selection table | Reuses `customer_meal_selections`; no new selection table. |
| Category values | Existing EF/service code writes lowercase `meal` and `snack`. Integration tests enforce those values. The old SQL dump predates category columns; target values/constraints still require the supplied read-only inspection before rollout. |
| Selection status | Existing dump permits `PENDING`, `PARTIAL`, `COMPLETED`, `DEFAULTED`, `LOCKED`; these values are preserved. |
| Confirmation identity | `COMPLETED` plus `customer_confirmed_at` maps to API `CUSTOMER_CONFIRMED`. |
| Automatic finalization identity | `DEFAULTED` plus `auto_finalized_at` maps to API `AUTO_FINALIZED`. Existing provisional `DEFAULTED` without a timestamp stays provisional. |
| Selection source | Existing per-selection `selection_source` retains `CUSTOMER` or `DEFAULT`; no redundant source column is added. |
| Lock | Reuses `selection_locked`. |
| Confirmation/finalization timestamps | No equivalent explicit columns were found in the checked-in entities or SQL snapshot. The applied migration adds two nullable timestamps with `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`. Its SQL is preserved below for other environments. |
| Unique constraints | Existing dish, position, legacy type, subscription/date, and subscription/sequence indexes are preserved. No index is dropped. |
| Live schema | Migration execution was confirmed by the project owner; the target schema was not independently queried in this session. Tests used a newly initialized isolated PostgreSQL instance, never the application database. |

The SQL dump is older than the current application model: it omits `order_id`, `service_sequence`, `menu_week_number`, saved template/package fields, review/revision fields, category/position fields, and the slot-option reference already used by the pre-existing upcoming-meal feature. The setup SQL below checks prerequisites rather than guessing a migration for an unknown deployed schema.

The database timestamp migration is already applied, per your confirmation. The API, background worker, and build configuration do not load its standalone SQL file, so that file has been removed. For new or additional environments, review and apply the following setup SQL before deploying the API/worker; it is never executed automatically.

```sql
-- REVIEW ONLY. Do not run automatically or from application startup.
-- Existing upcoming-meals release prerequisites must already be installed.
-- No meal selections, orders, subscriptions, indexes, or historical statuses are removed.
BEGIN;
SET LOCAL lock_timeout = '5s';

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public'
      AND table_name = 'subscription_service_days' AND column_name = 'order_id')
    OR NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public'
      AND table_name = 'customer_meal_selections' AND column_name = 'category') THEN
    RAISE EXCEPTION 'Upcoming-meals schema prerequisites are missing. Review the schema assessment before applying this migration.';
  END IF;
END $$;

ALTER TABLE public.subscription_service_days
  ADD COLUMN IF NOT EXISTS customer_confirmed_at timestamptz,
  ADD COLUMN IF NOT EXISTS auto_finalized_at timestamptz;

COMMENT ON COLUMN public.subscription_service_days.customer_confirmed_at IS
  'Customer whole-day confirmation time. Set atomically with selection_locked and COMPLETED.';
COMMENT ON COLUMN public.subscription_service_days.auto_finalized_at IS
  'Validated automatic finalization time. Set atomically with selection_locked and DEFAULTED.';

-- Existing constraint values remain valid: COMPLETED/DEFAULTED plus timestamps
-- map to CUSTOMER_CONFIRMED/AUTO_FINALIZED in the API. Sources remain CUSTOMER/DEFAULT.
-- Old LOCKED records are intentionally not reclassified as validated finalizations.
COMMIT;

-- Read-only assessment to run separately against the target database before approval:
-- SELECT table_name, column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns WHERE table_schema = 'public'
-- AND table_name IN ('subscription_service_days', 'customer_meal_selections')
-- ORDER BY table_name, ordinal_position;
-- SELECT conrelid::regclass, conname, pg_get_constraintdef(oid)
-- FROM pg_constraint WHERE conrelid IN ('public.subscription_service_days'::regclass,
-- 'public.customer_meal_selections'::regclass);
-- SELECT tablename, indexname, indexdef FROM pg_indexes WHERE schemaname = 'public'
-- AND tablename IN ('subscription_service_days', 'customer_meal_selections');
-- SELECT DISTINCT category, selection_source, status FROM public.customer_meal_selections;
```

The optional [read-only schema-assessment script](../diet-time-api/database/scripts/20261026_tomorrow_meal_schema_assessment.sql) remains available for inspecting columns, constraints, indexes, categories, sources, and statuses.

For other target environments, if inspection reveals equivalent timestamp columns or different category casing, map those existing columns/values instead of adding redundant fields. Existing orders without initialized service days need the existing explicit admin initialization endpoint after their schedule/template configuration is verified. Existing locked days without confirmation/finalization timestamps need operations review; they are not silently unlocked or reclassified.

API examples (illustrative configured-menu fixtures; dish names are not hardcoded in the application):

```http
GET /api/v1/orders/{orderId}/tomorrow-menu?language=en
Authorization: Bearer {accessToken}
```

```json
{
  "data": {
    "subscriptionId": "11111111-1111-1111-1111-111111111111",
    "subscriptionServiceDayId": "22222222-2222-2222-2222-222222222222",
    "deliveryDate": "2026-10-27",
    "mealPlanName": "Complete Balance",
    "mealCount": 2,
    "snackCount": 1,
    "selectionStatus": "DEFAULT_PENDING",
    "selectionLocked": false,
    "canConfirm": true,
    "cutoffAt": "2026-10-26T18:00:00+00:00",
    "serverNow": "2026-10-26T12:00:00+00:00",
    "reviewReason": null,
    "selectedMenuItemIds": [],
    "selectedMeals": [],
    "availableMeals": [
      {
        "mealItemId": "33333333-3333-3333-3333-333333333333",
        "slotOptionId": "44444444-4444-4444-4444-444444444444",
        "mealName": "Grilled chicken",
        "description": "Chicken with seasonal vegetables",
        "imageUrl": "https://cdn.example.test/configured-chicken.jpg",
        "calories": 450,
        "category": "meal",
        "mealTypeId": "55555555-5555-5555-5555-555555555555"
      },
      {
        "mealItemId": "66666666-6666-6666-6666-666666666666",
        "slotOptionId": "77777777-7777-7777-7777-777777777777",
        "mealName": "Salmon bowl",
        "description": "Salmon with rice",
        "imageUrl": "https://cdn.example.test/configured-salmon.jpg",
        "calories": 510,
        "category": "meal",
        "mealTypeId": "55555555-5555-5555-5555-555555555555"
      }
    ],
    "availableSnacks": [
      {
        "mealItemId": "88888888-8888-8888-8888-888888888888",
        "slotOptionId": "99999999-9999-9999-9999-999999999999",
        "mealName": "Berry yogurt",
        "description": "Yogurt with berries",
        "imageUrl": "https://cdn.example.test/configured-yogurt.jpg",
        "calories": 160,
        "category": "snack",
        "mealTypeId": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
      }
    ]
  }
}
```

Provisional defaults populate `selectedMenuItemIds` and `selectedMeals` with actual persisted dishes. A no-delivery result has a null service-day ID, `NO_DELIVERY`, `canConfirm: false`, and empty arrays. Owned inactive subscriptions return read-only state; unknown or unowned orders return 404.

```http
POST /api/v1/orders/{orderId}/service-days/{serviceDayId}/confirm-meals?language=en
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "mealMenuItemIds": [
    "33333333-3333-3333-3333-333333333333",
    "66666666-6666-6666-6666-666666666666"
  ],
  "snackMenuItemIds": ["88888888-8888-8888-8888-888888888888"]
}
```

The 200 response uses the same envelope, with `selectionStatus: CUSTOMER_CONFIRMED`, `selectionLocked: true`, `canConfirm: false`, all persisted dishes in `selectedMeals`, their IDs in `selectedMenuItemIds`, and no editable alternatives. At cutoff an unconfirmed day is initially `FINALIZATION_PENDING`, then `AUTO_FINALIZED` after worker persistence. Missing safe defaults produce `NEEDS_REVIEW`.

Errors use existing problem details: 401 authentication failure; 404 unowned/missing order/day; 409 `cutoff_passed`, `already_confirmed`, `subscription_inactive`, or retired PUT `confirmation_required`; 422 `invalid_selection` or `meal_unavailable`. Repeated confirmations return 409 without changing saved selections. Flutter refreshes authoritative state after any ambiguous confirmation failure.

Validation:

| Check | Result |
| --- | --- |
| `flutter analyze --no-pub` | Passed, no issues. |
| Flutter dashboard, calendar, repository, and new tomorrow-menu tests | 34 passed. |
| Full Flutter suite | 210 passed, 7 failed in pre-existing launch/language tests. |
| Baseline check with original dashboard restored temporarily | Same 7 failures reproduced; implementation restored afterward. |
| API unit suite | 121 passed, including Qatar midnight/cutoff and Friday/Saturday boundaries. |
| Isolated PostgreSQL upcoming-meal and rotation suite | 25 passed, none skipped. |
| Admin production build (`npm run build`) | Passed. Existing bundle-size warning remains. |
| Admin kitchen UI/API tests | 10 passed. |
| Git whitespace checks | Passed in all three repositories. |

The PostgreSQL tests create and remove their own randomly named databases on a separate local test cluster. They cover HTTP authentication/ownership, exact entitlements, provisional defaults, full-set confirmation, dish swaps, cancelled-position reuse, invalid counts/categories/duplicates, dietary/allergen filtering, inactive slots, four-week mapping, persisted read-only responses, concurrent confirmations, confirmation/finalizer races at cutoff, repeat finalizers, restart recovery, injected transaction failures, failed-delivery isolation, inactive subscriptions, incomplete defaults, and legacy locks. No tests ran against the application database.

Run the API unit tests with `dotnet test tests/DietTime.UnitTests/DietTime.UnitTests.csproj --no-restore`. For the PostgreSQL suite, set `UPCOMING_MEALS_TEST_CONNECTION` to an **isolated** PostgreSQL instance whose user may create/drop test databases, then run:

```powershell
dotnet test tests/DietTime.Meal.Api.IntegrationTests/DietTime.Meal.Api.IntegrationTests.csproj --no-restore --filter 'FullyQualifiedName~UpcomingMealServiceTests|FullyQualifiedName~SubscriptionMenuRulesTests'
```

The remaining pre-existing Flutter failures are: new guest onboarding after language; carousel start-plan login; final questionnaire submission opening the menu; first-launch language panel; authenticated first-launch language panel; English selection persistence; and Arabic selection/RTL. Their launch/language code was not modified.

The current database migration is complete according to the project owner. Remaining rollout checks: review uninitialized or previously locked legacy service days and validate production menu configuration and media. For other environments, inspect their schema and apply the setup SQL above before deploying the API/worker. Native iOS/Android builds and a production end-to-end session were not run. Existing API compiler warnings outside the changed feature remain. Additional environments must receive the schema changes before the worker is deployed.

Changed files, relative to each repository:

```text
diet-time-app/
  lib/features/dashboard/presentation/customer_dashboard_screen.dart
  lib/features/dashboard/presentation/tomorrow_menu_section.dart
  lib/features/dashboard/data/tomorrow_menu_repository.dart
  lib/features/dashboard/domain/tomorrow_menu.dart
  test/tomorrow_menu_test.dart
  README.md

diet-time-api/
  src/Apis/DietTime.Meal.Api/Controllers/UpcomingMealsController.cs
  src/Apis/DietTime.Meal.Api/Program.cs
  src/Apis/DietTime.Meal.Api/TomorrowMealFinalizationWorker.cs
  src/BuildingBlocks/DietTime.Application/UpcomingMeals.cs
  src/BuildingBlocks/DietTime.Contracts/UpcomingMealContracts.cs
  src/BuildingBlocks/DietTime.Contracts/DeliveryPreparationContracts.cs
  src/BuildingBlocks/DietTime.Domain/UpcomingMealEntities.cs
  src/BuildingBlocks/DietTime.Persistence/UpcomingMealService.cs
  src/BuildingBlocks/DietTime.Persistence/TomorrowMealService.cs
  src/BuildingBlocks/DietTime.Persistence/AdminDeliveryCalendarService.cs
  src/BuildingBlocks/DietTime.Infrastructure/KitchenPreparationPdfReportGenerator.cs
  tests/DietTime.Meal.Api.IntegrationTests/UpcomingMealServiceTests.cs
  tests/DietTime.Meal.Api.IntegrationTests/DeliveryPreparationApiTests.cs
  tests/DietTime.UnitTests/TomorrowMealWindowTests.cs
  database/scripts/20261026_tomorrow_meal_schema_assessment.sql

diet-time-admin-spa/
  src/features/delivery-calendar/types.ts
  src/features/delivery-calendar/components/DateDetailsDrawer.tsx
  src/features/delivery-calendar/components/DateDetailsDrawer.test.tsx
```
