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

## Calendar with overlapping orders — 27 October 2026

The customer calendar now displays all current and completed orders from the existing fully paginated customer order list. Two orders delivering on the same date have separate expandable cards, packages, statuses, meals, snacks and delivery details. The single-order layout is retained. Dates with multiple deliveries show a count badge; mixed statuses use a neutral indicator, with individual statuses inside each card.

### Root cause and data flow

`_calendarOrder` in `customer_dashboard_screen.dart` selected `activeOrders.first`, even though the dashboard controller already retained multiple active orders. `UpcomingDeliveriesScreen` then watched only that order's service-day provider and used `firstOrNull` for the selected date and its status. Completed orders had no calendar path. These presentation restrictions discarded other orders before their service days or dishes were requested.

The existing API meal query already returns every non-cancelled selection ordered by category and selection number. It does not group by meal type or limit regular meals to three. The apparent missing dishes were associated with orders the calendar never loaded; no additional selection-grouping defect was found in that query.

The new `CustomerDeliveryCalendar` resolves all current/completed order details, reusing details already loaded by the dashboard. Each order uses its existing `upcomingMealDaysProvider(orderId)`. `deliveriesByDate` builds `Map<DateTime, List<CalendarDelivery>>`; every entry retains its order and service-day identity. Each card independently fetches its `DailyMealMenu` using `(orderId, dayId, language)`. Meals from different orders are never merged. Per-order request failures produce a retry state instead of silently displaying an incomplete delivery count. When Tomorrow's Menu accepts a finalized selection, it invalidates only that order's service-day list and that day's menu cache so the calendar updates its lock/status without restarting the app.

### Existing API endpoints and additive response fields

No duplicate calendar endpoint was introduced. The authenticated data flow remains:

```text
GET /api/v1/customer-profiles/{customerProfileId}/orders?pageNumber=...&pageSize=...
GET /api/v1/orders/{orderId}
GET /api/v1/orders/{orderId}/upcoming-meals
GET /api/v1/orders/{orderId}/service-days/{dayId}/menu?language=en
```

The calendar combines these existing per-order responses. The API continues validating ownership against the authenticated user's active customer profile.

| Response | Added or clarified fields |
| --- | --- |
| Each `data[]` row from `upcoming-meals` | `orderId`, actual `subscriptionId`, `planName`, `mealCount`, `snackCount`, `selectionStatus`, `selectionLocked`, `deliveryStatus` |
| `data` from the service-day menu | `orderId`, actual `subscriptionId`, `selectionStatus`, `selectionLocked`, `deliveryStatus` |
| Each `selectedMeals[]` row | `selectionNumber`; dish details and category remain in `meal` |

Selected regular dishes and snacks remain in the existing `selectedMeals` collection, distinguished by `meal.category`. The service filters by the specific `subscription_service_day_id`, excludes cancelled selection rows, and returns every position. It never chooses just one row per meal type. A four-meal package therefore returns regular positions 1–4 plus its snack, and a five-meal package returns positions 1–5 plus its snack. Flutter rejects responses identifying a different order or day. Lock/finalization metadata also prevents a legacy edit flag from enabling changes to a locked day.

The service-day query excludes cancelled/skipped service days and planned deliveries on cancelled orders. Completed orders retain delivered history. Calendar navigation spans the included orders' delivery periods. Confirmation, automatic finalization, and kitchen behavior retain their existing service-day scope; calendar reads do not modify selections or lock days.

### Database review

No tables, migrations, constraints or indexes were added. Multiple orders can share a customer, and multiple subscriptions can share a delivery date. Existing unique indexes are scoped to `(subscription_id, service_date)` and `(order_id, service_date)`, not `service_date` alone. The existing `(customer_profile_id, placed_at)` index supports customer order retrieval. Service-day queries use the order/date index; selection lookups are supported by the service-day prefix of the existing position/dish indexes. The category/selection-position and legacy-type constraints are preserved. The isolated PostgreSQL fixture exercises two orders on the same date with four and five regular selections using the same regular meal type.

### Verification and modified files

New Flutter tests verify the real dashboard calendar with two active orders and two completed orders, overlapping 4+1 and 5+1 packages, all selected dishes and independent snacks, mixed-status indicators, cancelled-order exclusion, failure/retry, and cross-order response rejection. Existing single-order calendar/dashboard tests continue to pass.

Three new PostgreSQL-backed integration tests pass. They verify both authenticated per-order endpoints on Wednesday, 28 October 2026, selection positions, confirmed/pending isolation, a cross-order service-day rejection, completed deliveries, cancelled selections/days/orders, ownership checks, and kitchen reports retaining both order references and all eleven dishes after both orders confirm. The API unit suite passes **136/136**. The complete Flutter suite passes **261/261**, including the new order-specific calendar cache refresh test, and Flutter analysis reports no issues. `git diff --check` passes in both repositories.

The broader PostgreSQL meal-service run passes **35 tests** and fails **1**: `Allergens_restrictions_inactive_slots_and_wrong_menu_days_are_excluded`. The same test was run against a separate archive of the unchanged committed API and fails there as well. Its assertion shows an allergen-associated dish remains eligible; the current committed `EligibleAsync` query has no allergen exclusion. That query is unchanged by this calendar work. This existing eligibility issue remains unresolved and the broader suite is not reported as green. Three previously identified tests referencing absent SQL files (`20261026_package_discounted_price.sql`, `tomorrow_menu_diagnostics.sql`, `20261026_address_delivery_slots.sql`) were explicitly excluded from this broader run.

Flutter files:

