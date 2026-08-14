import 'package:diet_time/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class CustomerProfileTab extends StatelessWidget {
  const CustomerProfileTab({
    required this.onBack,
    required this.onEditAddress,
    required this.onEditProfile,
    required this.onQuestionnaire,
    this.onLogout,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback onEditAddress;
  final VoidCallback onEditProfile;
  final VoidCallback onQuestionnaire;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) => ListView(
    key: const ValueKey('customerProfile'),
    padding: const EdgeInsets.fromLTRB(15, 8, 15, 22),
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
        'Profile',
        style: TextStyle(
          color: AppColors.darkGreen,
          fontSize: 23,
          height: 1.1,
          fontWeight: FontWeight.w900,
          letterSpacing: -.45,
        ),
      ),
      const SizedBox(height: 18),
      _ProfileNavigationRow(
        key: const ValueKey('customerProfileOption'),
        icon: Icons.person_outline_rounded,
        label: 'Customer Profile',
        description: 'View or update your personal information',
        onTap: onEditProfile,
      ),
      const SizedBox(height: 9),
      _ProfileNavigationRow(
        key: const ValueKey('customerQuestionnaireOption'),
        icon: Icons.assignment_outlined,
        label: 'Questionnaire',
        description: 'Capture your goals and food preferences',
        onTap: onQuestionnaire,
      ),
      const SizedBox(height: 9),
      _ProfileNavigationRow(
        key: const ValueKey('customerAddressOption'),
        icon: Icons.location_on_outlined,
        label: 'Delivery Address',
        description: 'Add or edit your delivery address',
        onTap: onEditAddress,
      ),
      if (onLogout != null) ...[
        const SizedBox(height: 18),
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
  );
}

class _ProfileNavigationRow extends StatelessWidget {
  const _ProfileNavigationRow({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: Material(
      color: AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: BorderSide(color: AppColors.darkGreen.withValues(alpha: .08)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 14, 10, 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.emeraldGreen.withValues(alpha: .1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: AppColors.emeraldGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.darkGreen,
                        fontSize: 13,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: AppColors.darkGreen.withValues(alpha: .62),
                        fontSize: 11,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.emeraldGreen,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
