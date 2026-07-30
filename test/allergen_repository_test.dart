import 'package:diet_time/features/personalization/data/allergen_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('allergen URI includes the requested language', () {
    final uri = buildGuestAllergensUri(
      baseUrl: 'https://api.example.com',
      language: 'ar',
    );

    expect(
      uri.toString(),
      'https://api.example.com/api/v1/guest/allergens?language=ar',
    );
  });

  test('allergen model parses API fields', () {
    final allergen = GuestAllergen.fromJson(const {
      'id': 'allergen-1',
      'code': 'TREE_NUTS',
      'name': 'Tree nuts',
    });

    expect(allergen.id, 'allergen-1');
    expect(allergen.code, 'TREE_NUTS');
    expect(allergen.name, 'Tree nuts');
  });
}
