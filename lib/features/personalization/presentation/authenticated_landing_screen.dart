import 'package:diet_time/app/localization/customer_copy.dart';
import 'dart:async';

import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/features/personalization/presentation/profile_persistence_controller.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:diet_time/features/checkout/data/orders_repository.dart';
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
    try {
      final persistence = ref.read(profilePersistenceControllerProvider);
      final profile = persistence.hasLoaded && persistence.errorMessage == null
          ? ref.read(personalizationControllerProvider)
          : await ref
                .read(profilePersistenceControllerProvider.notifier)
                .load();
      if (ref.read(profilePersistenceControllerProvider).errorMessage != null) {
        throw StateError('profile_load');
      }
      final orders = profile?.profileId == null
          ? null
          : await ref
                .read(ordersRepositoryProvider)
                .getCustomerOrders(profile!.profileId!);
      if (!mounted) return;
      context.go(
        orders?.any(
                  (order) =>
                      order.isCurrent ||
                      [
                        'PENDING_APPROVAL',
                        'ON_HOLD',
                        'REJECTED',
                      ].contains(order.status) ||
                      order.review['awaitingPayment'] == true,
                ) ==
                true
            ? AppRoutes.home
            : AppRoutes.plans,
      );
    } on Object {
      if (mounted) setState(() => _hasError = true);
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
