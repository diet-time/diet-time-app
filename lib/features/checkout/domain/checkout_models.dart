import 'package:diet_time/features/plans/domain/meal_plan_purchase_selection.dart';

enum DeliveryAddressType { home, apartment, office, other }

extension DeliveryAddressTypeValue on DeliveryAddressType {
  String get apiValue => name.toUpperCase();
  String get label => switch (this) {
    DeliveryAddressType.home => 'Home',
    DeliveryAddressType.apartment => 'Apartment',
    DeliveryAddressType.office => 'Office',
    DeliveryAddressType.other => 'Other',
  };

  static DeliveryAddressType from(Object? value) {
    final normalized = value?.toString().trim().toLowerCase();
    return DeliveryAddressType.values.firstWhere(
      (item) => item.name == normalized,
      orElse: () => DeliveryAddressType.other,
    );
  }
}

class CustomerDeliveryAddress {
  const CustomerDeliveryAddress({
    required this.id,
    required this.addressName,
    required this.addressType,
    required this.buildingNo,
    required this.streetNo,
    required this.zoneNo,
    required this.area,
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    this.unitNumber,
    this.directions,
    this.isDefault = false,
  });

  factory CustomerDeliveryAddress.fromJson(Map<String, dynamic> json) =>
      CustomerDeliveryAddress(
        id: _text(json['id'] ?? json['addressId']),
        addressName: _text(json['addressName'] ?? json['name']),
        addressType: DeliveryAddressTypeValue.from(json['addressType']),
        buildingNo: _text(json['buildingNo'] ?? json['buildingNumber']),
        streetNo: _text(json['streetNo'] ?? json['streetNumber']),
        unitNumber: _nullableText(json['unitNumber'] ?? json['unitNo']),
        zoneNo: _text(json['zoneNo'] ?? json['zoneNumber']),
        area: _text(json['area'] ?? json['city']),
        directions: _nullableText(json['directions']),
        latitude: _number(json['latitude']),
        longitude: _number(json['longitude']),
        formattedAddress: _text(
          json['formattedAddress'] ?? json['fullAddress'],
        ),
        isDefault: json['isDefault'] == true,
      );

  final String id;
  final String addressName;
  final DeliveryAddressType addressType;
  final String buildingNo;
  final String streetNo;
  final String? unitNumber;
  final String zoneNo;
  final String area;
  final String? directions;
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final bool isDefault;

  String get displayName =>
      addressName.trim().isEmpty ? addressType.label : addressName;
  String get streetLine =>
      'Building $buildingNo, Street $streetNo, Zone $zoneNo';

  Map<String, dynamic> toRequestJson() => {
    'addressName': displayName,
    'addressType': addressType.apiValue,
    'buildingNo': buildingNo.trim(),
    'streetNo': streetNo.trim(),
    'unitNumber': _nullableText(unitNumber),
    'zoneNo': zoneNo.trim(),
    'area': area.trim(),
    'directions': _nullableText(directions),
    'latitude': latitude,
    'longitude': longitude,
    'formattedAddress': formattedAddress.trim(),
    'isDefault': isDefault,
  };

  CustomerDeliveryAddress copyWith({String? id, bool? isDefault}) =>
      CustomerDeliveryAddress(
        id: id ?? this.id,
        addressName: addressName,
        addressType: addressType,
        buildingNo: buildingNo,
        streetNo: streetNo,
        unitNumber: unitNumber,
        zoneNo: zoneNo,
        area: area,
        directions: directions,
        latitude: latitude,
        longitude: longitude,
        formattedAddress: formattedAddress,
        isDefault: isDefault ?? this.isDefault,
      );
}

class DeliveryTimeSlot {
  const DeliveryTimeSlot({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
  });

  factory DeliveryTimeSlot.fromJson(Map<String, dynamic> json) =>
      DeliveryTimeSlot(
        id: _text(json['id'] ?? json['deliveryTimeSlotId']),
        name: _text(json['name'] ?? json['label'] ?? json['slotName']),
        startTime: _text(json['startTime'] ?? json['fromTime']),
        endTime: _text(json['endTime'] ?? json['toTime']),
      );

  final String id;
  final String name;
  final String startTime;
  final String endTime;