```text
lib/features/dashboard/data/upcoming_meals_repository.dart
lib/features/dashboard/domain/upcoming_meals.dart
lib/features/dashboard/domain/calendar_delivery.dart
lib/features/dashboard/presentation/customer_dashboard_screen.dart
lib/features/dashboard/presentation/customer_delivery_calendar.dart
lib/features/dashboard/presentation/upcoming_deliveries_screen.dart
lib/features/dashboard/presentation/tomorrow_menu_section.dart
test/upcoming_meals_repository_test.dart
test/calendar_multiple_orders_test.dart
test/tomorrow_menu_test.dart
README.md
```

API files, relative to `../diet-time-api`:

```text
src/BuildingBlocks/DietTime.Contracts/UpcomingMealContracts.cs
src/BuildingBlocks/DietTime.Persistence/UpcomingMealService.cs
tests/DietTime.Meal.Api.IntegrationTests/CalendarMultipleOrdersTests.cs
```

Validation uses isolated test data; no production database, API deployment, or app release was changed. This calendar change does not establish the cause of the previously reported missing dishes in the live Tomorrow's Menu.

## Compact meal panel, address rules and questionnaire skip — 28 October 2026

### Behavior and root causes

Tomorrow's Menu previously rendered large meal cards directly on the dashboard and repeated its confirmation status in several lines. Confirmed packages now show the delivery date, plan, purchased quantities, one green status indicator, and the persisted dish count. The full list starts collapsed. **View confirmed meals** and **Hide confirmed meals** control compact, read-only rows with a small thumbnail, dish name, category and optional calories. Multiple active orders retain separate panels with order references, even when their plan names match.

Unconfirmed panels show selection progress and **Choose your meals**. This opens the existing picker in a full-screen view backed by the same menu and draft state; closing and reopening preserves unsaved choices and provisional defaults. All API-provided eligible dishes remain available in that picker. Selection replacement, the confirmation review sheet, ownership/service-day targeting, server-authoritative success, calendar cache refresh, and the 9 PM Qatar cutoff are retained. The presentation change does not alter the API's menu eligibility query or create additional selections.

Address fields previously shared required-only checks in Flutter, while most API fields only had length limits. Client and server now apply matching field rules:

| Field | Validation |
| --- | --- |
| Building No | Required; Unicode letters/digits and space, hyphen or slash; maximum 50 characters |
| Street | Required; letters and digits, including numeric streets such as `960`, plus common street punctuation; maximum 50 characters |
| Unit Number | Optional; alphanumeric identifiers with space, hyphen or slash; maximum 50 characters |
| Zone No | Required; decimal digits only, including Arabic digits; numeric keyboard; maximum 50 characters |
| Area | Required; English/Arabic letters, combining marks, spaces and common name punctuation; at least one letter, no digits; maximum 150 characters |
| Directions | Optional free text, including numbers and punctuation; maximum 500 characters |

Input is trimmed when submitted, without rewriting the form's valid entered values. Area errors remain visible inline instead of silently deleting invalid characters. The zone formatter accepts complete numeric pastes and preserves active IME composition; it rejects an invalid edit as a whole rather than stripping characters out of a pasted value. Copy/paste and RTL behavior remain available. API field errors are shown beside the relevant input and cleared as that field is corrected.

Address creation applies all rules. The existing update endpoint validates changed fields while permitting unchanged legacy values in the newly restricted fields, allowing delivery-slot updates without forcing a rewrite of an older address. Both paths return structured field validation errors. Reads and existing saved records are not migrated or automatically corrected. There are no new database CHECK constraints, tables or migrations.

The questionnaire introduction's **Not now** previously navigated directly to Browse Menu, or merely popped the profile screen, without consulting authentication. It now saves available answers to the existing encrypted guest/per-user draft format without changing completion or confirmation flags. Session validity is rechecked rather than relying on the cached authenticated flag or customer name. Guests and expired sessions use the existing phone Login route with Dashboard as the pending destination; authenticated customers go directly to Dashboard. The existing refresh-token flow handles resumable sessions.

A separate in-memory deferral flag prevents the current skip/login journey from immediately reopening the questionnaire, including the existing OTP error fallback and authenticated landing gate. It is not questionnaire completion, and logout clears it. Drafts remain durable in secure storage. Customers can complete the questionnaire later through their profile; starting a new plan after deferral routes incomplete questionnaires back to that existing flow, preserving the existing captured-answer purchase gate. Existing completed answers, birth dates and fractional measurements are preserved when the customer has not changed them.

### Validation

- Flutter analysis of `lib` and `test`: no issues.
- Complete Flutter suite: **272/272 passed**. Coverage includes confirmed 3- and 5-meal expand/collapse, read-only dishes, all eligible options for 1–5-meal packages, provisional and unsaved draft retention, same-plan order isolation, actual address form entry and numeric keyboard, Arabic/English area rules, guest/authenticated/expired-session skip routing, local draft preservation and unchanged completion flags, and existing checkout/calendar/authentication regressions.
- API unit suite: **148/148 passed**, including 12 new address cases.
- PostgreSQL-backed authenticated HTTP test: **1/1 passed**. It exercises invalid creation with structured BuildingNo/Area/ZoneNo errors, valid Arabic address creation and trimming, numeric street and alphanumeric building/unit fields, valid/invalid edits, unchanged legacy retrieval and delivery-slot updates, and rejection of newly invalid area changes. It also verifies the fixture's order, price and meal-selection state is unchanged.
- `git diff --check`: passed in both repositories.

All database writes during verification were confined to disposable test databases. No existing customer order, pricing or meal-selection data was altered. No production database changes, deployment, app release, or physical-device verification was performed.

### Modified files

Flutter files, relative to this repository:

