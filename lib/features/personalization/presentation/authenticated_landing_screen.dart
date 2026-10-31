import 'package:diet_time/app/localization/customer_copy.dart';
import 'dart:async';

import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/features/personalization/presentation/profile_persistence_controller.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
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
  bool _resolving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_resolve()));
  }

  Future<void> _resolve() async {
    if (_resolving) return;
    _resolving = true;
    if (_hasError) setState(() => _hasError = false);
    try {
      final persistence = ref.read(profilePersistenceControllerProvider);
      if (!persistence.hasLoaded || persistence.errorMessage != null) {
        await ref.read(profilePersistenceControllerProvider.notifier).load();
      }
      if (!mounted) return;
      final loaded = ref.read(profilePersistenceControllerProvider);
      if (loaded.requiresLogin ||
          !ref.read(otpAuthControllerProvider).isAuthenticated) {
        context.go(
          AppRoutes.phoneLogin,
          extra: const PendingAuthDestination(
            route: AppRoutes.authenticatedLanding,
          ),
        );
        return;
      }
      if (loaded.errorMessage != null) {
        throw StateError('profile_load');
      }
      if (!mounted) return;
      context.go(
        ref.read(personalizationControllerProvider).isCompleted
            ? AppRoutes.home
            : AppRoutes.customerSetup,
      );
    } on Object {
      if (mounted) setState(() => _hasError = true);
    } finally {
      _resolving = false;
    }
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
                Text(
                  context.customerCopy("We couldn't load your profile."),
                  style: TextStyle(
                    color: AppColors.darkGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () => unawaited(_resolve()),
                  child: Text(context.customerCopy('TRY AGAIN')),
                ),
              ],
            )
          : const CircularProgressIndicator(color: AppColors.emeraldGreen),
    ),
  );
}