  String get timeRange => '$startTime - $endTime';
}

class CheckoutState {
  const CheckoutState({
    this.selection,
    this.schedule,
    this.customerProfileId,
    this.selectedAddressId,
    this.selectedAddress,
    this.selectedDeliveryTimeSlotId,
    this.selectedDeliveryTimeSlot,
    this.addresses = const [],
    this.deliveryTimeSlots = const [],
    this.isLoadingAddresses = false,
    this.isLoadingDeliveryTimeSlots = false,
    this.isSavingAddress = false,
    this.addressError,
    this.deliveryTimeSlotError,
    this.saveAddressError,
  });

  final MealPlanPurchaseSelection? selection;
  final MealPlanServiceSchedule? schedule;
  final String? customerProfileId;
  final String? selectedAddressId;
  final CustomerDeliveryAddress? selectedAddress;
  final String? selectedDeliveryTimeSlotId;
  final DeliveryTimeSlot? selectedDeliveryTimeSlot;
  final List<CustomerDeliveryAddress> addresses;
  final List<DeliveryTimeSlot> deliveryTimeSlots;
  final bool isLoadingAddresses;
  final bool isLoadingDeliveryTimeSlots;
  final bool isSavingAddress;
  final String? addressError;
  final String? deliveryTimeSlotError;
  final String? saveAddressError;

  bool get isReadyToContinue =>
      selectedAddressId != null && selectedDeliveryTimeSlotId != null;

  CheckoutState copyWith({
    MealPlanPurchaseSelection? selection,
    MealPlanServiceSchedule? schedule,
    Object? customerProfileId = _unset,
    Object? selectedAddressId = _unset,
    Object? selectedAddress = _unset,
    Object? selectedDeliveryTimeSlotId = _unset,
    Object? selectedDeliveryTimeSlot = _unset,
    List<CustomerDeliveryAddress>? addresses,
    List<DeliveryTimeSlot>? deliveryTimeSlots,
    bool? isLoadingAddresses,
    bool? isLoadingDeliveryTimeSlots,
    bool? isSavingAddress,
    Object? addressError = _unset,
    Object? deliveryTimeSlotError = _unset,
    Object? saveAddressError = _unset,
  }) => CheckoutState(
    selection: selection ?? this.selection,
    schedule: schedule ?? this.schedule,
    customerProfileId: identical(customerProfileId, _unset)
        ? this.customerProfileId
        : customerProfileId as String?,
    selectedAddressId: identical(selectedAddressId, _unset)
        ? this.selectedAddressId
        : selectedAddressId as String?,
    selectedAddress: identical(selectedAddress, _unset)
        ? this.selectedAddress
        : selectedAddress as CustomerDeliveryAddress?,
    selectedDeliveryTimeSlotId: identical(selectedDeliveryTimeSlotId, _unset)
        ? this.selectedDeliveryTimeSlotId
        : selectedDeliveryTimeSlotId as String?,
    selectedDeliveryTimeSlot: identical(selectedDeliveryTimeSlot, _unset)
        ? this.selectedDeliveryTimeSlot
        : selectedDeliveryTimeSlot as DeliveryTimeSlot?,
    addresses: addresses ?? this.addresses,
    deliveryTimeSlots: deliveryTimeSlots ?? this.deliveryTimeSlots,
    isLoadingAddresses: isLoadingAddresses ?? this.isLoadingAddresses,
    isLoadingDeliveryTimeSlots:
        isLoadingDeliveryTimeSlots ?? this.isLoadingDeliveryTimeSlots,
    isSavingAddress: isSavingAddress ?? this.isSavingAddress,
    addressError: identical(addressError, _unset)
        ? this.addressError
        : addressError as String?,
    deliveryTimeSlotError: identical(deliveryTimeSlotError, _unset)
        ? this.deliveryTimeSlotError
        : deliveryTimeSlotError as String?,
    saveAddressError: identical(saveAddressError, _unset)
        ? this.saveAddressError
        : saveAddressError as String?,
  );
}

const _unset = Object();

String _text(Object? value) => value?.toString().trim() ?? '';
String? _nullableText(Object? value) {
  final result = _text(value);
  return result.isEmpty ? null : result;
}

double _number(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
