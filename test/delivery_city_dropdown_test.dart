import 'package:diet_time/features/checkout/domain/checkout_models.dart';
import 'package:diet_time/features/checkout/domain/delivery_city.dart';
import 'package:diet_time/features/checkout/presentation/delivery_city_dropdown.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog contains exactly the 32 requested unique locations', () {
    final expected =
        'Doha, Rayyan, Um Salal, Wakrah, Khour, AL Daayen, West Bay, The Pearl, Lusail, Al Sadd, Bin Mahmoud, Najma, Al Mansoura, Old Airport, Al Hilal, Abu Hamour, Ain Khaled, Al Waab, Muaither, Madinat Khalifa, Duhail, Al Gharrafa, Al Thumama, Al Dafna, Al Kheesa, Al Wukair, Izghawa, Azizia, Al Markhiya, Umm Ghuwailina, Al Muntazah, Al Nasr'
            .split(', ');
    expect(
      DeliveryCity.values.map((city) => city.value),
      unorderedEquals(expected),
    );
    expect(
      DeliveryCity.values.map((city) => city.value.toLowerCase()).toSet(),
      hasLength(32),
    );
  });

  for (final language in ['en', 'ar']) {
    testWidgets(
      'locations have translated, alphabetically sorted, unique labels: $language',
      (tester) async {
        final controller = TextEditingController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(_app(controller, language: language));
        final entries = tester
            .widget<DropdownMenu<String>>(
              find.byKey(const ValueKey('cityDropdown')),
            )
            .dropdownMenuEntries;
        final labels = entries.map((entry) => entry.label).toList();
        final sorted = [...labels]
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        expect(labels, sorted);
        expect(labels.toSet(), hasLength(32));
        expect(entries.map((entry) => entry.value).toSet(), hasLength(32));
        expect(
          labels,
          contains(lookupAppLocalizations(Locale(language)).deliveryCityDoha),
        );
      },
    );

    for (final query in ['Lus', 'لوسيل']) {
      testWidgets(
        'search in either language selects one stable API value: $language / $query',
        (tester) async {
          final controller = TextEditingController();
          addTearDown(controller.dispose);
          await tester.pumpWidget(_app(controller, language: language));
          await tester.tap(_input);
          await tester.enterText(_input, query);
          await tester.pumpAndSettle();
          final label = lookupAppLocalizations(
            Locale(language),
          ).deliveryCityLusail;
          await tester.tap(find.widgetWithText(MenuItemButton, label));
          await tester.pumpAndSettle();
          expect(controller.text, 'Lusail');
          expect(tester.widget<TextField>(_input).controller!.text, label);
          expect(Form.of(tester.element(_input)).validate(), isTrue);
          // A second choice replaces the previous city rather than accumulating it.
          await tester.tap(_input);
          await tester.enterText(_input, 'Doha');
          await tester.pumpAndSettle();
          await tester.tap(
            find.widgetWithText(
              MenuItemButton,
              lookupAppLocalizations(Locale(language)).deliveryCityDoha,
            ),
          );
          await tester.pumpAndSettle();
          expect(controller.text, 'Doha');
        },
      );
    }
  }

  testWidgets('search text cannot be saved as a new city without selection', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    await tester.tap(_input);
    await tester.enterText(_input, 'Unlisted location 123');
    await tester.pump();
    expect(controller.text, isEmpty);
    expect(Form.of(tester.element(_input)).validate(), isFalse);
  });

  for (final saved in ['Al Wakrah', 'الوكرة', 'Legacy District']) {
    testWidgets(
      'editing preserves an existing location and does not add duplicate options: $saved',
      (tester) async {
        final controller = TextEditingController(text: saved);
        addTearDown(controller.dispose);
        await tester.pumpWidget(_app(controller, existingValue: saved));
        expect(controller.text, saved);
        expect(Form.of(tester.element(_input)).validate(), isTrue);
        final entries = tester
            .widget<DropdownMenu<String>>(
              find.byKey(const ValueKey('cityDropdown')),
            )
            .dropdownMenuEntries;
        expect(
          entries.map((entry) => entry.value.toLowerCase()).toSet().length,
          entries.length,
        );
        expect(entries, hasLength(saved == 'Legacy District' ? 33 : 32));
        await tester.pumpWidget(
          _app(controller, language: 'ar', existingValue: saved),
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(_input).controller!.text,
          saved == 'Legacy District'
              ? saved
              : lookupAppLocalizations(const Locale('ar')).deliveryCityWakrah,
        );
        expect(controller.text, saved);
        final address = CustomerDeliveryAddress.fromJson({
          'id': 'existing',
          'city': controller.text,
        });
        expect(address.area, saved);
        expect(address.toRequestJson()['area'], saved);
      },
    );
  }

  testWidgets(
    'a map-derived unlisted location cannot become a new dropdown option',
    (tester) async {
      final controller = TextEditingController(text: 'Unlisted map district');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(controller));
      expect(Form.of(tester.element(_input)).validate(), isFalse);
      final entries = tester
          .widget<DropdownMenu<String>>(
            find.byKey(const ValueKey('cityDropdown')),
          )
          .dropdownMenuEntries;
      expect(entries, hasLength(32));
    },
  );

  testWidgets('parent refresh preserves an active city search', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    await tester.tap(_input);
    await tester.enterText(_input, 'Lus');
    await tester.pumpWidget(_app(controller));
    await tester.pump();
    expect(tester.widget<TextField>(_input).controller!.text, 'Lus');
  });
}

Finder get _input => find.descendant(
  of: find.byKey(const ValueKey('cityDropdown')),
  matching: find.byType(TextField),
);

Widget _app(
  TextEditingController controller, {
  String language = 'en',
  String? existingValue,
}) => MaterialApp(
  locale: Locale(language),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        child: DeliveryCityDropdown(
          controller: controller,
          existingValue: existingValue,
        ),
      ),
    ),
  ),
);
