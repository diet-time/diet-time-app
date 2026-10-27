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

## Android APK download and installation

The **Build Android APK** GitHub Actions workflow builds one installable Android APK on demand. It is separate from the iOS workflows; running it does not start an iOS build or upload anything to TestFlight.

1. Commit and push `.github/workflows/build-apk.yml` and this README to GitHub. The workflow must be present on the repository’s default branch to appear under **Actions**.
2. Open **Actions → Build Android APK → Run workflow**. Select the branch to build and keep the default staging API address, or enter your API’s HTTPS address.
3. Wait for the run to succeed, then open it. Download **diet-time-android-apk-&lt;run number&gt;** from **Artifacts**, or use the download link in the run summary.
4. Extract the downloaded ZIP. Copy `diet-time.apk` to your Android phone if you downloaded it on your computer.
5. Open `diet-time.apk` on the phone. Allow **Install unknown apps** for your browser or Files app if prompted, then tap **Install**.

The artifact is retained for 14 days; run the workflow again whenever you need a new APK. Downloading an artifact requires signing in to GitHub with access to this repository. See [GitHub’s artifact download instructions](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/download-workflow-artifacts).

No Apple certificates or signing secrets are needed. The workflow uses Flutter `3.41.9` (Dart `3.11.5`), Java 17, and the project’s existing Android debug signing configuration in release mode. This APK is intended for installation on your own phone for testing. Its signing key is cached between runs, and the build number increases with each new run. Use the same branch for updates. If the cache is cleared or you previously installed an APK signed with a different key, Android may require uninstalling the old app first; uninstalling clears its local data. Google Play distribution would require a permanent release signing setup.

For the address map, optionally add the repository **Actions secret** `ANDROID_GOOGLE_MAPS_API_KEY` under **Settings → Secrets and variables → Actions**. Enable Maps SDK for Android and restrict the key to package `com.diettime.diet_time` and the SHA-1 fingerprint printed in the workflow summary. Without this key, the APK still builds and installs, but the address map will not load. The key is written only to the runner’s ignored `android/local.properties`; it is not added to the repository or iOS configuration.

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

## Empty Tomorrow’s Menu investigation

The code investigation found these defects; the affected live customer order has **not yet been verified**. No usable application database connection or affected order identifier was available in this session. The affected order/environment and authorized access are still required. The checks below are ready to establish the live cause rather than assume that an order is missing.

- `GetTomorrowAsync` previously returned `NO_DELIVERY` whenever no matching `subscription_service_days.order_id` row existed, even when the purchased order scheduled a delivery tomorrow. It now checks the owned order, purchased quantities, date range, and delivery weekdays first, then distinguishes `SERVICE_DAYS_MISSING`, `SERVICE_DAY_INCOMPLETE`, `NOT_STARTED`, `PENDING_ACTIVATION`, `NO_DELIVERY`, `INACTIVE_ORDER`, and `MENU_NOT_CONFIGURED`.
- Flutter previously treated every null service-day ID as “No delivery.” It now renders the API status and reason, retains plan/package information, shows the first delivery date for future plans, and distinguishes authentication, missing-order lookup, network, and API failures. Repairable empty states have a refresh action.
- The customer order lookup previously read only its first page. It now reads all pages, so an older active plan is not hidden by newer orders. Incomplete or changing pagination is reported as an error. Pending activation orders remain visible as plans.
- A PostgreSQL regression reproduced a confirmation failure when no provisional selection rows existed: new rows with assigned UUIDs were treated as updates, resulting in `DbUpdateConcurrencyException`. New selections are now explicitly added to EF before saving. Configured dishes load without any saved selections, and customers can confirm a new complete set.

Order placement already calls `InitializeAsync` after saving the order and before committing the same transaction. Orders are the subscription source; there is no new subscription table. The operational backfill now checks both order/subscription identifiers and refuses ambiguous links or conflicting service sequences. It adds only missing current/future service days, preserves historical dates and selections, and remains idempotent. No schema changes or application-data backfill were executed for this investigation. The exact 9 PM Qatar cutoff, tomorrow-only window, Friday exclusion, row locks, and permanent confirmation remain unchanged.

Trace the real customer through these existing authenticated routes:

```http
GET /api/v1/customer/profile
GET /api/v1/customer-profiles/{profileId}/orders?pageNumber=1&pageSize=100
GET /api/v1/orders/{orderId}/tomorrow-menu?language=en
```

