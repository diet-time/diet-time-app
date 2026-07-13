import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class RoutePlaceholderScreen extends StatelessWidget {
  const RoutePlaceholderScreen({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        foregroundColor: AppColors.white,
        backgroundColor: AppColors.emeraldGreen,
      ),
      body: Center(
        child: Text(
          AppLocalizations.of(context).comingSoon,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