```text
lib/features/authentication/data/mock_authentication_service.dart
lib/features/authentication/presentation/otp_auth_controller.dart
lib/features/authentication/presentation/otp_verification_page.dart
lib/features/checkout/domain/address_validation.dart
lib/features/checkout/domain/checkout_models.dart
lib/features/checkout/presentation/checkout_controller.dart
lib/features/checkout/presentation/customer_address_screen.dart
lib/features/dashboard/presentation/customer_dashboard_screen.dart
lib/features/dashboard/presentation/tomorrow_menu_section.dart
lib/features/onboarding/presentation/onboarding_screen.dart
lib/features/personalization/presentation/authenticated_landing_screen.dart
lib/features/personalization/presentation/questionnaire_deferral_controller.dart
test/dashboard_improvements_test.dart
test/tomorrow_menu_test.dart
README.md
```

API files, relative to `../diet-time-api`:

```text
src/BuildingBlocks/DietTime.Application/Validation.cs
src/Apis/DietTime.Meal.Api/Controllers/CustomerAddressesController.cs
tests/DietTime.UnitTests/CustomerAddressValidationTests.cs
tests/DietTime.Meal.Api.IntegrationTests/AddressInputValidationTests.cs
```

## Twilio runtime diagnostics — 28 October 2026

The configured environment-variable names match `TwilioWhatsApp__Enabled`, `__AccountSid`, `__AuthToken`, `__FromNumber`, `__OperationsNumber`, and `__NewOrderContentSid`. Environment variables can override the disabled checked-in defaults. Local defaults therefore do not establish the configuration of a deployed service. The reported enabled flag and absence of visible Twilio logs are not enough to identify the live delivery failure.

The API now provides this read-only endpoint under its existing Admin authorization:

```http
GET /api/v1/admin/integrations/whatsapp/twilio/configuration
Authorization: Bearer <admin-token>
```

Deploy/restart the updated API before calling it. The response contains `enabled`, `configurationComplete`, boolean `checks` for each setting, `invalidOrMissingSettings`, and a description of the existing operations-recipient/new-order trigger. It returns no configured account SID, template SID, phone number or auth token. `providerVerified` is explicitly false: presence/format checks do not verify credentials, WhatsApp sender approval, recipient sandbox membership, or template approval. The request performs no Twilio call and sends no message. A 404 after updating the caller URL can indicate an older deployment or a different service; 401/403 requires a valid Admin session.

Logging now distinguishes:

- Startup: `Twilio WhatsApp runtime configuration` with enabled/completeness flags and invalid/missing setting names, never their values.
- Order processing: dispatch after commit, `idempotent_replay` skips, disabled skips, and existing invalid-order-data field warnings.
- Provider requests: attempts, HTTP rejection status and provider error code, timeouts, network failures, acceptance SID and provider status.

Order replays continue to avoid duplicate notifications. Success logs now say **accepted by Twilio**, rather than claiming a queued request was delivered. A successful HTTP response without a Message SID is rejected as `invalid_provider_response`; an immediate `failed` or `undelivered` provider status is also treated as failure. Queued acceptance still requires later delivery confirmation through Twilio's message status/logs. See the [Twilio Message resource documentation](https://www.twilio.com/docs/messaging/api/message-resource).

The previous log containing the entire template-variable payload, customer name, phone and delivery address was replaced by order identity, template SID and variable count. Provider rejection logs do not include request bodies or credentials.

Validation: **164 API unit tests passed**, including seven new diagnostic/status/logging cases. **Four HTTP endpoint tests passed**, covering enabled/disabled runtime settings, Admin authorization, anonymous/customer rejection, exclusion of configured secret/phone/SID values, and zero send calls. HTTP authorization tests run with JWT authentication outside the development fallback. All sends in unit tests use a fake HTTP handler; the endpoint tests use a provider that throws if sending is attempted. No live messages, database changes, notification resends, or deployment were performed. Live delivery remains unverified pending the running service's diagnostics/provider result.

Modified API files, relative to `../diet-time-api`:

```text
src/Apis/DietTime.Meal.Api/Program.cs
src/Apis/DietTime.Meal.Api/Controllers/WhatsAppIntegrationController.cs
src/BuildingBlocks/DietTime.Application/WhatsApp.cs
src/BuildingBlocks/DietTime.Infrastructure/TwilioWhatsAppService.cs
src/BuildingBlocks/DietTime.Persistence/OrderService.cs
tests/DietTime.UnitTests/WhatsAppTests.cs
tests/DietTime.Meal.Api.IntegrationTests/TwilioConfigurationApiTests.cs
```

An Admin can now fetch the final provider status of an accepted message without sending again:

```http
GET /api/v1/admin/integrations/whatsapp/twilio/messages/MMa84d8c229315011a1ef25296af380a89
Authorization: Bearer <admin token>
```

Deploy/restart the updated API before using this route. It returns `messageId`, `status`, `deliveryConfirmed`, `errorCode` and `errorMessage`. `deliveryConfirmed` is true only for `delivered` or `read`. A successful lookup can report an `undelivered` or `failed` message; inspect its error code instead of interpreting HTTP 200 as delivery. The lookup accepts valid SM/MM message IDs, uses the server's account credentials, and does not return message bodies or recipient numbers. It also works when outgoing messaging is disabled. Invalid IDs are rejected before calling Twilio; provider lookup failures return structured errors. No live message was sent or queried during implementation; production delivery remains unverified.

Status lookup validation: **175 API unit tests passed** and **8 Twilio HTTP endpoint tests passed**. These cover queued/delivered/read/failed/undelivered results, SM/MM IDs, provider authentication/not-found errors, timeouts, mismatched records, invalid-ID rejection, Admin-only access and zero sends. No order, pricing, meal-selection or database data was altered.

## Customer application implementation reports

The following implementation reports were consolidated from the project documentation. Test counts describe the checks recorded for each change.

### Customer journey audit

#### Investigation before implementation

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

##### Root causes

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

##### API and PostgreSQL findings

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

#### Unified design

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

#### Verification plan

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

#### Implementation and changed files

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

