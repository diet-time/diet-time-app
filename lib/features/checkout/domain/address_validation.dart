import 'package:flutter/services.dart';

abstract final class AddressValidation {
  static final _identifier = RegExp(r'^[\p{L}\p{M}\p{Nd} /-]+$', unicode: true);
  static final _street = RegExp(
    r"^[\p{L}\p{M}\p{Nd} ./#,'’()\-]+$",
    unicode: true,
  );
  static final _area = RegExp(r"^[\p{L}\p{M} .,'’،()&\-]+$", unicode: true);
  static final _letter = RegExp(r'\p{L}', unicode: true);
  static final _letterOrDigit = RegExp(r'[\p{L}\p{Nd}]', unicode: true);
  static final _digits = RegExp(r'^\p{Nd}*$', unicode: true);

  static String? building(String? value) =>
      _validate(value, 'Building number', 50, _identifier, _letterOrDigit);
  static String? street(String? value) =>
      _validate(value, 'Street', 50, _street, _letterOrDigit);
  static String? unit(String? value) => (value?.trim().isEmpty ?? true)
      ? null
      : _validate(value, 'Unit number', 50, _identifier, _letterOrDigit);
  static String? area(String? value) => _validate(
    value,
    'Area',
    150,
    _area,
    _letter,
    invalid: 'Use English or Arabic letters and name punctuation; no digits.',
  );
  static String? zone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Zone number is required.';
    if (text.length > 50) return 'Use at most 50 characters.';
    return _digits.hasMatch(text)
        ? null
        : 'Zone number must contain digits only.';
  }

  static String? directions(String? value) =>
      (value?.trim().length ?? 0) > 500 ? 'Use at most 500 characters.' : null;

  static String? _validate(
    String? value,
    String label,
    int max,
    RegExp allowed,
    RegExp content, {
    String? invalid,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$label is required.';
    if (text.length > max) return 'Use at most $max characters.';
    return allowed.hasMatch(text) && content.hasMatch(text)
        ? null
        : invalid ?? 'Use letters, numbers and valid separators.';
  }

  // Accept complete pasted numbers, including Arabic digits, without stripping
  // characters out of a pasted identifier or interrupting IME composition.
  static final zoneFormatter = TextInputFormatter.withFunction(
    (oldValue, newValue) =>
        newValue.composing.isValid && !newValue.composing.isCollapsed ||
            _digits.hasMatch(newValue.text)
        ? newValue
        : oldValue,
  );
}
