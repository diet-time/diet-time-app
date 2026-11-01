import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/features/checkout/domain/address_validation.dart';
import 'package:diet_time/features/checkout/domain/delivery_city.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

extension DeliveryCityLabel on DeliveryCity {
  String label(AppLocalizations copy) => switch (this) {
    DeliveryCity.doha => copy.deliveryCityDoha,
    DeliveryCity.rayyan => copy.deliveryCityRayyan,
    DeliveryCity.umSalal => copy.deliveryCityUmSalal,
    DeliveryCity.wakrah => copy.deliveryCityWakrah,
    DeliveryCity.khour => copy.deliveryCityKhour,
    DeliveryCity.alDaayen => copy.deliveryCityAlDaayen,
    DeliveryCity.westBay => copy.deliveryCityWestBay,
    DeliveryCity.thePearl => copy.deliveryCityThePearl,
    DeliveryCity.lusail => copy.deliveryCityLusail,
    DeliveryCity.alSadd => copy.deliveryCityAlSadd,
    DeliveryCity.binMahmoud => copy.deliveryCityBinMahmoud,
    DeliveryCity.najma => copy.deliveryCityNajma,
    DeliveryCity.alMansoura => copy.deliveryCityAlMansoura,
    DeliveryCity.oldAirport => copy.deliveryCityOldAirport,
    DeliveryCity.alHilal => copy.deliveryCityAlHilal,
    DeliveryCity.abuHamour => copy.deliveryCityAbuHamour,
    DeliveryCity.ainKhaled => copy.deliveryCityAinKhaled,
    DeliveryCity.alWaab => copy.deliveryCityAlWaab,
    DeliveryCity.muaither => copy.deliveryCityMuaither,
    DeliveryCity.madinatKhalifa => copy.deliveryCityMadinatKhalifa,
    DeliveryCity.duhail => copy.deliveryCityDuhail,
    DeliveryCity.alGharrafa => copy.deliveryCityAlGharrafa,
    DeliveryCity.alThumama => copy.deliveryCityAlThumama,
    DeliveryCity.alDafna => copy.deliveryCityAlDafna,
    DeliveryCity.alKheesa => copy.deliveryCityAlKheesa,
    DeliveryCity.alWukair => copy.deliveryCityAlWukair,
    DeliveryCity.izghawa => copy.deliveryCityIzghawa,
    DeliveryCity.azizia => copy.deliveryCityAzizia,
    DeliveryCity.alMarkhiya => copy.deliveryCityAlMarkhiya,
    DeliveryCity.ummGhuwailina => copy.deliveryCityUmmGhuwailina,
    DeliveryCity.alMuntazah => copy.deliveryCityAlMuntazah,
    DeliveryCity.alNasr => copy.deliveryCityAlNasr,
  };
}

/// Shared by checkout and Profile through the existing address create/edit form.
class DeliveryCityDropdown extends StatefulWidget {
  const DeliveryCityDropdown({
    required this.controller,
    this.existingValue,
    this.serverError,
    this.onChanged,
    super.key,
  });
  final TextEditingController controller;
  final String? existingValue;
  final String? serverError;
  final ValueChanged<String>? onChanged;
  @override
  State<DeliveryCityDropdown> createState() => _DeliveryCityDropdownState();
}

class _DeliveryCityDropdownState extends State<DeliveryCityDropdown> {
  final _display = TextEditingController();
  final _focus = FocusNode();
  final _field = GlobalKey<FormFieldState<String>>();
  AppLocalizations get _copy =>
      lookupAppLocalizations(Localizations.localeOf(context));
  final _arabic = lookupAppLocalizations(const Locale('ar'));

  DeliveryCity? _city(String value) {
    final known = DeliveryCity.fromValue(value);
    if (known != null) return known;
    for (final city in DeliveryCity.values) {
      if (city.label(_arabic) == value.trim()) return city;
    }
    return null;
  }

  String _label(String value) =>
      _city(value)?.label(_copy) ??
      (value.trim() == widget.existingValue?.trim() ? value.trim() : '');

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    _focus.addListener(_restoreSelection);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _display.text = _label(widget.controller.text);
  }

  @override
  void didUpdateWidget(covariant DeliveryCityDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
      _field.currentState?.didChange(widget.controller.text);
    }
    if (oldWidget.controller != widget.controller ||
        oldWidget.existingValue != widget.existingValue) {
      _display.text = _label(widget.controller.text);
    }
  }

  void _changed() {
    _field.currentState?.didChange(widget.controller.text);
    _display.text = _label(widget.controller.text);
    setState(() {});
  }

  void _restoreSelection() {
    if (!_focus.hasFocus) _display.text = _label(widget.controller.text);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus.dispose();
    _display.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = [
      for (final city in DeliveryCity.values)
        DropdownMenuEntry(value: city.value, label: city.label(_copy)),
      if (widget.existingValue?.trim().isNotEmpty == true &&
          _city(widget.existingValue!) == null)
        DropdownMenuEntry(
          value: widget.existingValue!.trim(),
          label: widget.existingValue!.trim(),
        ),
    ]..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.darkGreen.withValues(alpha: .1)),
    );
    return FormField<String>(
      key: _field,
      initialValue: widget.controller.text,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (_) {
        final value = widget.controller.text.trim();
        if (value.isEmpty ||
            _city(value) == null && value != widget.existingValue?.trim()) {
          return _copy.deliveryCityRequired;
        }
        return AddressValidation.area(value);
      },
      builder: (field) => DropdownMenu<String>(
        key: const ValueKey('cityDropdown'),
        controller: _display,
        focusNode: _focus,
        expandedInsets: EdgeInsets.zero,
        menuHeight: 240,
        requestFocusOnTap: true,
        enableFilter: true,
        enableSearch: true,
        label: Text(_copy.deliveryCityLabel),
        hintText: _copy.deliveryCitySearch,
        errorText: widget.serverError ?? field.errorText,
        initialSelection:
            _city(widget.controller.text)?.value ??
            widget.existingValue?.trim(),
        dropdownMenuEntries: entries,
        filterCallback: (options, query) {
          final search = query.trim().toLowerCase();
          return options
              .where(
                (option) => [
                  option.label,
                  option.value,
                  _city(option.value)?.label(_arabic) ?? '',
                ].any((text) => text.toLowerCase().contains(search)),
              )
              .toList();
        },
        onSelected: (value) {
          if (value == null) return;
          widget.controller.text = value;
          widget.onChanged?.call(value);
          _focus.unfocus();
        },
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: const BorderSide(
              color: AppColors.emeraldGreen,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
