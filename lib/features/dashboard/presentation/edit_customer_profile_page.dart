import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/features/dashboard/domain/customer_account_profile.dart';
import 'package:diet_time/features/dashboard/presentation/customer_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class EditCustomerProfilePage extends ConsumerStatefulWidget {
  const EditCustomerProfilePage({this.profile, super.key});

  final CustomerAccountProfile? profile;

  @override
  ConsumerState<EditCustomerProfilePage> createState() =>
      _EditCustomerProfilePageState();
}

class _EditCustomerProfilePageState
    extends ConsumerState<EditCustomerProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _dateController;
  late final CustomerAccountProfile? _initialProfile;
  DateTime? _dateOfBirth;
  String? _gender;
  bool _allowPop = false;

  static const _genderOptions = <String>['MALE', 'FEMALE'];

  @override
  void initState() {
    super.initState();
    _initialProfile =
        widget.profile ?? ref.read(customerProfileControllerProvider).profile;
    _nameController = TextEditingController(
      text: _initialProfile?.fullName ?? '',
    )..addListener(_fieldChanged);
    _dateOfBirth = _initialProfile?.dateOfBirth;
    _dateController = TextEditingController(
      text: _dateOfBirth == null
          ? ''
          : DateFormat('dd MMM yyyy').format(_dateOfBirth!),
    );
    _gender = _normalizeGender(_initialProfile?.gender);
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_fieldChanged)
      ..dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _fieldChanged() => setState(() {});

  bool get _hasChanges {
    final initial = _initialProfile;
    if (initial == null) return false;
    return _nameController.text.trim() != initial.fullName.trim() ||
        !_sameDate(_dateOfBirth, initial.dateOfBirth) ||
        _gender != _normalizeGender(initial.gender);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerProfileControllerProvider);
    final profile = _initialProfile;
    if (profile == null) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: Text('Unable to load your profile.')),
        ),
      );
    }
    return PopScope(
      canPop: _allowPop || !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6EF),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F6EF),
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            key: const ValueKey('editProfileBack'),
            onPressed: _handleBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text(
            'Edit Profile',
            style: TextStyle(
              color: AppColors.darkGreen,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              children: [
                TextFormField(
                  key: const ValueKey('profileFullName'),
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 150,
                  validator: (value) {
                    final name = value?.trim() ?? '';
                    if (name.isEmpty) return 'Full Name is required.';
                    if (name.length < 2) {
                      return 'Full Name must be at least 2 characters.';
                    }
                    if (name.length > 150) {
                      return 'Full Name must be 150 characters or fewer.';
                    }
                    return state.fieldErrors['fullName'];
                  },
                  decoration: _decoration('Full Name'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const ValueKey('profileMobileNumber'),
                  initialValue: profile.mobileNumber,
                  readOnly: true,
                  decoration: _decoration('Mobile Number').copyWith(
                    helperText:
                        'Contact support or use Change Mobile Number to update your login number.',
                    suffixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      size: 19,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const ValueKey('profileDateOfBirth'),
                  readOnly: true,
                  onTap: _pickDate,
                  validator: (_) => state.fieldErrors['dateOfBirth'],
                  controller: _dateController,
                  decoration: _decoration('Date of Birth').copyWith(
                    suffixIcon: const Icon(Icons.calendar_month_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  key: const ValueKey('profileGender'),
                  initialValue: _genderOptions.contains(_gender)
                      ? _gender
                      : null,
                  items: [
                    for (final value in _genderOptions)
                      DropdownMenuItem(
                        value: value,
                        child: Text(_genderLabel(value)),
                      ),
                  ],
                  onChanged: state.isSaving
                      ? null
                      : (value) => setState(() => _gender = value),
                  validator: (_) => state.fieldErrors['gender'],
                  decoration: _decoration('Gender'),
                ),
                if (state.saveError case final error?) ...[
                  const SizedBox(height: 14),
                  Text(
                    error,
                    key: const ValueKey('profileSaveError'),
                    style: const TextStyle(
                      color: Color(0xFF9B351F),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    key: const ValueKey('saveProfileChanges'),
                    onPressed: state.isSaving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.darkGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: state.isSaving
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text('Saving...'),
                            ],
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: AppColors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: BorderSide(color: AppColors.darkGreen.withValues(alpha: .12)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: AppColors.emeraldGreen, width: 1.5),
    ),
  );

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (selected != null && mounted) {
      setState(() {
        _dateOfBirth = selected;
        _dateController.text = DateFormat('dd MMM yyyy').format(selected);
      });
    }
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await ref
        .read(customerProfileControllerProvider.notifier)
        .save(
          UpdateCustomerProfileRequest(
            fullName: _nameController.text.trim(),
            dateOfBirth: _dateOfBirth,
            gender: _gender,
          ),
        );
    if (success && mounted) {
      _allowPop = true;
      context.pop(true);
    } else if (mounted) {
      _formKey.currentState?.validate();
    }
  }

  Future<void> _handleBack() async {
    if (!_hasChanges) {
      context.pop();
      return;
    }
    await _confirmDiscard();
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to leave?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      setState(() => _allowPop = true);
      context.pop();
    }
  }
}

String? _normalizeGender(String? value) {
  final normalized = value?.trim().toUpperCase();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

String _genderLabel(String value) =>
    '${value[0]}${value.substring(1).toLowerCase()}';

bool _sameDate(DateTime? left, DateTime? right) =>
    left == null && right == null ||
    left != null &&
        right != null &&
        left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