Use the `id` from the owned orders response as `{orderId}`. The existing response field `subscriptionId` still carries this order identifier. The menu now also returns `orderStatus`, `orderStartDate`, `firstDeliveryDate`, `menuTemplateId`, `menuTemplateVersion`, `menuWeekNumber`, and `emptyReason` where applicable.

Server logs record authenticated user/customer IDs, order/subscription IDs, order status, Qatar today/tomorrow, matched service-day ID, saved template/version, week/weekday, dish and selection counts, status, and empty reason. Flutter debug logs show the actual route, HTTP status, and parsed menu state; access tokens are not logged. Empty results are not treated as evidence of a missing order.

Operational tools are provided separately in the API repository:

- `database/scripts/tomorrow_menu_diagnostics.sql`: read-only PostgreSQL queries for the real order, authenticated user link, purchased quantities, delivery weekdays, service days, persisted selections, configured menu options, and foreign keys. The SQL uses the actual mapped template weekday column, `day_of_week`.
- `database/scripts/backfill_upcoming_meals.ps1`: defaults to a read-only admin preview. An explicit `-Apply` invokes the existing transaction-protected initialization endpoint for one verified order. Raw DML is not duplicated in SQL because that would bypass the existing service’s eligibility, sequence, and locking rules.
- `database/scripts/verify_tomorrow_menu.ps1`: resolves the authenticated customer profile, locates the actual existing order across pages, and fetches its real menu. It changes no selections. Supply the customer access token through `DIETTIME_CUSTOMER_ACCESS_TOKEN` in the environment, never in a committed file or chat.

Run diagnostics against the intended database, supplying the actual order UUID:

```sh
psql -v order_id='<order-uuid>' -f database/scripts/tomorrow_menu_diagnostics.sql
```

Preview a backfill using an authorized Admin/Operations session token supplied through `DIETTIME_ADMIN_ACCESS_TOKEN`:

```powershell
.\database\scripts\backfill_upcoming_meals.ps1 -ApiBaseUrl https://your-api.example -OrderId <order-uuid>
```

Review the order, status, dates, saved template version, existing IDs, conflicts, and missing dates. Only after verifying the cause, repeat with `-Apply`. Historical days and existing selections are preserved. Ambiguous existing subscription links must be reviewed separately; they are not automatically reassigned.

Verify the customer’s actual menu with the updated API deployed, during the appropriate selection window:

```powershell
.\database\scripts\verify_tomorrow_menu.ps1 -ApiBaseUrl https://your-api.example -OrderId <order-uuid>
```

An existing future-starting or non-delivery order should return its distinct state. Do not alter the server clock or bypass cutoff to make a live verification pass. A successful test fixture is not evidence that the affected live order has been repaired.

Files affected by this investigation:

```text
diet-time-app/
  README.md
  lib/features/checkout/data/orders_repository.dart
  lib/features/checkout/domain/order_models.dart
  lib/features/dashboard/data/tomorrow_menu_repository.dart
  lib/features/dashboard/domain/tomorrow_menu.dart
  lib/features/dashboard/presentation/tomorrow_menu_section.dart
  test/tomorrow_menu_test.dart
  test/dashboard_order_pagination_test.dart
diet-time-api/
  src/BuildingBlocks/DietTime.Contracts/UpcomingMealContracts.cs
  src/BuildingBlocks/DietTime.Persistence/TomorrowMealService.cs
  src/BuildingBlocks/DietTime.Persistence/UpcomingMealService.cs
  src/Apis/DietTime.Meal.Api/Controllers/AdminUpcomingMealsController.cs
  tests/DietTime.Meal.Api.IntegrationTests/UpcomingMealServiceTests.cs
  database/scripts/tomorrow_menu_diagnostics.sql
  database/scripts/backfill_upcoming_meals.ps1
  database/scripts/verify_tomorrow_menu.ps1
```

Current regression results: 43 Flutter dashboard/menu/pagination/calendar tests passed; 31 PostgreSQL menu/rotation tests passed, including missing schedules, no saved selections, explicit idempotent backfill, preserved locks, and cutoff/concurrency cases. One additional PostgreSQL test passed for the read-only diagnostic SQL, for 32 passing database tests in total. Flutter analysis is clean, the API builds, both operational PowerShell scripts parse successfully, and whitespace checks pass. The operational HTTP scripts were not run against a live account. Live-order verification remains outstanding until the affected order/environment and authorized access are available.

