import 'package:diet_time/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

IconData serviceStatusIcon(String? status) => switch (status) {
  'customized' => Icons.tune_rounded,
  'locked' => Icons.lock_outline_rounded,
  'delivered' => Icons.check_circle_outline,
  'mixed' => Icons.layers_outlined,
  'needs_review' => Icons.info_outline,
  'auto_selected' => Icons.auto_awesome_outlined,
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
  final bool service;
  final bool selected;
  final int count;
  final String? status;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    selected: selected,
    button: service,
    enabled: service,
    excludeSemantics: true,
    child: Tooltip(
      message: label,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: selected
              ? AppColors.darkGreen
              : service
              ? const Color(0xFFE7F1E4)
              : const Color(0xFFF1F0EA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: selected
                  ? AppColors.darkGreen
                  : service
                  ? const Color(0xFFB5CFB3)
                  : Colors.transparent,
            ),
          ),
          child: InkWell(
            key: ValueKey('deliveryDate-${date.toIso8601String()}'),
            onTap: service ? onTap : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: MediaQuery.textScalerOf(context).scale(18),
                    width: double.infinity,
                    key: ValueKey('dateNumber-${date.toIso8601String()}'),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${date.day}',
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: selected ? Colors.white : AppColors.darkGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (count > 0)
                    SizedBox(
                      width: double.infinity,
                      height: MediaQuery.textScalerOf(context).scale(12) + 4,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white
                                : AppColors.darkGreen,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '$count',
                            key: ValueKey(
                              'deliveryCount-${date.toIso8601String()}',
                            ),
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                              color: selected
                                  ? AppColors.darkGreen
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Icon(
                    service ? serviceStatusIcon(status) : Icons.remove,
                    size: 12,
                    color: selected ? Colors.white : const Color(0xFF52684D),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
