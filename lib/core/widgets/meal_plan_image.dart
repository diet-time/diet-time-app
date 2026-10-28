import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/config/app_environment.dart';
import 'package:diet_time/core/widgets/app_logo.dart';
import 'package:flutter/material.dart';

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
class MealPlanImage extends StatelessWidget {
  const MealPlanImage({super.key, required this.imageUrl, this.size = 96});
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = resolvePlanImageUrl(imageUrl);
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).ceil();
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
        dimension: size,
        child: url.isEmpty
            ? placeholder
            : Image.network(
                url,
                fit: BoxFit.cover,
                cacheWidth: pixels,
                errorBuilder: (_, _, _) => placeholder,
                frameBuilder: (_, child, frame, synchronouslyLoaded) =>
                    frame != null || synchronouslyLoaded ? child : placeholder,
              ),
      ),
    );
  }
}
