import 'package:diet_time/features/personalization/domain/customer_onboarding.dart';
import 'package:diet_time/features/personalization/presentation/customer_onboarding_coordinator.dart';
import 'package:diet_time/app/localization/customer_copy.dart';
import 'dart:async';
import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum CheckoutAccess { login, questionnaire, summary, browse }

final checkoutAccessProvider = Provider<CheckoutAccessService>(
  CheckoutAccessService.new,
);

class CheckoutAccessService {
  CheckoutAccessService(this.ref);
  final Ref ref;

  Future<CheckoutAccess> resolve({bool refreshProfile = false}) async {
    if (ref.read(checkoutControllerProvider).selection == null) {
      return CheckoutAccess.browse;
    }
    final decision = await ref
        .read(customerOnboardingCoordinatorProvider.notifier)
        .check(refresh: refreshProfile);
    if (decision.phase == CustomerOnboardingPhase.unauthenticated) {
      return CheckoutAccess.login;
    }
    if (decision.phase == CustomerOnboardingPhase.recoverableError) {
      throw StateError('profile_load');
    }
    if (decision.phase != CustomerOnboardingPhase.ready) {
      return CheckoutAccess.questionnaire;
    }
    ref
        .read(checkoutControllerProvider.notifier)
        .useCustomerProfile(decision.profile!.profileId);
    return CheckoutAccess.summary;
  }
}

class CheckoutEntryScreen extends ConsumerStatefulWidget {
  const CheckoutEntryScreen({super.key});
  @override
  ConsumerState<CheckoutEntryScreen> createState() =>
      _CheckoutEntryScreenState();
}

class _CheckoutEntryScreenState extends ConsumerState<CheckoutEntryScreen> {
  bool _error = false;
  bool _resolving = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_resolve()));
  }

  Future<void> _resolve() async {
    if (_resolving) return;
    _resolving = true;
    if (_error) setState(() => _error = false);
    try {
      final access = await ref.read(checkoutAccessProvider).resolve();
      if (!mounted) return;
      switch (access) {
        case CheckoutAccess.browse:
          context.go(AppRoutes.plans);
        case CheckoutAccess.login:
          ref.read(checkoutControllerProvider.notifier).beginNewOrder();
          context.go(
            AppRoutes.phoneLogin,
            extra: const PendingAuthDestination(route: AppRoutes.startPlan),
          );
        case CheckoutAccess.questionnaire:
          context.go(AppRoutes.startPlan);
        case CheckoutAccess.summary:
          context.go(AppRoutes.planSummary);
      }
    } on Object {
      if (mounted) setState(() => _error = true);
    } finally {
      _resolving = false;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go(AppRoutes.plans),
      ),
    ),
    body: Center(
      child: _error
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.customerCopy('We could not load your profile.')),
                TextButton(
                  onPressed: () => unawaited(_resolve()),
                  child: Text(context.customerCopy('TRY AGAIN')),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.plans),
                  child: Text(context.customerCopy('Browse plans')),
                ),
              ],
            )
          : const CircularProgressIndicator(),
    ),
  );
}