#### Executed verification

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

#### Scenario coverage and remaining manual verification

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

#### Follow-up: name prompt before login (2026-11-01)

The gateway previously used `restoreSession()`, which immediately accepted a
cached authenticated flag. The secure-storage service also accepted an in-memory
authentication marker when credentials were absent. Neither is sufficient to
open name collection for a guest.

The coordinator now calls `ensureCurrentSession()` before loading the profile.
This validates stored credentials or refreshes them, clears an unusable session,
and preserves the destination intent when login is needed. The production
secure-storage service no longer grants access from an in-memory marker alone.
Ordinary session restoration retains its previous refresh behavior; the explicit
onboarding check requires a usable session. Valid restored customers still skip
login and completed onboarding.

Regression tests use the real phone-login/OTP screens and authentication methods
for guests, cached authenticated flags without credentials, and expired tokens,
under both intents. They assert no profile load or name panel before successful
OTP, then exactly one name panel afterward. Additional tests retain the valid
restored-session path and reject authentication markers without credentials.
Existing fake authenticated test controllers explicitly provide fake session
validation; the new regression cases exercise the real validation methods.

Executed after this correction: **447 Flutter tests passed**, static analysis
reported **no issues**, and `git diff --check` passed. Logs:
`artifacts/login-before-name-full-tests.log` and
`artifacts/login-before-name-analysis.log`. No API changes were needed for this
follow-up. Real-device reproduction and release checks remain outstanding.

### Three customer flow corrections

#### 1. Questionnaire save conflict

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

#### 2. Back to Dashboard

The existing meal-plan screen has a compact, localized Back to Dashboard header
action when the authenticated customer can access Dashboard. It uses the existing
home route. It does not select a package, submit an order, or modify plan cards,
prices or Continue. The ordinary back button remains for other pushed entries.

#### 3. Questionnaire introduction and Not Now

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

#### Exact changed files

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

#### Executed validation

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

### Login UI, back arrow, OTP editing and automatic meal categories

#### Root causes and corrections

1. **Login panel:** its minimum height was the viewport remainder below the hero,
   producing blank space after Continue. The scroll view also added keyboard
   insets while Scaffold already resized its body. Removed the panel minimum and
   duplicate keyboard padding, reduced its bottom padding to 12, and kept SafeArea.
   Extra height now exposes the existing background instead of stretching the
   panel. Logo, copy, rounded corners, input and validation are unchanged.
2. **Meal-plan back action:** the header used a labelled text button. It is now a
   green IconButton with a tooltip and a standard touch target, at the top-left.
   The same existing dashboard route and availability check are retained. No plan
   selection, checkout mutation or order request is performed by this action.
3. **OTP editing:** six independent editors relied on hardware KeyEvent backspace
   handling, which did not reliably cover mobile IME deletion. A multi-character
   cell edit was also treated as a full-code paste. One native TextField now owns
   the value, cursor, deletion, selection, clipboard menu and one-time-code autofill.
   The existing six-box appearance renders that value. Tapping a box selects its
   digit, replacement advances the caret, and a complete pasted code replaces the
   whole value even when an earlier digit is selected. Authentication, OTP
   generation, expiry, verification and navigation were not changed.
4. **Automatic meal assignments:** initialization and cutoff finalization both
   chose distinct dish IDs without enforcing distinct meal-type IDs. Both now use
   the same assignment rule over their existing eligible template/week/weekday
   options. Meal types are grouped by configured ID and sorted by configured
   DisplayOrder. Within each type, existing saved-default, customer-preference,
   IsDefault and display-order priorities are retained. Ranked alternatives are
   considered only when needed to avoid a shared dish blocking another category.
   Snacks are assigned separately using the existing snack classification and
   quantity. No Breakfast/Lunch/Dinner IDs are hardcoded.

Insufficient distinct types produce the existing partial/needs-review state with
a specific configuration reason instead of duplicate-category meals. A failed
cutoff assignment retains existing selections. Confirmed/locked days retain their
existing early exit; unconfirmed customer-sourced selections are preserved for
review. Initialization still skips existing service dates under its existing
per-order lock. No new startup reassignment, history deletion, migration, package
change, payment/approval change or cutoff change was introduced.

#### Exact modified files

Relative to `diet-time-app`:

- `lib/features/authentication/presentation/phone_login_page.dart`
- `lib/features/authentication/presentation/otp_verification_page.dart`
- `lib/features/plans/presentation/meal_plan_screen.dart`
- `test/otp_flow_test.dart`
- `test/meal_plan_screen_test.dart`
- `README.md` (this report)

Relative to the sibling `diet-time-api`:

- `src/BuildingBlocks/DietTime.Application/AutomaticMealAssignmentRules.cs` (new)
- `src/BuildingBlocks/DietTime.Persistence/UpcomingMealService.cs`
- `src/BuildingBlocks/DietTime.Persistence/TomorrowMealService.cs`
- `tests/DietTime.UnitTests/AutomaticMealAssignmentTests.cs` (new)
- `tests/DietTime.Meal.Api.IntegrationTests/UpcomingMealServiceTests.cs`

#### Executed verification

- Full Flutter suite: **471 passed**.
- Targeted OTP/login/meal-plan suite: **44 passed**, including deletion at each of
  six positions, empty-position backspace, replacement at every position, native
  long-press Paste over an existing code, autofill editing events/hints, keyboard
  insets, compact/tall viewports, safe-area spacing, dashboard navigation and no
  checkout creation by the back action.
- Full ASP.NET Core unit suite: **257 passed**. Assignment tests cover 1–5 meal
  packages, configured type order, several slots sharing one type, independent
  snack quantities, default/preference priorities, shared-dish fallback, missing
  configuration and deterministic repeat selection.
