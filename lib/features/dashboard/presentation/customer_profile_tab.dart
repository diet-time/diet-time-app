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
    super.key,
  });

  final CustomerProfile profile;
  final String? phoneNumber;
  final CustomerDeliveryAddress? address;
  final VoidCallback onBack;
  final VoidCallback onEditAddress;
  final VoidCallback onEditProfile;

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
        const SizedBox(height: 29),
        const _SectionLabel('PERSONAL INFORMATION'),
        const SizedBox(height: 8),
        _ProfileCard(
          child: Column(
            children: [
              _InformationRow(
                icon: Icons.person_outline_rounded,
                label: 'Full Name',
                value: _name(profile.preferredName),
                onTap: onEditProfile,
              ),
              const _ThinDivider(),
              _InformationRow(
                icon: Icons.phone_iphone_rounded,
                label: 'Mobile Number',
                value: _value(phoneNumber),
                onTap: onEditProfile,
              ),
              const _ThinDivider(),
              _InformationRow(
                icon: Icons.calendar_month_outlined,
                label: 'Date of Birth',
                value: _birthDate(profile.dateOfBirth),
                onTap: onEditProfile,
              ),
              const _ThinDivider(),
              _InformationRow(
                icon: Icons.people_outline_rounded,
                label: 'Gender',
                value: _gender(profile.genderCode),
                onTap: onEditProfile,
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
      ],
    );
  }
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
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
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
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppColors.emeraldGreen,
          ),
        ],
      ),
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
            address!.streetLine,
            address!.area,
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

String _name(String? value) =>
    value?.trim().isNotEmpty == true ? value!.trim() : 'Customer';

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
