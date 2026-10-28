import 'dart:convert';
import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/checkout/domain/address_validation.dart';
import 'package:diet_time/features/checkout/domain/checkout_models.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';
import 'package:diet_time/features/checkout/presentation/customer_address_screen.dart';
import 'package:diet_time/features/onboarding/presentation/onboarding_screen.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:diet_time/features/personalization/presentation/profile_persistence_controller.dart';
import 'package:diet_time/features/personalization/presentation/authenticated_landing_screen.dart';
import 'package:diet_time/features/personalization/presentation/questionnaire_deferral_controller.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class DraftStorage extends SecureStorageService {
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

class LocalProfileController extends ProfilePersistenceController {
  @override
  ProfilePersistenceState build() =>
      const ProfilePersistenceState(hasLoaded: true);
  @override
  Future<CustomerProfile?> load() async =>
      ref.read(personalizationControllerProvider);
}

class AddressFormController extends CheckoutController {
  CustomerDeliveryAddress? submitted;
  @override
  CheckoutState build() => const CheckoutState(
    customerProfileId: 'customer',
    deliveryTimeSlots: [
      DeliveryTimeSlot(
        id: 'slot',
        name: 'Morning',
        startTime: '07:00',
        endTime: '11:00',
      ),
    ],
    selectedDeliveryTimeSlotId: 'slot',
    selectedDeliveryTimeSlot: DeliveryTimeSlot(
      id: 'slot',
      name: 'Morning',
      startTime: '07:00',
      endTime: '11:00',
    ),
  );
  @override
  Future<void> loadAddresses() async {}
  @override
  Future<void> loadDeliveryTimeSlots() async {}
  @override
  Future<bool> saveAddress(
    CustomerDeliveryAddress address, {
    required bool editing,
  }) async {
    submitted = address;
    return false;
  }
}