## Optional package discounted prices

The API returns a rounded whole discount percentage, and Flutter badges plus SPA pricing listings and live previews use whole percentages (for example, 16.53% displays as 17% OFF). The Flutter bottom subscription summary shows the package total and savings without a per-day price; the SPA already displays package totals without that line. Monetary amounts and daily-price API fields retain their existing precision and contracts.

Administrators can add, change, or clear a discounted selling price in the existing **Plan Pricing → Add/Edit Price** dialog. The regular price remains separate. The dialog previews the percentage and customer savings, and the listing shows both prices when a promotion exists. Clearing the optional field submits `discountedPrice: null`.

The package-specific price belongs to `meal_plan_prices`: each row maps a saved meal plan, duration (`package_code`), and `package_option_id`, with its regular amount in `amount NUMERIC(12,2)`. `meal_plan_price_packages` contains duration definitions, and `meal_package_options` contains meal/snack entitlements. Neither lookup table stores this selling amount. No equivalent discounted-price field was found in the checked-in schema or EF mappings. This assessment uses repository evidence; the live database schema was not independently queried.

Review and apply `diet-time-api/database/scripts/20261026_package_discounted_price.sql` **before deploying the API**. It adds nullable `meal_plan_prices.discounted_price NUMERIC(12,2)`, defaulting to NULL, and a CHECK constraint requiring a populated value to be non-negative and strictly lower than `amount`. Both amounts are in the same row. The script is repeatable, sets lock/statement timeouts, and validates the constraint. It does not update existing regular prices, orders, subscriptions, or payments. There is no startup migration hook. The migration was tested only against newly created isolated test databases and **has not been run against the application database**.

For target-schema review, inspect existing columns before applying it:

```sql
SELECT table_name, column_name, data_type, numeric_precision, numeric_scale
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('meal_plan_prices', 'meal_plan_price_packages', 'meal_package_options')
ORDER BY table_name, ordinal_position;
```

The shared server-side `PackagePriceRules` computes effective price, savings, and percentage with `decimal`; percentages round to a whole number using `MidpointRounding.AwayFromZero`. APIs reject negative discounts, discounts equal to or above the regular amount, amounts outside NUMERIC(12,2), and more than two decimal places. A discounted price of zero is supported as a 100% promotion. No promotion is represented by NULL.

Existing admin endpoints retain their request fields (`price` for the package configuration API; `amount` for the older pricing API). Responses add `regularPrice`, `discountedPrice`, `effectivePrice`, `discountAmount`, `discountPercentage`, and `hasDiscount`. Older update clients that omit `discountedPrice` preserve the stored promotion; explicit NULL removes it. Create requests that omit it create an ordinary price. Status-only updates preserve pricing. The legacy pricing API also reads, validates, and writes the new field.

Example create/update body for the current package-price endpoint:

```http
POST /api/admin/meal-plan-prices
Content-Type: application/json
Authorization: Bearer {adminAccessToken}

{
  "mealPlanId": "11111111-1111-1111-1111-111111111111",
  "durationId": "WEEK",
  "packageOptionId": "22222222-2222-2222-2222-222222222222",
  "price": 999.00,
  "discountedPrice": 799.00,
  "currencyCode": "QAR",
  "isActive": true
}
```

Creation returns 201 with `{ "id": "..." }`. Updates use `PUT /api/admin/meal-plan-prices/{priceId}` with the same fields and return 204. The existing `GET /api/admin/meal-plan-prices` listing includes these price fields on each row:

```json
{
  "price": 999.00,
  "regularPrice": 999.00,
  "discountedPrice": 799.00,
  "effectivePrice": 799.00,
  "discountAmount": 200.00,
  "discountPercentage": 20,
  "hasDiscount": true,
  "currencyCode": "QAR"
}
```

Without a promotion, the discounted price is NULL, effective price equals regular price, both computed discount values are zero, and `hasDiscount` is false. Authenticated purchase options, selection validation, public plan details, and starting-price cards use the effective amount. Older customer consumers receive the effective amount in their existing `amount` field; regular-price information is available separately.

