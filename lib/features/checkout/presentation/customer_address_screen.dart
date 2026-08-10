import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/widgets/app_button.dart';
import 'package:diet_time/features/checkout/domain/checkout_models.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CustomerAddressScreen extends ConsumerStatefulWidget {
  const CustomerAddressScreen({super.key});

  @override
  ConsumerState<CustomerAddressScreen> createState() =>
      _CustomerAddressScreenState();
}

class _CustomerAddressScreenState extends ConsumerState<CustomerAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _buildingController = TextEditingController();
  final _streetController = TextEditingController();
  final _unitController = TextEditingController();
  final _zoneController = TextEditingController();
  final _areaController = TextEditingController();
  final _directionsController = TextEditingController();

  bool _editingForm = false;
  CustomerDeliveryAddress? _addressBeingEdited;
  DeliveryAddressType? _addressType;
  double _latitude = 25.285447;
  double _longitude = 51.53104;
  String _formattedAddress = 'Doha, Qatar';
  String? _localError;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() async {
      final controller = ref.read(checkoutControllerProvider.notifier);
      await Future.wait([
        controller.loadAddresses(),
        controller.loadDeliveryTimeSlots(),
      ]);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _buildingController.dispose();
    _streetController.dispose();
    _unitController.dispose();
    _zoneController.dispose();
    _areaController.dispose();
    _directionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkout = ref.watch(checkoutControllerProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFE9EFE7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          key: const ValueKey('customerAddressBack'),
          onPressed: _editingForm && checkout.addresses.isNotEmpty
              ? () => setState(() => _editingForm = false)
              : () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          _editingForm ? 'Customer Address' : 'Delivery Address',
          style: const TextStyle(
            color: AppColors.darkGreen,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            bottom: MediaQuery.sizeOf(context).height * .38,
            child: _MapArea(
              searchController: _searchController,
              pin: LatLng(_latitude, _longitude),
              locationError: _locationError,
              onSearch: _search,
              onCurrentAddress: _useCurrentAddress,
              onMapTap: _movePin,
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: _editingForm ? .72 : .68,
            minChildSize: .56,
            maxChildSize: .94,
            snap: true,
            snapSizes: const [.68, .94],
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9F8F2),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkGreen.withValues(alpha: .14),
                    blurRadius: 28,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: _editingForm
                  ? _buildAddressForm(scrollController, checkout)
                  : _buildAddressSelector(scrollController, checkout),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSelector(
    ScrollController scrollController,
    CheckoutState checkout,
  ) {
    return ListView(
      key: const ValueKey('addressSelector'),
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      children: [
        const _SheetHandle(),
        const SizedBox(height: 18),
        const Text(
          'Choose Delivery Address',
          style: TextStyle(
            color: AppColors.darkGreen,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Select where you would like your meals delivered.',
          style: TextStyle(
            color: AppColors.darkGreen.withValues(alpha: .58),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 18),
        if (checkout.isLoadingAddresses)
          const _LoadingBlock(label: 'Loading saved addresses...')
        else if (checkout.addressError case final error?)
          _ErrorBlock(
            message: error,
            onRetry: () =>
                ref.read(checkoutControllerProvider.notifier).loadAddresses(),
          )
        else if (checkout.addresses.isEmpty)
          _EmptyAddresses(onAdd: _addAddress)
        else ...[
          for (final address in checkout.addresses) ...[
            _AddressCard(
              address: address,
              selected: address.id == checkout.selectedAddressId,
              onTap: () => ref
                  .read(checkoutControllerProvider.notifier)
                  .selectAddress(address),
              onEdit: () => _editAddress(address),
            ),
            const SizedBox(height: 10),
          ],
          OutlinedButton.icon(
            key: const ValueKey('addAnotherAddress'),
            onPressed: _addAddress,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Add Another Address'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.emeraldGreen,
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: AppColors.emeraldGreen),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        _TimeSlotSection(checkout: checkout),
        if (_localError case final error?) ...[
          const SizedBox(height: 12),
          _ErrorText(error),
        ],
        const SizedBox(height: 18),
        AppButton(
          key: const ValueKey('useDeliveryAddress'),
          label: 'Use This Address',
          onPressed: checkout.isLoadingAddresses ? null : _useAddress,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildAddressForm(
    ScrollController scrollController,
    CheckoutState checkout,
  ) {
    return Form(
      key: _formKey,
      child: ListView(
        key: const ValueKey('addressForm'),
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        children: [
          const _SheetHandle(),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Address Details',
                  style: TextStyle(
                    color: AppColors.darkGreen,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (checkout.addresses.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _editingForm = false),
                  child: const Text('Saved addresses'),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            _formattedAddress,
            key: const ValueKey('formattedMapAddress'),
            style: TextStyle(
              color: AppColors.darkGreen.withValues(alpha: .62),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 22),
          const _FieldLabel('SAVE AS *'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in DeliveryAddressType.values)
                ChoiceChip(
                  key: ValueKey('addressType-${type.name}'),
                  label: Text(type.label),
                  selected: _addressType == type,
                  onSelected: (_) => setState(() {
                    _addressType = type;
                    _localError = null;
                  }),
                  selectedColor: AppColors.emeraldGreen,
                  labelStyle: TextStyle(
                    color: _addressType == type
                        ? AppColors.white
                        : AppColors.darkGreen,
                    fontWeight: FontWeight.w700,
                  ),
                  side: BorderSide(
                    color: _addressType == type
                        ? AppColors.emeraldGreen
                        : AppColors.darkGreen.withValues(alpha: .14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _AddressField(
                  key: const ValueKey('buildingNoField'),
                  controller: _buildingController,
                  label: 'Building No *',
                  validator: _required('Building number'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AddressField(
                  key: const ValueKey('streetNoField'),
                  controller: _streetController,
                  label: 'Street *',
                  validator: _required('Street'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _AddressField(
                  controller: _unitController,
                  label: 'Unit Number',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AddressField(
                  key: const ValueKey('zoneNoField'),
                  controller: _zoneController,
                  label: 'Zone No *',
                  validator: _required('Zone number'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _AddressField(
            key: const ValueKey('areaField'),
            controller: _areaController,
            label: 'Area *',
            validator: _required('Area'),
          ),
          const SizedBox(height: 14),
          _AddressField(
            controller: _directionsController,
            label: 'Directions To Reach',
            hint: 'Call me when you arrive',
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          _TimeSlotSection(checkout: checkout),
          if (_localError case final error?) ...[
            const SizedBox(height: 12),
            _ErrorText(error),
          ],
          if (checkout.saveAddressError case final error?) ...[
            const SizedBox(height: 12),
            _ErrorText(error),
          ],
          const SizedBox(height: 18),
          AppButton(
            key: const ValueKey('saveAddress'),
            label: checkout.isSavingAddress
                ? 'Saving Address...'
                : 'Save Address',
            onPressed: checkout.isSavingAddress ? null : _saveAddress,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _addAddress() {
    _clearForm();
    setState(() {
      _editingForm = true;
      _addressBeingEdited = null;
      _addressType = null;
      _localError = null;
    });
  }

  void _editAddress(CustomerDeliveryAddress address) {
    _buildingController.text = address.buildingNo;
    _streetController.text = address.streetNo;
    _unitController.text = address.unitNumber ?? '';
    _zoneController.text = address.zoneNo;
    _areaController.text = address.area;
    _directionsController.text = address.directions ?? '';
    setState(() {
      _editingForm = true;
      _addressBeingEdited = address;
      _addressType = address.addressType;
      _latitude = address.latitude;
      _longitude = address.longitude;
      _formattedAddress = address.formattedAddress;
      _localError = null;
    });
  }

  void _clearForm() {
    _buildingController.clear();
    _streetController.clear();
    _unitController.clear();
    _zoneController.clear();
    _areaController.clear();
    _directionsController.clear();
    _formattedAddress = 'Pinned location, Qatar';
    _latitude = 25.285447;
    _longitude = 51.53104;
  }

  Future<void> _saveAddress() async {
    final valid = _formKey.currentState?.validate() ?? false;
    final checkout = ref.read(checkoutControllerProvider);
    if (!valid || _addressType == null) {
      setState(() {
        _localError = _addressType == null
            ? 'Select an address type before saving.'
            : 'Complete all required address fields.';
      });
      return;
    }
    if (checkout.selectedDeliveryTimeSlot == null) {
      setState(
        () => _localError = 'Select a delivery time slot before saving.',
      );
      return;
    }
    final previous = _addressBeingEdited;
    final address = CustomerDeliveryAddress(
      id: previous?.id ?? '',
      addressName: _addressType!.label,
      addressType: _addressType!,
      buildingNo: _buildingController.text,
      streetNo: _streetController.text,
      unitNumber: _unitController.text.trim().isEmpty
          ? null
          : _unitController.text.trim(),
      zoneNo: _zoneController.text,
      area: _areaController.text,
      directions: _directionsController.text.trim().isEmpty
          ? null
          : _directionsController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      formattedAddress: _formattedAddress,
      isDefault: previous?.isDefault ?? checkout.addresses.isEmpty,
    );
    final saved = await ref
        .read(checkoutControllerProvider.notifier)
        .saveAddress(address, editing: previous != null);
    if (saved && mounted) context.pop();
  }

  void _useAddress() {
    final checkout = ref.read(checkoutControllerProvider);
    final error = checkout.selectedAddress == null
        ? 'Select a delivery address or add a new one.'
        : checkout.selectedDeliveryTimeSlot == null
        ? 'Select a delivery time slot.'
        : null;
    setState(() => _localError = error);
    if (error == null) context.pop();
  }

  Future<void> _search(String value) async {
    final query = value.trim();
    if (query.isEmpty) {
      setState(() => _locationError = 'Enter a zone or area to search.');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _locationError = 'Searching for $query...');
    try {
      final results = await locationFromAddress('$query, Qatar');
      if (!mounted) return;
      if (results.isEmpty) {
        setState(() => _locationError = 'No matching location was found.');
        return;
      }
      if (_areaController.text.trim().isEmpty) _areaController.text = query;
      final result = results.first;
      await _movePin(LatLng(result.latitude, result.longitude));
    } catch (_) {
      if (mounted) {
        setState(
          () => _locationError =
              'Location search is unavailable. Try again or move the pin.',
        );
      }
    }
  }

  Future<void> _useCurrentAddress() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      setState(() => _locationError = 'Turn on location services to continue.');
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (!mounted) return;
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(
        () => _locationError = permission == LocationPermission.deniedForever
            ? 'Location access is blocked. Enable it in device settings.'
            : 'Location permission is needed to find your current address.',
      );
      return;
    }
    setState(() => _locationError = 'Finding your current location...');
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      await _movePin(LatLng(position.latitude, position.longitude));
    } catch (_) {
      if (mounted) {
        setState(
          () => _locationError =
              'Could not determine your location. Try again or move the pin.',
        );
      }
    }
  }

  Future<void> _movePin(LatLng position) async {
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
      _formattedAddress = 'Pinned location';
      _locationError = null;
    });
    try {
      final results = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (!mounted ||
          position.latitude != _latitude ||
          position.longitude != _longitude) {
        return;
      }
      final place = results.firstOrNull;
      if (place == null) return;
      final parts = <String?>[
        place.street,
        place.subLocality,
        place.locality,
        place.administrativeArea,
        place.country,
      ];
      final addressParts = parts
          .whereType<String>()
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toSet()
          .toList(growable: false);
      final area = (place.subLocality?.trim().isNotEmpty ?? false)
          ? place.subLocality!.trim()
          : place.locality?.trim();
      setState(() {
        _formattedAddress = addressParts.isEmpty
            ? 'Pinned location'
            : addressParts.join(', ');
        if (_areaController.text.trim().isEmpty && area != null) {
          _areaController.text = area;
        }
      });
    } catch (_) {
      // The coordinates remain valid when a device geocoder is unavailable.
    }
  }

  String? Function(String?) _required(String label) =>
      (value) => value?.trim().isEmpty ?? true ? '$label is required' : null;
}

class _MapArea extends StatefulWidget {
  const _MapArea({
    required this.searchController,
    required this.pin,
    required this.onSearch,
    required this.onCurrentAddress,
    required this.onMapTap,
    this.locationError,
  });

  final TextEditingController searchController;
  final LatLng pin;
  final ValueChanged<String> onSearch;
  final VoidCallback onCurrentAddress;
  final ValueChanged<LatLng> onMapTap;
  final String? locationError;

  @override
  State<_MapArea> createState() => _MapAreaState();
}

class _MapAreaState extends State<_MapArea> {
  static const _configurationChannel = MethodChannel(
    'com.diettime.diet_time/google_maps_configuration',
  );

  GoogleMapController? _controller;
  late final Future<bool> _mapsReady = _checkMapsConfiguration();

  Future<bool> _checkMapsConfiguration() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return true;
    try {
      return await _configurationChannel.invokeMethod<bool>('isConfigured') ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  void didUpdateWidget(covariant _MapArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pin != widget.pin) {
      _controller?.animateCamera(CameraUpdate.newLatLng(widget.pin));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: FutureBuilder<bool>(
          future: _mapsReady,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const ColoredBox(
                color: Color(0xFFE1E9DF),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.data != true) {
              return const _MapConfigurationError();
            }
            return GoogleMap(
              key: const ValueKey('googleMap'),
              initialCameraPosition: CameraPosition(
                target: widget.pin,
                zoom: 14.5,
              ),
              onMapCreated: (controller) => _controller = controller,
              onTap: widget.onMapTap,
              compassEnabled: true,
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: {
                Marker(
                  markerId: const MarkerId('deliveryLocation'),
                  position: widget.pin,
                  draggable: true,
                  onDragEnd: widget.onMapTap,
                ),
              },
            );
          },
        ),
      ),
      Positioned(
        left: 16,
        right: 16,
        top: 14,
        child: Column(
          children: [
            Material(
              elevation: 5,
              shadowColor: Colors.black12,
              borderRadius: BorderRadius.circular(15),
              child: TextField(
                key: const ValueKey('zoneSearch'),
                controller: widget.searchController,
                onSubmitted: widget.onSearch,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search a Zone',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        widget.onSearch(widget.searchController.text),
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            if (widget.locationError case final error?) ...[
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  error,
                  style: const TextStyle(
                    color: Color(0xFF9B351F),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      Positioned(
        right: 16,
        bottom: 20,
        child: FilledButton.icon(
          key: const ValueKey('currentAddress'),
          onPressed: widget.onCurrentAddress,
          icon: const Icon(Icons.my_location_rounded, size: 18),
          label: const Text('Current Address'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.emeraldGreen,
            elevation: 4,
          ),
        ),
      ),
    ],
  );
}

class _MapConfigurationError extends StatelessWidget {
  const _MapConfigurationError();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFE1E9DF),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.map_outlined,
              color: AppColors.darkGreen,
              size: 40,
            ),
            const SizedBox(height: 10),
            const Text(
              'Google Maps is not configured for this iOS build.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.darkGreen,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Add the iOS API key, then clean and rebuild the app.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.darkGreen.withValues(alpha: .65),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TimeSlotSection extends ConsumerWidget {
  const _TimeSlotSection({required this.checkout});
  final CheckoutState checkout;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _FieldLabel('DELIVERY TIME *'),
      const SizedBox(height: 9),
      if (checkout.isLoadingDeliveryTimeSlots)
        const _LoadingBlock(label: 'Loading delivery times...')
      else if (checkout.deliveryTimeSlotError case final error?)
        _ErrorBlock(
          message: error,
          onRetry: () => ref
              .read(checkoutControllerProvider.notifier)
              .loadDeliveryTimeSlots(),
        )
      else if (checkout.deliveryTimeSlots.isEmpty)
        const _ErrorText('No delivery time slots are currently available.')
      else
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            for (final slot in checkout.deliveryTimeSlots)
              ChoiceChip(
                key: ValueKey('deliveryTimeSlot-${slot.id}'),
                selected: slot.id == checkout.selectedDeliveryTimeSlotId,
                onSelected: (_) => ref
                    .read(checkoutControllerProvider.notifier)
                    .selectDeliveryTimeSlot(slot),
                selectedColor: AppColors.emeraldGreen,
                showCheckmark: false,
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(slot.name),
                      Text(
                        slot.timeRange,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                labelStyle: TextStyle(
                  color: slot.id == checkout.selectedDeliveryTimeSlotId
                      ? AppColors.white
                      : AppColors.darkGreen,
                  fontWeight: FontWeight.w800,
                ),
                side: BorderSide(
                  color: slot.id == checkout.selectedDeliveryTimeSlotId
                      ? AppColors.emeraldGreen
                      : AppColors.darkGreen.withValues(alpha: .14),
                ),
              ),
          ],
        ),
    ],
  );
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.selected,
    required this.onTap,
    required this.onEdit,
  });
  final CustomerDeliveryAddress address;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFFE7F4E8) : AppColors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(17),
      side: BorderSide(
        color: selected
            ? AppColors.emeraldGreen
            : AppColors.darkGreen.withValues(alpha: .1),
      ),
    ),
    child: InkWell(
      key: ValueKey('address-${address.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected
                    ? AppColors.emeraldGreen
                    : AppColors.darkGreen.withValues(alpha: .35),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.displayName,
                        style: const TextStyle(
                          color: AppColors.darkGreen,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'DEFAULT',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(address.area),
                  const SizedBox(height: 2),
                  Text(
                    address.streetLine,
                    style: TextStyle(
                      color: AppColors.darkGreen.withValues(alpha: .58),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              key: ValueKey('editAddress-${address.id}'),
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 19),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AddressField extends StatelessWidget {
  const _AddressField({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.validator,
    super.key,
  });
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.darkGreen.withValues(alpha: .1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.darkGreen.withValues(alpha: .1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.emeraldGreen, width: 1.5),
      ),
    ),
  );
}

class _EmptyAddresses extends StatelessWidget {
  const _EmptyAddresses({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.add_location_alt_outlined,
          size: 42,
          color: AppColors.emeraldGreen,
        ),
        const SizedBox(height: 10),
        const Text(
          'No saved addresses yet',
          style: TextStyle(
            color: AppColors.darkGreen,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Add an address for your meal deliveries.',
          style: TextStyle(
            color: AppColors.darkGreen.withValues(alpha: .58),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          key: const ValueKey('addFirstAddress'),
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Address'),
        ),
      ],
    ),
  );
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    height: 104,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(17),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 10),
        Text(label),
      ],
    ),
  );
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFECE8),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        Expanded(child: _ErrorText(message)),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Text(
    message,
    style: const TextStyle(
      color: Color(0xFF9B351F),
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.darkGreen.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(99),
      ),
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(
      color: AppColors.darkGreen.withValues(alpha: .64),
      fontSize: 11,
      letterSpacing: .7,
      fontWeight: FontWeight.w900,
    ),
  );
}