- Database-free `SubscriptionMenuRulesTests` in the integration-test assembly:
  **9 passed**, covering the four-week cycle and wraparound.
- PostgreSQL integration project: build succeeded, **0 errors** and eight existing
  warnings in unrelated API controllers. Added persistent distinct-type,
  confirmed-selection preservation, idempotent rerun and shortage coverage; aligned
  its fixture with three configured meal types for its three-meal package.
- Dart static analysis: **no issues**. App/API `git diff --check` passed.

Logs are under `artifacts/four-fixes-*.log`.

#### Verification still required

No physical iPhone, TestFlight or Android testing was performed. Flutter device
discovery found Windows, Chrome and Edge only. Tests exercised Flutter's native
editing/clipboard path and simulated autofill events; real SMS autofill and mobile
keyboard behavior must still be checked on both mobile platforms.

Live PostgreSQL integration tests were not executed because
`UPCOMING_MEALS_TEST_CONNECTION` is not configured. Date/weekday SQL filtering,
persistent history/locking and database idempotency have compiled test coverage,
not an executed database validation in this session. Run the UpcomingMealService
integration suite against an isolated PostgreSQL instance before release.
The backend assignment changes must be deployed alongside the Flutter changes.

### Delivery and Takeaway for every eligible package

#### Changes

The legacy package delivery flag previously hid the selector, forced Takeaway in
checkout state, rejected Delivery at placement, and rejected it during subsequent
fulfillment validation. Customer package responses also exposed that restriction.

Both methods are now available regardless of that flag. Existing package
availability, active address ownership, active delivery slots, active takeaway
branches, fulfillment snapshots and order/subscription processing remain intact.
The legacy database column/admin metadata remain for compatibility; they no longer
restrict customer fulfillment. No schema migration or admin feature was added.

One compact green information component displays the requested Delivery Information
notice immediately in the plan summary when Delivery is selected and on Delivery
order confirmation. It disappears for Takeaway. English and Arabic use the
existing ARB/generated localization system. Delivery's price caption is now
Meal-plan amount; Takeaway retains its existing total captions and pricing.

No fees, estimated amounts, distance calculations, daily charges, pricing changes,
new financial configuration, tables or columns were introduced. The price values,
duration, quantities and request amounts are unchanged.

#### Modified files for this request

Flutter, relative to `diet-time-app`:

- `lib/features/checkout/domain/checkout_models.dart`
- `lib/features/checkout/presentation/checkout_controller.dart`
- `lib/features/checkout/presentation/delivery_information_notice.dart` (new)
- `lib/features/checkout/presentation/plan_summary_screen.dart`
- `lib/features/checkout/presentation/order_placed_screen.dart`
- `lib/app/localization/customer_copy.dart`
- `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`
- Generated `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`,
  `app_localizations_ar.dart`
- `test/package_delivery_test.dart`
- `README.md` (this report)

ASP.NET Core, relative to the sibling `diet-time-api` repository:

- `src/BuildingBlocks/DietTime.Domain/Entities.cs`
- `src/BuildingBlocks/DietTime.Persistence/CustomerMealPlanPurchaseService.cs`
- `src/BuildingBlocks/DietTime.Persistence/MealQueryService.cs`
- `src/BuildingBlocks/DietTime.Persistence/OrderService.cs`
- `src/BuildingBlocks/DietTime.Persistence/StaffOrderService.cs` (only removal of
  the legacy delivery-flag predicate; approval workflow remains unchanged)
- `tests/DietTime.UnitTests/DeliveryEligibilityTests.cs`
- `tests/DietTime.Meal.Api.IntegrationTests/PackageDeliveryIntegrationTests.cs`

Earlier uncommitted login/OTP/back-arrow/automatic-assignment work was preserved.

#### Verification

- Targeted checkout/order tests: 36 passed; the additional Delivery payload test
  then passed in the 14-test package fulfillment suite.
- Final full Flutter suite: **479 passed** (`artifacts/fulfillment-full-tests.log`).
- ASP.NET Core unit suite: **257 passed**.
- Dart static analysis: **no issues**.
- API integration project: **build succeeded**, zero warnings/errors in the final
  incremental build. PostgreSQL integration tests were not executed because the
  isolated `UPCOMING_MEALS_TEST_CONNECTION` is not configured.
- App/API `git diff --check`: passed.

Tests cover both legacy flag values, Delivery and Takeaway, English/Arabic notices
and captions, unchanged displayed prices and order payload amounts, required
addresses/slots/branches, selection preservation and normal checkout clearing
after successful placement. Compiled integration coverage additionally checks
customer API eligibility, stored fulfillment snapshots and equal plan amounts
across Delivery/Takeaway. Live database and real-device verification remain
outstanding. Deploy the API and Flutter changes together.
## Next-day booking cutoff and order-row alignment

New bookings now enforce the 9:00 PM Qatar boundary (18:00 UTC), including exactly
9:00 PM. Before cutoff the minimum is tomorrow; at/after cutoff it is the day after
tomorrow, subject to existing longer lead times, selected weekdays and unavailable
service dates. Friday remains excluded. The previous booking rule checked dates
only; the separate meal-selection cutoff did not protect new order placement.

The customer API advertises the current minimum start date. Order placement checks
fresh server time during validation and again after database writes, before commit;
a request that crosses cutoff rolls back its new order/events and is not enqueued
for notification. Existing bookings and idempotent replays are preserved.
Flutter advances the supplied server clock across cutoff, rejects invalid checkout
dates locally, and rechecks a calendar left open before confirming. English/Arabic
guidance explains the cutoff. No prices, payment logic or database schema changed.

The recent-order row previously allocated space to a loose status Flexible beside
an Expanded title, leaving unused space after the arrow. Its trailing group now
fills the remaining row allocation and aligns the status/arrow to the end (right
in English, mirrored for Arabic), including narrow screens.

