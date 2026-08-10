import 'dart:async';

import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/features/personalization/presentation/profile_persistence_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AuthenticatedLandingScreen extends ConsumerStatefulWidget {
  const AuthenticatedLandingScreen({super.key});

  @override
  ConsumerState<AuthenticatedLandingScreen> createState() =>
      _AuthenticatedLandingScreenState();
}

class _AuthenticatedLandingScreenState
    extends ConsumerState<AuthenticatedLandingScreen> {
  bool _started = false;
  bool _hasError = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_resolve()));
  }

  Future<void> _resolve() async {
    if (_hasError) setState(() => _hasError = false);
    final profile = await ref
        .read(profilePersistenceControllerProvider.notifier)
        .load();
    if (!mounted) return;
    if (profile == null &&
        ref.read(profilePersistenceControllerProvider).errorMessage != null) {
      setState(() => _hasError = true);
      return;
    }
    context.go(
      profile?.isCompleted == true ? AppRoutes.home : AppRoutes.personalization,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F6EF),
    body: Center(
      key: ValueKey(
        _hasError ? 'authenticatedLandingError' : 'authenticatedLandingLoading',
      ),
      child: _hasError
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "We couldn't load your profile.",
                  style: TextStyle(
                    color: AppColors.darkGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () => unawaited(_resolve()),
                  child: const Text('TRY AGAIN'),
                ),
              ],
            )
          : const CircularProgressIndicator(color: AppColors.emeraldGreen),
    ),
  );
}
