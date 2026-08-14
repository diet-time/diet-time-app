import 'package:diet_time/features/checkout/domain/checkout_models.dart';

/// Account details returned by the authenticated customer-profile endpoint.
/// This is deliberately separate from the nutrition/onboarding profile.
class CustomerAccountProfile {
  const CustomerAccountProfile({
    required this.id,
    required this.fullName,
    required this.mobileNumber,
    this.dateOfBirth,
    this.gender,
    this.addresses = const [],
  });

  factory CustomerAccountProfile.fromJson(Map<String, dynamic> json) {
    final rawAddresses = json['addresses'] ?? json['deliveryAddresses'];
    return CustomerAccountProfile(
      id: _text(json['id'] ?? json['customerId'] ?? json['customerProfileId']),
      fullName: _text(
        json['fullName'] ?? json['preferredName'] ?? json['name'],
      ),
      mobileNumber: _text(
        json['mobileNumber'] ?? json['phoneNumber'] ?? json['mobile'],
      ),
      dateOfBirth: _date(json['dateOfBirth'] ?? json['dob']),
      gender: _nullableText(json['gender'] ?? json['genderCode']),
      addresses: rawAddresses is List
          ? List.unmodifiable(
              rawAddresses.whereType<Map>().map(
                (item) => CustomerDeliveryAddress.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              ),
            )
          : const [],
    );
  }

  final String id;
  final String fullName;
  final String mobileNumber;
  final DateTime? dateOfBirth;
  final String? gender;
  final List<CustomerDeliveryAddress> addresses;

  CustomerDeliveryAddress? get defaultAddress {
    if (addresses.isEmpty) return null;
    return addresses.firstWhere(
      (address) => address.isDefault,
      orElse: () => addresses.first,
    );
  }

  CustomerAccountProfile copyWith({
    String? fullName,
    DateTime? dateOfBirth,
    String? gender,
    List<CustomerDeliveryAddress>? addresses,
  }) => CustomerAccountProfile(
    id: id,
    fullName: fullName ?? this.fullName,
    mobileNumber: mobileNumber,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    gender: gender ?? this.gender,
    addresses: addresses ?? this.addresses,
  );
}

class UpdateCustomerProfileRequest {
  const UpdateCustomerProfileRequest({
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
  });

  final String fullName;
  final DateTime? dateOfBirth;
  final String? gender;

  Map<String, dynamic> toJson() => {
    'fullName': fullName.trim(),
    'dateOfBirth': dateOfBirth == null ? null : _apiDate(dateOfBirth!),
    'gender': gender,
  };
}

String _text(Object? value) => value?.toString().trim() ?? '';

String? _nullableText(Object? value) {
  final result = _text(value);
  return result.isEmpty ? null : result;
}

DateTime? _date(Object? value) => DateTime.tryParse(_text(value));

String _apiDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