Flutter files: `lib/features/plans/domain/meal_plan_purchase_selection.dart`,
`lib/features/plans/presentation/meal_plan_start_date_screen.dart`,
`lib/features/checkout/domain/checkout_models.dart`,
`lib/features/checkout/presentation/checkout_controller.dart`,
`lib/features/dashboard/presentation/customer_dashboard_screen.dart`,
`lib/app/localization/customer_copy.dart`, English/Arabic ARBs and generated
localizations, `test/booking_cutoff_test.dart`, and `test/customer_dashboard_test.dart`.
API files in `diet-time-api`: `src/BuildingBlocks/DietTime.Application/Rules.cs`,
`src/BuildingBlocks/DietTime.Persistence/CustomerMealPlanPurchaseService.cs`,
`src/BuildingBlocks/DietTime.Persistence/OrderService.cs`,
`tests/DietTime.UnitTests/BookingCutoffTests.cs`, and
`tests/DietTime.Meal.Api.IntegrationTests/BookingCutoffIntegrationTests.cs`.

Executed validation: **508 Flutter tests passed**, **317 API unit tests passed**,
Dart static analysis clean, API integration project compiled (zero errors; eight
existing unrelated controller warnings), and app/API whitespace checks passed.
Logs: `artifacts/booking-cutoff-*.log`. PostgreSQL transaction/replay integration
tests were compiled but not executed: `UPCOMING_MEALS_TEST_CONNECTION` is not
configured. Physical-device verification remains outstanding. Deploy the API
changes alongside the rebuilt app for authoritative server enforcement.

## Consolidated questionnaire, tour and kitchen UI fixes

The seven targeted fixes reuse the existing screens, router, spotlight host,
notification queries, fulfillment dialog/API and preparation export endpoint.

### Root causes and corrections

| Issue | Root cause | Correction |
| --- | --- | --- |
| Adjust Plan at 100% | The profile questionnaire had no dedicated edit initialization; its progress came from persisted completion and its introduction used resume metadata. | The existing Adjust Plan route requests edit mode. Completed profiles open at question 1 with saved values, 17% step progress and accurate accessibility progress. Opening does not save or reset completion. Incomplete profiles retain the introduction/resume behavior. |
| Enable App Tour | The toggle saved the preference while staying on Profile, but the existing automatic start trigger runs on Home. The tour navigator could also incorrectly treat Home as already selected after a previous tour. | After a successful preference save, navigate through the existing dashboard callback to Home. Its readiness trigger starts the same spotlight host after targets render. Re-enabling after Skip also works; failed saves do not launch a tour. |
| Notification dropdown | Large nested cards, repeated unread information, absolute timestamps and generous padding made the panel difficult to scan. | A responsive 400px panel uses separator rows, small icons, relative timestamps with the Qatar timestamp in a tooltip, one scrolling list and accessible fixed controls. Long values wrap. |
| Scheduled Orders | Nine table columns competed for the drawer width. | Compact responsive cards retain customer/order/plan, item counts, fulfillment details, approval and daily status, and the existing fulfillment control. Four aligned counters, filters and sorting remain intact. Only overdue cards use a red background. |
| Preparation Summary | Expanded customer cards appeared before the kitchen's primary dish list; totals and categories were spread across large panels. | Compact portion counters and category totals precede the menu work list, followed by expandable customer details and the existing plan breakdown. Allergens stay visible while collapsed; the PDF action remains prominent. |
| Repeated allergen prefixes | Preferences and allergies were flattened into one prefixed string list. | The existing response adds separate structured preference/allergen labels, including saved allergen notes. UI/PDF safely handle legacy anchored prefixes, retain meaningful text, deduplicate labels and use “None specified” for empty groups. Existing legacy fields are retained. |
| Generic meal categories | The preparation query explicitly replaced configured type names with Meal/Snack, and customer dishes were grouped only by broad classification. | One selection-based projection resolves the specific option's slot/type, falling back to the selection's explicit type for legacy rows. Configured names/order feed aggregates, customer dishes, overview and PDF. Classification remains separate. Unmapped rows retain their quantities under Uncategorized Meal/Snack and emit a diagnostic warning. |

### Modified files

Flutter application (`diet-time-app`):

- `lib/app/router/app_router.dart`
- `lib/features/onboarding/presentation/onboarding_screen.dart`
- `lib/features/app_tour/app_tour_host.dart`
- `lib/features/dashboard/presentation/customer_dashboard_screen.dart` — tour navigation guard only; order cards unchanged.
- `test/widget_test.dart`
- `test/app_tour_test.dart`
- `README.md` — this report.

React Admin (`../diet-time-admin-spa`):

- `src/layouts/NotificationBell.tsx`
- `src/layouts/NotificationBell.test.tsx`
- `src/features/delivery-calendar/types.ts`
- `src/features/delivery-calendar/components/DateDetailsDrawer.tsx`
- `src/features/delivery-calendar/components/DateDetailsDrawer.test.tsx`
- `src/features/delivery-calendar/components/FulfillmentRefresh.test.tsx`

ASP.NET Core (`../diet-time-api`):

- `src/BuildingBlocks/DietTime.Contracts/DeliveryPreparationContracts.cs`
- `src/BuildingBlocks/DietTime.Application/AdminDeliveryCalendar.cs`
- `src/BuildingBlocks/DietTime.Application/PreparationDisplayText.cs`
- `src/BuildingBlocks/DietTime.Persistence/AdminDeliveryCalendarService.cs`
- `src/BuildingBlocks/DietTime.Infrastructure/KitchenPreparationPdfReportGenerator.cs`
- `tests/DietTime.UnitTests/DeliveryPreparationTests.cs`
- `tests/DietTime.UnitTests/KitchenPreparationReportTests.cs`
- `tests/DietTime.Meal.Api.IntegrationTests/PreparationCustomerDetailsTests.cs`