Flutter shows the discounted total, original price with strikethrough, percentage badge, and amount saved in the existing duration/package selection, start-date summary, and order summary. Promotion labels are absent for ordinary prices. The promotion widget supports English and Arabic and was checked with large text on a compact phone. Flutter rounds quote fields to cents when serializing them; it does not supply an amount the server will charge.

New Flutter order requests add these quote-comparison fields to the existing order payload:

```json
{
  "expectedTotalAmount": 799.00,
  "expectedRegularPrice": 999.00,
  "expectedDiscountAmount": 200.00,
  "expectedCurrencyCode": "QAR"
}
```

The order service reads the current price from PostgreSQL, acquires a shared row lock for the transaction, independently computes the charge, and compares supplied expectations. Changed prices produce HTTP 409 with `code: price_changed` before creating an order. Flutter refreshes the summary and requires a second customer submission; it does not automatically retry the purchase. The expectation fields are optional for older API consumers, but the updated Flutter app always supplies them. They are comparison guards, never trusted price overrides.

The existing order snapshot stores regular price in `subtotal`, promotion savings in `discount_amount`, effective selling price in `total_amount`, and the agreed currency in `currency_code`. Existing delivery-charge and coupon behavior is preserved. Order history, order details, and dashboard totals continue to use the stored snapshot. Idempotent retries return the original order snapshot even after master prices change. Updating or removing a promotion never reprices existing orders, active subscriptions, or previously confirmed payments.

Validation results:

| Check | Result |
| --- | --- |
| API unit suite | 133 passed, including exact decimal calculations and omitted-versus-null update semantics. |
| New isolated PostgreSQL discount tests | 5 passed: administration, database constraints, purchase options, HTTP checkout/snapshot/history, and repeatable migration with unchanged existing amounts. |
| Broader meal-selection/rotation integration run | 36 passed, 1 existing diagnostic test failed because `database/scripts/tomorrow_menu_diagnostics.sql` is absent from the repository. Its test body was not changed by this feature. |
| Relevant Flutter pricing/checkout regressions | 56 passed across targeted runs, including stale-price review, English/Arabic promotions, no-discount behavior, free promotions, and compact layouts. |
| Flutter analysis | No issues. |
| Admin pricing form/API/preview tests | 22 passed. |
| Admin production build | Passed; existing bundle-size advisory remains. |

No native iOS files, Android build settings, or build workflows were changed for this pricing feature. The remaining deployment step is review and application of the standalone SQL, followed by deployment of the updated API, admin app, and customer app. Production checkout was not exercised.

Modified files for this feature, relative to each repository:

```text
diet-time-app/
  README.md
  lib/features/plans/domain/meal_plan_package.dart
  lib/features/plans/presentation/package_discount_details.dart
  lib/features/plans/presentation/subscription_selection_widgets.dart
  lib/features/plans/presentation/meal_plan_details_screen.dart
  lib/features/plans/presentation/meal_plan_start_date_screen.dart
  lib/features/checkout/domain/order_models.dart
  lib/features/checkout/presentation/checkout_controller.dart
  lib/features/checkout/presentation/plan_summary_screen.dart
  test/package_discount_test.dart
  test/place_order_test.dart
  test/meal_plan_details_screen_test.dart
diet-time-api/
  database/scripts/20261026_package_discounted_price.sql
  src/BuildingBlocks/DietTime.Domain/Entities.cs
  src/BuildingBlocks/DietTime.Domain/PackagePriceRules.cs
  src/BuildingBlocks/DietTime.Contracts/ApiContracts.cs
  src/BuildingBlocks/DietTime.Contracts/MealConfigurationContracts.cs
  src/BuildingBlocks/DietTime.Application/Abstractions.cs
  src/BuildingBlocks/DietTime.Persistence/DietTimeDbContext.cs
  src/BuildingBlocks/DietTime.Persistence/MealPlanPricingService.cs
  src/BuildingBlocks/DietTime.Persistence/AdminMealService.cs
  src/BuildingBlocks/DietTime.Persistence/CustomerMealPlanPurchaseService.cs
  src/BuildingBlocks/DietTime.Persistence/MealQueryService.cs
  src/BuildingBlocks/DietTime.Persistence/OrderService.cs
  src/Apis/DietTime.Meal.Api/Controllers/OrdersController.cs
  tests/DietTime.UnitTests/PackagePriceTests.cs
  tests/DietTime.Meal.Api.IntegrationTests/PackageDiscountIntegrationTests.cs
  tests/DietTime.Meal.Api.IntegrationTests/UpcomingMealServiceTests.cs
diet-time-admin-spa/
  src/api/subscriptionConfigurationApi.ts
  src/api/planPricingApi.ts
  src/features/meal-plans/pricing/SubscriptionPlanPricingPage.tsx
  src/features/meal-plans/pricing/SubscriptionPlanPricingPage.test.tsx
  src/features/meal-plans/pricing/packageDiscount.ts
  src/features/meal-plans/pricing/packageDiscount.test.ts
```

