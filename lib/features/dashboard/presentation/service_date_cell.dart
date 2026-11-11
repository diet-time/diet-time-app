import 'package:diet_time/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

IconData serviceStatusIcon(String? status) => switch (status) {
  'actionNeeded' => Icons.schedule_rounded,
  'confirmed' ||
  'delivered' ||
  'DELIVERED' ||
  'collected' ||
  'COLLECTED' => Icons.check_circle_outline,
  'selectedForYou' || 'auto_selected' => Icons.auto_awesome_outlined,
  'closed' || 'locked' => Icons.event_available_outlined,
  'mixed' => Icons.layers_outlined,
  _ => Icons.event_outlined,
};

class ServiceDateCell extends StatelessWidget {
  const ServiceDateCell({
    required this.date,
    required this.service,
    required this.selected,
    required this.count,
    required this.status,
    required this.label,
    required this.onTap,
    super.key,
  });
  final DateTime date;
  final bool service, selected;
  final int count;
  final String? status;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final action = status == 'actionNeeded';
    final accent = action ? const Color(0xFF895C25) : AppColors.emeraldGreen;
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      enabled: onTap != null,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFDFEEE0)
                  : action
                  ? const Color(0xFFFFF0D5)
                  : service
                  ? const Color(0xFFF0F5EB)
                  : const Color(0xFFF5F4EF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? AppColors.emeraldGreen : Colors.transparent,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: ValueKey('deliveryDate-${date.toIso8601String()}'),
                onTap: onTap,
                borderRadius: BorderRadius.circular(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${date.day}',
                          key: ValueKey('dateNumber-${date.toIso8601String()}'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: service || selected
                                ? AppColors.darkGreen
                                : const Color(0xFF8A928B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (service)
                      Icon(serviceStatusIcon(status), size: 12, color: accent)
                    else
                      const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