### Response and PDF compatibility

Existing response fields and endpoint paths remain available. Each customer dish
adds `mealCategoryId`, `mealCategoryName`, `mealCategoryDisplayOrder` and
`mealClassification`; its existing `category` still represents meal/snack.
Aggregated `mealTypes` retain `mealTypeId`/`mealTypeName` and add
`mealCategoryDisplayOrder`/`mealClassification`. Customer selections add
`mealPlanName`, `foodPreferences` and `allergens`.

The PDF consumes the same existing preparation response as Admin. Customer dishes
use configured category headings, and preferences/allergens are separate, with
allergens emphasized. Existing aggregate dish quantities, totals, export/download
handling and plan breakdown are preserved. No PostgreSQL migration or saved-data
updates are required. No unrelated workflow changes were necessary.

### Executed validation and limits

- Flutter: **509 tests passed** across the full suite. Coverage includes saved edit answers, step progress, Previous/Continue, successful edited-answer persistence, unchanged onboarding/resume behavior, immediate tour launch, re-enabling after Skip, Finish persistence and existing spotlight interactions.
- API/PDF: **320 unit tests passed**, including same-dish/different-category quantities, sorting, structured/legacy dietary normalization, meaningful notes and extracted PDF content.
- Preparation API endpoint checks: **7 passed**; **5 PostgreSQL-backed tests skipped** because `UPCOMING_MEALS_TEST_CONNECTION` is not configured. The skipped tests compiled, including customer-selected and automatic slot mapping. Live database query execution and persisted-data verification remain outstanding; no production database was accessed.
- Headless Chrome: existing components passed responsive checks at **1440×900** and **390×844** with isolated mock data: drawer overflow, configured preparation categories, collapsed/expanded customer cards, notification viewport bounds, long content, list scrolling and visible footer controls. Temporary preview files were removed.
- Repository-wide Admin lint reports the existing `react-refresh/only-export-components` warning in untouched `src/features/orders/OrderReviewDetails.tsx`. That unrelated file was left unchanged.

- React Admin: **190 tests passed across 41 files** with `npm test -- --maxWorkers=2`. The initial unrestricted parallel run had one unrelated pricing-test timeout; reduced concurrency passed without changing that test or its timeout. All **40 notification/calendar tests** also passed in the focused run.
- Static/build checks: Dart analysis reported **no issues**; Admin TypeScript/production build and ESLint for all six changed Admin files passed. Vite emitted a large-chunk advisory. App, Admin and API `git diff --check` checks passed.
- Local validation logs are in ignored `artifacts/consolidated-*.log` and `artifacts/preparation-*.log`. Preview scripts/screenshots were moved outside the repositories; no preview page or generated build output is part of the changes.

## Safe package pause and customer cancellation

Customer cancellation previously checked approval transitions, service start and
preparation locks, but never combined the separate persisted approval and payment
statuses. The Flutter action also checked approval status alone. A future confirmed,
paid booking could therefore reach cancellation and the existing refund-pending
branch. The customer endpoint now rejects that combination under the order row lock
with HTTP **409**, code **`ORDER_CANCELLATION_NOT_ALLOWED`**, and the requested
explanation. The rejected command changes neither approval nor payment. Existing
stricter fulfillment restrictions, eligible unpaid cancellation, its confirmation
dialog, and Admin authorization/payment behavior remain intact.

Pause was not previously implemented. The new controls live in the existing
dashboard and order details, with English/Arabic labels; no router destination or
separate subscription-management page was introduced. They show remaining service
days, next delivery, projected end date, pause dates/status and Resume Early when
available. Start-date picking uses fresh server eligibility and Qatar time, excludes
today/past/Friday/committed dates, and requires an explicit backend preview before
confirmation. The preview displays paused/rescheduled day counts and the revised
end date. No eligible dates means a disabled action with an explanation.

The API validates again after locking the order and service days, including the
current clock/cutoffs, versions and saved schedule fingerprint. Changes are
transactional and command IDs make pause/resume retries idempotent. Existing
service-day IDs and purchased day counts are retained; fulfilled, locked and
otherwise committed records are not moved. Unlocked remaining days are rescheduled
on or after the selected resume date, respecting the purchased weekdays and Friday
exclusion. The existing menu rotation, eligibility, assignment and selection-audit
code revalidates future defaults. Invalid provisional customer choices remain saved
and flagged for review. Missing legacy schedule/quantity metadata requires review.

Pause state is stored separately from order approval/payment. It does not globally
block committed deliveries. The persisted service-day schedule is authoritative
after a pause, so backfilling cannot recreate pause gaps. Calendar/kitchen queries
exclude genuinely paused dates, retain committed/fulfilled records and use the
rescheduled dates. Kitchen report layout and configured category mapping are unchanged.
Only the affected package's customer calendar/menu cache is refreshed after changes.

### API and persistence

The current application bridges an order to its subscription service days; the
existing order ID is therefore used for these owned-customer endpoints:

- `GET /api/v1/orders/{id}/package-management`
- `GET /api/v1/orders/{id}/pauses`
- `POST /api/v1/orders/{id}/pause/preview`
- `POST /api/v1/orders/{id}/pause`
- `POST /api/v1/orders/{id}/resume`

Cancellation continues through the existing `POST /api/v1/orders/{id}/cancel`.
Preview takes `pauseStartDate`/`resumeDate`. Confirmation also takes `commandId`,
`expectedRowVersion`, the preview's `scheduleVersion` and an optional reason.
Resume takes `commandId`, `pauseId` and `expectedRowVersion`.