## Meal replacement, questionnaire persistence, Qatar dates and delivery slots

Implemented together across Flutter and the sibling `diet-time-api` repository. No live database changes were executed. Android/iOS native settings and build workflows were not changed.

### Root causes and resulting behavior

| Issue | Confirmed cause in the code | Implemented fix |
| --- | --- | --- |
| Meal replacement | `TomorrowMealDraft.toggle` rejected an unselected dish when its category was full; the screen only asked the customer to remove another dish. | Multiple positions open **Replace a meal** / **Replace a snack**, listing selected dishes. A single position replaces directly. Draft counts and the other category stay unchanged, duplicate dishes are rejected, and no confirmation request runs until Confirm My Meals. Locked/finalized days and the existing 9 PM Qatar cutoff remain protected. |
| Questionnaire | Start-plan entry points and the questionnaire required login, while `PUT /api/v1/customer/profile` is authenticated. There was no durable guest save. Every repository error became a generic connection message. The API ignored the submitted confirmation flags even though the profile table already stores them. | Guests enter the questionnaire directly and checkpoint answers in secure local storage. Authenticated drafts are scoped to the stored user identity. Existing OTP/profile loading claims and synchronizes a guest draft through the existing profile PUT; the API resolves ownership from JWT claims. Failed saves keep answers, show status-specific messages and Retry, and block repeated submissions. Controls pause during saving. Existing rows are updated rather than inserted again on retry. Confirmation flags are accepted, saved and returned. No Allergies clears individual selections and restores correctly after reload; the API receives an empty allergen list plus confirmation. |
| Delivery start date | Flutter used the device's local date with a default lead of zero; order placement used UTC dates and permitted configured zero lead. | Purchase packages return server time, earliest start and lead days. Flutter advances the server clock from receipt, uses the Qatar calendar date, enforces at least one day, disables today/past/Friday and validates programmatic checkout changes and submission. The API uses the existing `Asia/Qatar` rules and the same minimum lead. Expired choices require reselection; historical orders and idempotent replays are preserved. Service-day counts and Friday-skipping schedules remain intact. |
| Delivery slots | Slot times come from `delivery_time_slots`, rather than Flutter constants. Addresses had no slot field; the checkout selection only lived in memory. | A nullable address slot FK stores the preference. Creating an address requires an active slot; legacy updates omitting the field retain its saved value. Flutter restores saved slots regardless of address/slot loading order, validates active choices, and saves an explicit change when editing or choosing Use This Address. API times render as `HH:mm`. Orders continue to copy slot names and times into their existing snapshots. |

The unauthenticated profile PUT returning 401 was reproduced in an isolated integration test. No failing production request trace or live database connection was supplied, so no claim is made about the exact status of the originally reported live failure. Failed profile requests now log endpoint/method, HTTP status, validation field names/error codes and correlation/trace ID where available; questionnaire answers and rejected values are excluded.

### Reviewed SQL and deployment order

Review `../diet-time-api/database/scripts/20261026_address_delivery_slots.sql`, then apply it to the intended database **before deploying the updated API**. It is the permanent migration file; `artifacts/four-fixes/api/database-slot.sql` was only a working copy.

The transaction adds only `customer_addresses.delivery_time_slot_id uuid NULL` and its foreign key. Existing addresses remain NULL. It changes the existing Morning slot to **07:0011:00** and Evening to **16:0018:00**, retaining IDs and active states. It updates configuration rows only when times differ and is repeatable. Lock/statement timeouts are set. The script aborts for review if it cannot identify exactly one Morning and one Evening by their existing code or name. It never rewrites orders or fills historical address preferences by guessing.