void main() {
  test(
    'address fields accept numeric streets, identifiers, Arabic names and free directions',
    () {
      for (final value in ['126', 'A-126', '126/B', 'مبنى-١٢٦']) {
        expect(AddressValidation.building(value), isNull, reason: value);
      }
      expect(AddressValidation.street('960'), isNull);
      expect(AddressValidation.street('شارع ٩٦٠'), isNull);
      expect(AddressValidation.unit('B/12'), isNull);
      expect(AddressValidation.unit(''), isNull);
      for (final value in [
        ' Al Wakrah ',
        'الوكرة',
        'أمّ صلال',
        "Al-Dafna (West)",
      ]) {
        expect(AddressValidation.area(value), isNull, reason: value);
      }
      for (final value in ['Al Wakrah2', 'الوكرة٢', '   ', '---']) {
        expect(AddressValidation.area(value), isNotNull, reason: value);
      }
      expect(AddressValidation.zone('91'), isNull);
      expect(AddressValidation.zone('٩١'), isNull);
      expect(AddressValidation.zone('A91'), isNotNull);
      expect(
        AddressValidation.directions('Gate 3, call +974 12345678!'),
        isNull,
      );
    },
  );

  test(
    'zone formatter preserves complete numeric pastes and Arabic composition',
    () {
      const old = TextEditingValue(text: '91');
      expect(
        AddressValidation.zoneFormatter
            .formatEditUpdate(old, const TextEditingValue(text: '٩١'))
            .text,
        '٩١',
      );
      expect(
        AddressValidation.zoneFormatter
            .formatEditUpdate(old, const TextEditingValue(text: 'A-123'))
            .text,
        '91',
      );
    },
  );

  for (final session in ['guest', 'authenticated', 'expired']) {
    testWidgets(
      'Not now saves draft and routes $session without completing questionnaire',
      (tester) async {
        final storage = DraftStorage();
        if (session != 'guest') {
          storage.values.addAll({
            SecureStorageService.accessTokenKey: 'token',
            SecureStorageService.authenticatedUserIdKey: 'customer',
            SecureStorageService.accessTokenExpiresAtKey: DateTime.now()
                .toUtc()
                .add(Duration(hours: session == 'expired' ? -1 : 1))
                .toIso8601String(),
          });
        }
        final container = ProviderContainer(
          overrides: [
            secureStorageServiceProvider.overrideWithValue(storage),
            profilePersistenceControllerProvider.overrideWith(
              LocalProfileController.new,
            ),
          ],
        );
        addTearDown(container.dispose);
        container
            .read(personalizationControllerProvider.notifier)
            .replace(
              const CustomerProfile(
                goalCode: 'LOSE_WEIGHT',
                preferences: {'CHICKEN'},
                onboardingStatus: 'IN_PROGRESS',
              ),
            );
        PendingAuthDestination? pending;
        final router = GoRouter(
          initialLocation: AppRoutes.personalization,
          routes: [
            GoRoute(
              path: AppRoutes.personalization,
              builder: (_, _) => const PersonalizationScreen(),
            ),
            GoRoute(
              path: AppRoutes.phoneLogin,
              builder: (_, state) {
                pending = state.extra as PendingAuthDestination?;
                return const Scaffold(body: Text('Existing Login'));
              },
            ),
            GoRoute(
              path: AppRoutes.home,
              builder: (_, _) =>
                  const Scaffold(body: Text('Customer Dashboard')),
            ),
            GoRoute(
              path: AppRoutes.authenticatedLanding,
              builder: (_, _) => const AuthenticatedLandingScreen(),
            ),
            GoRoute(
              path: AppRoutes.plans,
              builder: (_, _) => const Scaffold(body: Text('Plans')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final skip = find.byKey(const ValueKey('personalizationNotNow'));
        await tester.ensureVisible(skip);
        await tester.tap(skip);
        await tester.pumpAndSettle();
        expect(
          find.text(
            session == 'authenticated'
                ? 'Customer Dashboard'
                : 'Existing Login',
          ),
          findsOneWidget,
        );
        if (session != 'authenticated') expect(pending?.route, AppRoutes.home);
        final key = session == 'guest'
            ? 'questionnaire.guest'
            : 'questionnaire.user.customer';
        final draft = jsonDecode(storage.values[key]!) as Map<String, dynamic>;
        expect(draft['goalCode'], 'LOSE_WEIGHT');
        expect(draft['preferences'], ['CHICKEN']);
        expect(draft['onboardingStatus'], 'IN_PROGRESS');
        expect(
          container.read(personalizationControllerProvider).isCompleted,
          false,
        );
        expect(
          container.read(personalizationControllerProvider).allergensConfirmed,
          false,
        );
        expect(container.read(questionnaireDeferralProvider), true);
        router.go(AppRoutes.authenticatedLanding);
        await tester.pumpAndSettle();
        expect(find.text('Customer Dashboard'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  test(
    'a previously authenticated session is rechecked after token expiry',
    () async {
      final storage = DraftStorage();
      storage.values.addAll({
        SecureStorageService.accessTokenKey: 'token',
        SecureStorageService.accessTokenExpiresAtKey: DateTime.now()
            .toUtc()
            .add(const Duration(hours: 1))
            .toIso8601String(),
      });
      final container = ProviderContainer(
        overrides: [secureStorageServiceProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);
      final auth = container.read(otpAuthControllerProvider.notifier);
      expect(await auth.restoreSession(), true);
      storage.values[SecureStorageService.accessTokenExpiresAtKey] =
          DateTime.now()
              .toUtc()
              .subtract(const Duration(hours: 1))
              .toIso8601String();
      expect(await auth.ensureCurrentSession(), false);
      expect(container.read(otpAuthControllerProvider).isAuthenticated, false);
    },
  );

  testWidgets(
    'address form uses field rules, numeric zone keyboard and preserves submitted values',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      const mapsChannel = MethodChannel(
        'com.diettime.diet_time/google_maps_configuration',
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        mapsChannel,
        (_) async => false,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          mapsChannel,
          null,
        ),
      );
      final controller = AddressFormController();
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            checkoutControllerProvider.overrideWith(() => controller),
          ],
          child: const MaterialApp(home: CustomerAddressScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Address'));
      await tester.pumpAndSettle();
      Finder field(String key) => find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(TextFormField),
      );
      await tester.tap(find.byKey(const ValueKey('addressType-home')));
      await tester.enterText(field('buildingNoField'), 'A-126/B');
      await tester.enterText(field('streetNoField'), '960');
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: field('zoneNoField'),
                matching: find.byType(EditableText),
              ),
            )
            .keyboardType,
        TextInputType.number,
      );
      await tester.enterText(field('zoneNoField'), '91');
      await tester.enterText(field('areaField'), 'Al Wakrah 2');
      expect(Form.of(tester.element(field('areaField'))).validate(), false);
      await tester.pump();
      expect(
        find.text(
          'Use English or Arabic letters and name punctuation; no digits.',
        ),
        findsOneWidget,
      );
      await tester.enterText(field('areaField'), '  الوكرة  ');
      expect(Form.of(tester.element(field('areaField'))).validate(), true);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('saveAddress')),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byKey(const ValueKey('saveAddress')));
      await tester.pumpAndSettle();
      expect(controller.submitted?.buildingNo, 'A-126/B');
      expect(controller.submitted?.streetNo, '960');
      expect(controller.submitted?.area, 'الوكرة');
      expect(controller.submitted?.unitNumber, isNull);
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
      await tester.pumpWidget(const SizedBox());
    },
  );
}
