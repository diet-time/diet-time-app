import 'package:diet_time/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Uses the same numeric domain for category segments, ticks and the value marker.
class BmiOverview extends StatelessWidget {
  const BmiOverview({
    required this.bmi,
    required this.age,
    required this.category,
    super.key,
  });
  final double? bmi;
  final int? age;
  final String category;
  static double position(double value) => ((value - 14) / 26).clamp(0.0, 1.0);
  @override
  Widget build(BuildContext context) {
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final valid = bmi != null && bmi!.isFinite && bmi! > 0;
    final adult = age != null && age! >= 18;
    final text = Theme.of(context).textTheme;
    return Container(
      key: const ValueKey('bmiRange'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE6DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            arabic ? 'مؤشر كتلة الجسم' : 'Your BMI',
            style: text.labelLarge?.copyWith(color: AppColors.darkGreen),
          ),
          const SizedBox(height: 6),
          Text(
            valid
                ? bmi!.toStringAsFixed(1)
                : (arabic ? 'غير متاح بعد' : 'Not available yet'),
            key: const ValueKey('bmiValue'),
            style: text.headlineMedium?.copyWith(
              color: AppColors.darkGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (valid && adult) ...[
            Text(
              category,
              style: const TextStyle(
                color: AppColors.darkGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Directionality(
              textDirection: TextDirection.ltr,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth - 24;
                  final x = 12 + position(bmi!) * width;
                  return Semantics(
                    label: 'BMI ${bmi!.toStringAsFixed(1)}, $category',
                    child: SizedBox(
                      height: 66,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 12,
                            right: 12,
                            top: 14,
                            height: 14,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 45,
                                    child: ColoredBox(
                                      color: Color(0xFF4C879D),
                                      child: SizedBox.expand(),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 65,
                                    child: ColoredBox(
                                      color: Color(0xFF2E7B5D),
                                      child: SizedBox.expand(),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 50,
                                    child: ColoredBox(
                                      color: Color(0xFFB9822D),
                                      child: SizedBox.expand(),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 100,
                                    child: ColoredBox(
                                      color: Color(0xFFA76746),
                                      child: SizedBox.expand(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: x - 11,
                            top: 10,
                            child: Container(
                              key: const ValueKey('bmiScaleMarker'),
                              child: Container(
                                key: const ValueKey('bmiScaleIndicatorDot'),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.darkGreen,
                                    width: 3,
                                  ),
                                ),
                                child: Icon(
                                  bmi! < 14
                                      ? Icons.arrow_left
                                      : bmi! > 40
                                      ? Icons.arrow_right
                                      : Icons.circle,
                                  size: 12,
                                  color: AppColors.darkGreen,
                                ),
                              ),
                            ),
                          ),
                          for (final tick in [14.0, 18.5, 25.0, 30.0, 40.0])
                            Positioned(
                              left: (12 + position(tick) * width - 16).clamp(
                                0.0,
                                constraints.maxWidth - 32,
                              ),
                              top: 38,
                              width: 32,
                              child: Text(
                                tick == 18.5 ? '18.5' : tick.toInt().toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.darkGreen,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Wrap(
              spacing: 16,
              runSpacing: 10,
              children: [
                _Category(
                  color: const Color(0xFF4C879D),
                  label: arabic ? 'أقل من النطاق' : 'Below range',
                  range: '<18.5',
                ),
                _Category(
                  color: const Color(0xFF2E7B5D),
                  label: arabic ? 'ضمن النطاق' : 'Within range',
                  range: '18.5–<25',
                ),
                _Category(
                  color: const Color(0xFFB9822D),
                  label: arabic ? 'أعلى من النطاق' : 'Above range',
                  range: '25–<30',
                ),
                _Category(
                  color: const Color(0xFFA76746),
                  label: arabic ? 'أعلى بكثير' : 'Well above range',
                  range: '≥30',
                ),
              ],
            ),
            if (bmi! < 14 || bmi! > 40)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  arabic
                      ? 'القيمة خارج حدود المقياس المعروض'
                      : 'Your value is outside the displayed 14–40 scale.',
                ),
              ),
          ] else if (valid) ...[
            const SizedBox(height: 8),
            Text(
              age == null
                  ? (arabic
                        ? 'أضف تاريخ ميلادك لتفسير المؤشر.'
                        : 'Add your date of birth to interpret BMI.')
                  : (arabic
                        ? 'يحتاج مؤشر الأطفال والمراهقين إلى تقييم حسب العمر والجنس. لا تنطبق نطاقات البالغين.'
                        : 'Children and teenagers need an age- and sex-specific assessment. Adult ranges do not apply.'),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            arabic
                ? 'مؤشر للفحص الأولي وليس تشخيصاً طبياً.'
                : 'A screening indicator, not a medical diagnosis.',
            style: text.bodySmall?.copyWith(color: AppColors.darkGreen),
          ),
        ],
      ),
    );
  }
}

class _Category extends StatelessWidget {
  const _Category({
    required this.color,
    required this.label,
    required this.range,
  });
  final Color color;
  final String label;
  final String range;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          '$label ($range)',
          style: const TextStyle(fontSize: 12, color: AppColors.darkGreen),
        ),
      ),
    ],
  );
}