Deploy the API and rebuild the Flutter app after applying the reviewed migration. Existing profile confirmation columns are reused; no questionnaire table or additional confirmation column is introduced. Production slot codes/names and schema compatibility still require checking against the intended database.

Delivery operations continue to use the existing order snapshots: `OrderService` copies `DeliveryTimeSlotName`, `DeliveryStartTime` and `DeliveryEndTime`; order details expose `delivery.timeSlot`. `AdminDeliveryCalendarService` and `OperationsDashboardService` read/order by stored order delivery fields. Kitchen reporting retains its existing order/service-day source. Updating slot configuration affects new purchases without changing promised times on existing orders.

### Contract examples

Authenticated questionnaire saves still use `PUT /api/v1/customer/profile`, with the full accumulated questionnaire (replace-all collection semantics). For No Allergies, send `allergens: []`; never send a `NONE` ID. Confirmation booleans now round-trip in the GET/PUT response `data` object. They are nullable on incoming requests, so omission by an older client preserves the saved flag.

```json
{
  "genderCode": "FEMALE",
  "dateOfBirth": "1995-01-01",
  "heightCm": 165,
  "weightKg": 65,
  "goalCode": "LOSE_WEIGHT",
  "dailyRoutineCode": "OFFICE_WORK",
  "activityLevelCode": "MOSTLY_SITTING",
  "preferredLanguage": "en",
  "onboardingStatus": "COMPLETED",
  "preferencesConfirmed": true,
  "allergensConfirmed": true,
  "preferences": [],
  "allergens": []
}
```

`GET /api/v1/customer/meal-plans/{code-or-id}/purchase-options` adds these fields to each `data.mealConfigurations[].packages[]` object. Lead days are at least one, including when API configuration contains zero.

```json
{
  "serverNow": "2026-10-25T22:00:00+00:00",
  "earliestStartDate": "2026-10-27",
  "startDateLeadTimeDays": 1
}
```

Address POST/PUT requests and responses now include optional `deliveryTimeSlotId` alongside the existing address fields. The value is the UUID returned by `GET /api/v1/delivery-time-slots`, not a hardcoded Morning/Evening identifier. A missing/inactive slot on create returns 400 with a clear delivery-time message; omitting/nulling it on a legacy PUT preserves the existing stored choice. The new Flutter save flow requires an active choice. Existing slot responses retain `startTime` / `endTime`, for example `"07:00:00"` / `"11:00:00"`.

### Modified files

Flutter application files:

```text
lib/features/dashboard/domain/tomorrow_menu.dart
lib/features/dashboard/presentation/tomorrow_menu_section.dart
lib/features/personalization/data/customer_profile_repository.dart
lib/features/personalization/data/customer_profile_service.dart
lib/features/personalization/presentation/profile_persistence_controller.dart
lib/features/onboarding/presentation/onboarding_screen.dart
lib/features/onboarding/presentation/onboarding_carousel_screen.dart
lib/features/menu/presentation/browse_menu_screen.dart
lib/features/authentication/presentation/otp_verification_page.dart
lib/features/plans/domain/meal_plan_package.dart
lib/features/plans/domain/meal_plan_purchase_selection.dart
lib/features/plans/presentation/meal_plan_start_date_screen.dart
lib/features/checkout/domain/checkout_models.dart
lib/features/checkout/presentation/checkout_controller.dart
lib/features/checkout/presentation/customer_address_screen.dart
```

ASP.NET Core files, relative to `diet-time-api`:

```text
src/BuildingBlocks/DietTime.Contracts/ApiContracts.cs
src/BuildingBlocks/DietTime.Domain/Entities.cs
src/BuildingBlocks/DietTime.Application/Abstractions.cs
src/BuildingBlocks/DietTime.Persistence/CustomerProfileService.cs
src/BuildingBlocks/DietTime.Persistence/CustomerMealPlanPurchaseService.cs
src/BuildingBlocks/DietTime.Persistence/OrderService.cs
src/BuildingBlocks/DietTime.Persistence/CustomerAddressConfigurations.cs
src/BuildingBlocks/DietTime.Persistence/CustomerAddressService.cs
src/Apis/DietTime.Meal.Api/Controllers/CustomerAddressesController.cs
```

