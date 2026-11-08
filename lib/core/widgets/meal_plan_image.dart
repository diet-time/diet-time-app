import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/config/app_environment.dart';
import 'package:diet_time/core/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:diet_time/core/performance/performance_trace.dart';

/// Same API-relative URL convention as the plan selection and pricing screens.
String resolvePlanImageUrl(String? value) {
  final candidate = value?.trim() ?? '';
  if (candidate.isEmpty) return '';
  final parsed = Uri.tryParse(candidate);
  if (parsed == null) return '';
  final resolved = parsed.hasScheme
      ? parsed
      : Uri.parse(AppEnvironment.apiBaseUrl).resolveUri(parsed);
  return resolved.scheme == 'https' || resolved.scheme == 'http'
      ? resolved.toString()
      : '';
}

/// NetworkImage uses Flutter's shared image cache; bound decode size on mobile.
class MealPlanImage extends StatefulWidget {
  const MealPlanImage({super.key, required this.imageUrl, this.size = 96});
  final String? imageUrl;
  final double size;

  @override
  State<MealPlanImage> createState() => _MealPlanImageState();
}

class _MealPlanImageState extends State<MealPlanImage> {
  Stopwatch _watch = Stopwatch()..start();
  bool _recorded = false;

  @override
  void didUpdateWidget(MealPlanImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.size != widget.size) {
      _watch = Stopwatch()..start();
      _recorded = false;
    }
  }

  void _record(String outcome) {
    if (_recorded) return;
    _recorded = true;
    PerformanceTrace.record(
      'image.meal_plan.first_frame',
      _watch,
      outcome: outcome,
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = resolvePlanImageUrl(widget.imageUrl);
    final pixels = (widget.size * MediaQuery.devicePixelRatioOf(context))
        .ceil();
    const placeholder = ColoredBox(
      key: ValueKey('planImagePlaceholder'),
      color: Color(0xFFE9F1E8),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: AppLogo(width: 72, color: AppColors.emeraldGreen),
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox.square(
        dimension: widget.size,
        child: url.isEmpty
            ? placeholder
            : Image.network(
                url,
                fit: BoxFit.cover,
                cacheWidth: pixels,
                errorBuilder: (_, _, _) {
                  _record('failure');
                  return placeholder;
                },
                frameBuilder: (_, child, frame, synchronouslyLoaded) {
                  if (frame == null && !synchronouslyLoaded) return placeholder;
                  _record(synchronouslyLoaded ? 'cached' : 'loaded');
                  return child;
                },
              ),
      ),
    );
  }
}