**Apply the migration before deploying the API.** New pause history is necessary
because no equivalent persistence existed. Use the EF migration
`20261102010000_SubscriptionPauses` or the transactional standalone script
`../diet-time-api/database/scripts/20261102_subscription_pauses.sql`.
It adds only `subscription_pauses`: order/subscription links, dates, accepted/resumed
state, reason, actor/timestamps, immutable requested resume date, schedule-change
audit JSON and a resume command ID. Existing tables/data are not rewritten by the
migration. Automatic destructive rollback is intentionally disallowed for audit history.

One upcoming/active pause is permitted per package. Resume means the first eligible
service date on or after the chosen resume date; committed dates remain scheduled.
Holiday/closure integration is deferred **as requested in this task**. No new
holiday configuration, payment processing, refund operation or Admin workflow was added.

### Modified files

Flutter (`diet-time-app`):

- `lib/features/checkout/data/orders_repository.dart`
- `lib/features/checkout/domain/order_models.dart`
- `lib/features/dashboard/domain/package_management.dart`
- `lib/features/dashboard/presentation/package_management_provider.dart`
- `lib/features/dashboard/presentation/package_management_panel.dart`
- `lib/features/dashboard/presentation/customer_dashboard_screen.dart`
- `lib/features/dashboard/presentation/order_details_screen.dart`
- `lib/features/dashboard/presentation/tomorrow_menu_section.dart`
- `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`
- Generated `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_ar.dart`
- `test/package_management_test.dart`
- `README.md`

ASP.NET Core/PostgreSQL (`../diet-time-api`):

- `src/Apis/DietTime.Meal.Api/Controllers/OrdersController.cs`
- `src/Apis/DietTime.Meal.Api/Program.cs`
- `src/BuildingBlocks/DietTime.Application/PackagePauseRules.cs`
- `src/BuildingBlocks/DietTime.Contracts/PackagePauseContracts.cs`
- `src/BuildingBlocks/DietTime.Domain/SubscriptionPause.cs`
- `src/BuildingBlocks/DietTime.Persistence/PackagePauseService.cs` — partial implementation of the existing `UpcomingMealService`.
- `src/BuildingBlocks/DietTime.Persistence/UpcomingMealService.cs`
- `src/BuildingBlocks/DietTime.Persistence/UpcomingMealConfigurations.cs`
- `src/BuildingBlocks/DietTime.Persistence/StaffOrderService.cs`
- `src/BuildingBlocks/DietTime.Persistence/OrderService.cs`
- `src/BuildingBlocks/DietTime.Persistence/AdminDeliveryCalendarService.cs`
- `src/BuildingBlocks/DietTime.Persistence/Migrations/20261102010000_SubscriptionPauses.cs`
- `database/scripts/20261102_subscription_pauses.sql`
- `tests/DietTime.UnitTests/PackagePauseRulesTests.cs`
- `tests/DietTime.Meal.Api.IntegrationTests/PackagePauseTests.cs`
- `tests/DietTime.Meal.Api.IntegrationTests/StaffOrderApprovalTests.cs`

### Executed validation

- **517 Flutter tests passed** across the full suite; the final **8 bilingual package tests** also passed after the Qatar picker refinement. Coverage includes blocked paid cancellation, retained order details, disabled dates, preview-only behavior, stable retry IDs, Resume Early and no-eligible-day messaging.
- **343 API unit tests passed**, including date/cutoff, committed-state, independent payment/approval and entitlement scheduling rules.
- **15 targeted integration checks passed, zero skipped**, against a separate temporary PostgreSQL 18 cluster with synthetic data. These cover actual HTTP preview/pause/replay/resume, authentication/ownership, confirmed-paid cancellation rejection without payment changes, unchanged eligible cancellation and Admin behavior, concurrency, rollback after an injected write failure, preserved IDs/fulfilled history, independent subscriptions, menu audit/uniqueness, kitchen/calendar exclusion and existing delivery/collection actions. The final **6 pause-specific PostgreSQL tests** passed again after entitlement validation refinements.
- The standalone migration was **applied twice** in a disposable PostgreSQL database; existing pause-history data was retained.
- Dart analysis reported **no issues**. API integration builds and app/API whitespace checks passed. Existing unrelated compiler warnings were not changed.

No existing database was modified during validation. Logs are in ignored
`artifacts/package-pause-*.log`. The temporary database cluster is shut down and
removed after verification. No unrelated customer or Admin workflows were changed;
real-device verification and deployment to the target environment remain outside
these local automated checks.

## Package restart-date update

Pause management is available from the existing order-details screen. Dashboard plan cards display Paused or Pause scheduled status, without pause-management controls.

Pausing selects a single restart date from the next eligible future date, up to six calendar months from the current Qatar date. This range can extend beyond the original package end. A preview shows the new end date, which the API calculates from the remaining purchased service days and package weekdays. Today's deliveries, delivered/collected days and committed meal selections are preserved.

Remove pause also opens a restart-date picker. Dates begin at the next eligible future date, respecting the existing 21:00 Qatar cutoff, and extend six months ahead. The app submits `resumeDate` to the existing resume endpoint; the API recalculates the package end automatically. An unavailable delivery weekday rolls forward to the next package weekday. The end date itself is never entered by the customer.

English and Arabic labels, schedule invalidation and command retry behavior are retained. Deploy the matching API changes before this app update. No database migration or SQL script is included.

Validation for this update: 34 Admin frontend tests, 44 Flutter tests, 62 backend unit tests and 20 API integration tests passed. The integration suite used a disposable local PostgreSQL 18 database with no skipped tests. Coverage includes actual future-date rejection, delivery/collection HTTP calls, single restart-date scheduling from tomorrow, six-month limits, pause/resume persistence, retries, entitlement preservation, authorization and existing preparation/PDF behavior. TypeScript, targeted ESLint, Flutter static analysis and the SPA production build passed. Existing compiler/Vite advisories remain. No existing application database was modified.