Regression coverage is in `test/four_issue_regression_test.dart`, `tomorrow_menu_test.dart`, `meal_plan_start_date_screen_test.dart`, `checkout_repository_test.dart`, `customer_profile_persistence_test.dart`, `place_order_test.dart`, `plan_summary_checkout_test.dart`, `widget_test.dart`, and API `tests/DietTime.Meal.Api.IntegrationTests/FourFixesIntegrationTests.cs`. Existing checkout fixtures now use explicit server time. App navigation tests mock secure storage so installation setup completes before the splash assertions.

### Validation and remaining dependencies

- The new API integration tests passed **4/4** against a temporary isolated PostgreSQL instance. They cover actual authenticated HTTP calls, guest 401, invalid allergen rejection, repeated allergen saves without duplicates, clearing allergies with confirmation retained, address-slot save/reload and legacy edit retention, missing-slot 400, Qatar midnight with zero configured lead, Friday rejection, tomorrow acceptance, and applying the slot migration twice while preserving old orders and addresses.
- API unit tests passed **133/133**. The broader meal/pricing database regression run passed **30 tests** and failed one older test because `database/scripts/20261026_package_discounted_price.sql` is absent. That removed-file dependency was not restored or hidden. The separately known missing `tomorrow_menu_diagnostics.sql` test was explicitly excluded from this broader run.
- Flutter analysis (`flutter analyze --no-pub lib test`) passed with no issues; the complete Flutter suite passed **246/246**. This includes meal/snack replacement, locked selections, guest save/sync/retry, No Allergies exclusivity, calendar eligibility/duration, saved-slot loading in both request orders, checkout and existing navigation tests.
- No live migration, API deployment, app release or physical-device installation was performed. The SQL review/application and deployment remain operational steps.

## Package purchase and daily meal selection — 27 October 2026

Purchase and daily confirmation now use separate validation. Local PostgreSQL-backed tests purchase packages with 1, 2, 3, 4 and 5 regular meals plus one snack, load all configured menu choices, and confirm the exact quantities. The five-meal case confirms five distinct regular dishes and one snack starting with no saved selections.

### Causes and changes

The Flutter purchase-options mapper used `regularTypes.take(meals)` with quantity one per type. A template with three regular meal types therefore produced only three regular quantities even when its selected package entitled the customer to five. `OrderService.PlaceAsync` compared that client list to `meal_plan_prices.meals_per_day` and returned the reported error. It confused a legacy type distribution with the purchased category entitlement.

Checkout now sends an empty legacy `meals` collection. The API also accepts an omitted/null collection. It validates the customer, published plan/version, active package and matching duration through `PurchasablePlanPrices`, effective price, expected amounts/currency, address, slot, weekdays, and delivery start. The server snapshots the price's quantities in the existing `order_meals` rows using regular/snack representative types. Quantity five on one regular type represents five selectable dishes, not five required types. Supplied legacy type quantities cannot override the purchased package. No individual dish IDs are required.

Service-day generation continues using that order snapshot. Missing eligible defaults do not fail the order: empty days are `PENDING`, partly assigned days are `PARTIAL`, with a persisted review reason and a warning log. Neither receives confirmation/finalization timestamps or a selection lock. Complete provisional defaults retain existing `DEFAULTED` storage semantics without a finalization timestamp.

The existing Tomorrow's Menu query already retrieves alternatives from template days, slots, options and meal items, separately from customer selections, and deduplicates each category by dish. It does not truncate options to the package quantity. Flutter hid those alternatives when `canConfirm` became false, showing only saved defaults when a shortage occurred. It now renders returned alternatives for an unlocked scheduled day even when confirmation is disabled. A second mapping defect hard-coded a four-week cycle when a saved week was absent; both API mapping and eligibility now use the saved template's actual cycle.

Flutter retains its existing design, dynamic progress, server cutoff, and confirmation flow. Full regular-meal selections now open the replacement sheet for every package size, including one meal; a single snack still replaces directly. Confirmed selections remain read-only.

Admin validation checks every active day's distinct free, available regular dishes and snacks against the maximum quantities among active package options. It accounts for overlap between categories so a dish cannot satisfy both entitlements. Create/update publication rejects insufficient capacity with HTTP 422. The existing validation endpoint returns capacity warnings for all weeks; the React editor displays them and shows the server's publication error message. Saving a draft remains available. Runtime eligibility additionally enforces delivery-date availability and each customer's restrictions.

