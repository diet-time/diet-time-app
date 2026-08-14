import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/features/checkout/domain/checkout_models.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomerProfileTab extends StatelessWidget {
  const CustomerProfileTab({
    required this.profile,
    required this.phoneNumber,
    required this.address,
    required this.onBack,
    required this.onEditAddress,
    required this.onEditProfile,
    this.onQuestionnaire,
    this.onLogout,
    this.onRetry,
    this.isLoading = false,
    this.errorMessage,
    super.key,
  });

  final CustomerProfile profile;
  final String? phoneNumber;
  final CustomerDeliveryAddress? address;
  final VoidCallback onBack;
  final VoidCallback onEditAddress;
  final VoidCallback onEditProfile;
  final VoidCallback? onQuestionnaire;
  final VoidCallback? onLogout;
  final VoidCallback? onRetry;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('customerProfile'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: IconButton(
            key: const ValueKey('profileBackButton'),
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            visualDensity: VisualDensity.compact,
            color: AppColors.darkGreen,
            icon: const Icon(Icons.arrow_back_rounded, size: 22),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Customer Profile',
          style: TextStyle(
            color: AppColors.darkGreen,
            fontSize: 23,
            height: 1.1,
            fontWeight: FontWeight.w900,
            letterSpacing: -.45,
          ),
        ),
        if (onQuestionnaire != null) ...[
          const SizedBox(height: 18),
          _ProfileAreaSelector(onQuestionnaire: onQuestionnaire!),
        ],
        const SizedBox(height: 24),
        if (isLoading) ...[const _ProfileSkeleton()],
        if (errorMessage case final message?) ...[
          _ProfileError(message: message, onRetry: onRetry),
        ],
        if (!isLoading && errorMessage == null) ...[
          const _SectionLabel('PERSONAL INFORMATION'),
          const SizedBox(height: 8),
          _ProfileCard(
            child: Column(
              children: [
                _InformationRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Full Name',
                  value: _name(profile.preferredName),
                ),
                const _ThinDivider(),
                _InformationRow(
                  icon: Icons.phone_iphone_rounded,
                  label: 'Mobile Number',
                  value: _value(phoneNumber),
                ),
                const _ThinDivider(),
                _InformationRow(
                  icon: Icons.calendar_month_outlined,
                  label: 'Date of Birth',
                  value: _birthDate(profile.dateOfBirth),
                ),
                const _ThinDivider(),
                _InformationRow(
                  icon: Icons.people_outline_rounded,
                  label: 'Gender',
                  value: _gender(profile.genderCode),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('DELIVERY ADDRESS'),
          const SizedBox(height: 8),
          _ProfileCard(
            child: Column(
              children: [
                _AddressBlock(address: address),
                const _ThinDivider(),
                InkWell(
                  key: const ValueKey('editProfileAddress'),
                  onTap: onEditAddress,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(14),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(17, 13, 10, 13),
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          size: 17,
                          color: AppColors.emeraldGreen,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Edit Address',
                            style: TextStyle(
                              color: AppColors.darkGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppColors.emeraldGreen,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          SizedBox(
            height: 47,
            child: FilledButton.icon(
              key: const ValueKey('editCustomerProfile'),
              onPressed: onEditProfile,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF004D3B),
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              icon: const Icon(Icons.edit_rounded, size: 17),
              label: const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          if (onLogout != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              key: const ValueKey('logoutCustomer'),
              onPressed: onLogout,
              style: TextButton.styleFrom(foregroundColor: AppColors.darkGreen),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _ProfileAreaSelector extends StatelessWidget {
  const _ProfileAreaSelector({required this.onQuestionnaire});

  final VoidCallback onQuestionnaire;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.darkGreen.withValues(alpha: .055),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      children: [
        const Expanded(
          child: _ProfileAreaOption(
            key: ValueKey('customerProfileOption'),
            icon: Icons.person_outline_rounded,
            label: 'Customer Profile',
            selected: true,
          ),
        ),
        Expanded(
          child: _ProfileAreaOption(
            key: const ValueKey('customerQuestionnaireOption'),
            icon: Icons.assignment_outlined,
            label: 'Questionnaire',
            selected: false,
            onTap: onQuestionnaire,
          ),
        ),
      ],
    ),
  );
}

class _ProfileAreaOption extends StatelessWidget {
  const _ProfileAreaOption({
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected ? AppColors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected
                    ? AppColors.emeraldGreen
                    : AppColors.darkGreen.withValues(alpha: .65),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.darkGreen,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
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

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.darkGreen.withValues(alpha: .035)),
      boxShadow: [
        BoxShadow(
          color: AppColors.darkGreen.withValues(alpha: .055),
          blurRadius: 22,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: child,
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.emeraldGreen,
      fontSize: 10,
      fontWeight: FontWeight.w900,
      letterSpacing: .15,
    ),
  );
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 11, 9, 11),
    child: Row(
      children: [
        _RoundIcon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.darkGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.darkGreen.withValues(alpha: .63),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AddressBlock extends StatelessWidget {
  const _AddressBlock({required this.address});

  final CustomerDeliveryAddress? address;

  @override
  Widget build(BuildContext context) {
    final lines = address == null
        ? const ['No saved delivery address']
        : [
            if (address!.unitNumber?.trim().isNotEmpty == true)
              'Unit ${address!.unitNumber}',
            if (address!.buildingNo.trim().isNotEmpty)
              'Building ${address!.buildingNo}',
            if (address!.streetNo.trim().isNotEmpty)
              'Street ${address!.streetNo}',
            if (address!.zoneNo.trim().isNotEmpty) 'Zone ${address!.zoneNo}',
            if (address!.area.trim().isNotEmpty) 'Area ${address!.area}',
            if (address!.formattedAddress.trim().isNotEmpty &&
                address!.formattedAddress.trim() != address!.area.trim())
              address!.formattedAddress,
          ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _RoundIcon(Icons.location_on_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        address?.displayName ?? 'Delivery Address',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (address?.isDefault == true) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldGreen.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          'Default ✓',
                          style: TextStyle(
                            color: AppColors.emeraldGreen,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      line,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.darkGreen.withValues(alpha: .58),
                        fontSize: 9,
                        height: 1.35,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 31,
    height: 31,
    decoration: BoxDecoration(
      color: AppColors.emeraldGreen.withValues(alpha: .095),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, size: 17, color: AppColors.emeraldGreen),
  );
}

class _ThinDivider extends StatelessWidget {
  const _ThinDivider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: 15,
    endIndent: 15,
    color: AppColors.darkGreen.withValues(alpha: .075),
  );
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('profileLoading'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _SectionLabel('PERSONAL INFORMATION'),
      const SizedBox(height: 8),
      _ProfileCard(
        child: Column(
          children: [
            for (var index = 0; index < 4; index++) ...[
              const Padding(
                padding: EdgeInsets.all(15),
                child: Row(
                  children: [
                    _SkeletonBox(width: 31, height: 31, round: true),
                    SizedBox(width: 12),
                    Expanded(child: _SkeletonBox(height: 25)),
                  ],
                ),
              ),
              if (index != 3) const _ThinDivider(),
            ],
          ],
        ),
      ),
      const SizedBox(height: 24),
      const _SectionLabel('DELIVERY ADDRESS'),
      const SizedBox(height: 8),
      const _ProfileCard(
        child: Padding(
          padding: EdgeInsets.all(15),
          child: _SkeletonBox(height: 105),
        ),
      ),
    ],
  );
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({this.width, required this.height, this.round = false});

  final double? width;
  final double height;
  final bool round;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: AppColors.darkGreen.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(round ? 99 : 7),
    ),
  );
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => _ProfileCard(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.emeraldGreen),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

String _name(String? value) =>
    value?.trim().isNotEmpty == true ? value!.trim() : 'Not provided';

String _value(String? value) =>
    value?.trim().isNotEmpty == true ? value!.trim() : 'Not provided';

String _birthDate(String? value) {
  final date = DateTime.tryParse(value ?? '');
  return date == null ? 'Not provided' : DateFormat('dd MMM yyyy').format(date);
}

String _gender(String? value) {
  final normalized = value?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) return 'Not provided';
  return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
}