### Database and safety properties

No migration or new table is needed for this change. Existing lowercase categories `meal`/`snack` and `selection_number` support positions `meal/1` through `meal/5` and `snack/1`. The integration fixture exercises the existing dish and position indexes plus the legacy-type index filtered to null categories. No constraints are removed. Repository schema/mappings contain no three-position limit for category selections. The old SQL dump contains `meal_package_option_types`, but the current EF purchase path does not map or use it as entitlement data; package master counts and price matching are authoritative, followed by saved order/service-day quantities.

The existing confirmation endpoint retains ownership, active service day, tomorrow-only Qatar window, exact counts, distinct dishes, category/menu eligibility, allergen/dietary checks, transactional replacement, and permanent locking. Existing finalization and kitchen-report code is retained and covered by regression tests.

Production data, deployed constraints/triggers, and the affected customer's actual menu configuration were not inspected or changed. Local verification uses synthetic fixtures in isolated PostgreSQL 18 databases. If production has only three distinct eligible dishes configured, operations must configure real additional dishes before a five-meal delivery can be confirmed. The new warnings/publication checks expose that shortage; they do not manufacture options or reduce entitlement. Deploy the API before the updated app because the older API rejects empty purchase `meals`.

### Verification

| Package | Purchase without daily choices | Service days | Available regular/snack dishes | Confirmation |
| --- | --- | --- | --- | --- |
| 1 meal + 1 snack | Passed, null legacy collection | 12 | 5 / 2 | 1 + 1, locked |
| 2 meals + 1 snack | Passed, empty legacy collection | 12 | 5 / 2 | 2 + 1, locked |
| 3 meals + 1 snack | Passed, empty legacy collection | 12 | 5 / 2 | 3 + 1, locked |
| 4 meals + 1 snack | Passed, empty legacy collection | 12 | 5 / 2 | 4 + 1, locked |
| 5 meals + 1 snack | Passed, empty legacy collection | 12 | 5 / 2 | 5 + 1 from no saved choices, locked |

The package regression also checks HTTP menu responses, too-few selections, repeat-confirmation rejection, unique dishes and category positions. Additional tests cover a stale three-meal client purchasing five meals with no configured defaults, admin shortage warnings/publication rejection, and the actual saved-template cycle fallback.

API unit tests: **136 passed**. New database-backed integration cases: **4 passed**. The broader meal-selection suite passed **32** cases and failed **3** existing tests because these referenced files are absent: `20261026_package_discounted_price.sql`, `tomorrow_menu_diagnostics.sql`, and `20261026_address_delivery_slots.sql`. The address failure was reproduced separately and is a `FileNotFoundException`. These missing dependencies were not hidden or recreated as part of this change.

Flutter targeted checkout/menu tests: **28 passed**, including all five package sizes, replacement sheets, independent snack replacement, and shortages. The complete Flutter suite passed **252/252** and analysis of `lib`/`test` reported no issues. React Admin editor tests passed **4/4**, including the new capacity warning; TypeScript checking and ESLint also passed. `git diff --check` passed in all three repositories.

### Modified files

Flutter repository:

- `lib/features/checkout/domain/checkout_models.dart`
- `lib/features/checkout/presentation/checkout_controller.dart`
- `lib/features/dashboard/presentation/tomorrow_menu_section.dart`
- `test/place_order_test.dart`
- `test/tomorrow_menu_test.dart`
- `README.md`

API repository (`../diet-time-api`):

- `src/BuildingBlocks/DietTime.Application/Validation.cs`
- `src/BuildingBlocks/DietTime.Contracts/ApiContracts.cs`
- `src/BuildingBlocks/DietTime.Persistence/OrderService.cs`
- `src/BuildingBlocks/DietTime.Persistence/UpcomingMealService.cs`
- `src/BuildingBlocks/DietTime.Persistence/TomorrowMealService.cs`
- `src/BuildingBlocks/DietTime.Persistence/AdminMealService.cs`
- `tests/DietTime.UnitTests/OrderTests.cs`
- `tests/DietTime.Meal.Api.IntegrationTests/PackageSelectionIntegrationTests.cs`

React Admin repository (`../diet-time-admin-spa`):

- `src/features/meal-plans/PlanBuilderPage.tsx`
- `src/features/meal-plans/PlanBuilderPage.test.tsx`
