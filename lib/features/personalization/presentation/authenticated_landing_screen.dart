import 'dart:async';
import 'package:diet_time/app/localization/customer_copy.dart';
import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';
import 'package:diet_time/features/personalization/domain/customer_onboarding.dart';
import 'package:diet_time/features/personalization/presentation/customer_onboarding_coordinator.dart';
import 'package:diet_time/features/personalization/presentation/display_name_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The sole automatic navigator for authenticated customer onboarding.
class AuthenticatedLandingScreen extends ConsumerStatefulWidget {
  const AuthenticatedLandingScreen({this.startNewPlan = false, super.key});
  final bool startNewPlan;
  @override
  ConsumerState<AuthenticatedLandingScreen> createState() =>
      _AuthenticatedLandingScreenState();
}

class _AuthenticatedLandingScreenState
    extends ConsumerState<AuthenticatedLandingScreen> {
  bool _started = false, _resolving = false, _hasError = false;
  bool _refresh = false;
  bool _showingName = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.startNewPlan) {
        ref
            .read(customerOnboardingCoordinatorProvider.notifier)
            .begin(CustomerJourneyIntent.startNewPlan);
        ref.read(checkoutControllerProvider.notifier).beginNewOrder();
        _refresh = true;
      }
      unawaited(_resolve());
    });
  }

  Future<void> _resolve() async {
    if (_resolving) return;
    _resolving = true;
    if (_hasError) setState(() => _hasError = false);
    try {
      while (mounted) {
        final coordinator = ref.read(
          customerOnboardingCoordinatorProvider.notifier,
        );
        final result = await coordinator.check(refresh: _refresh);
        _refresh = false;
        if (!mounted) return;
        switch (result.phase) {
          case CustomerOnboardingPhase.unauthenticated:
            context.go(
              AppRoutes.phoneLogin,
              extra: PendingAuthDestination(
                route: result.intent == CustomerJourneyIntent.startNewPlan
                    ? AppRoutes.startPlan
                    : AppRoutes.authenticatedLanding,
              ),
            );
            return;
          case CustomerOnboardingPhase.profileRequired:
          case CustomerOnboardingPhase.nameRequired:
            setState(() => _showingName = true);
            await showGeneralDialog<String>(
              context: context,
              barrierDismissible: false,
              barrierColor: AppColors.darkGreen.withValues(alpha: .42),
              transitionDuration: const Duration(milliseconds: 420),
              pageBuilder: (dialogContext, _, _) => DisplayNamePanel(
                onSave: (name) async {
                  final saved = await coordinator.saveName(name);
                  if (dialogContext.mounted &&
                      ref.read(customerOnboardingCoordinatorProvider).phase ==
                          CustomerOnboardingPhase.unauthenticated) {
                    Navigator.of(dialogContext).pop();
                  }
                  return saved;
                },
              ),
            );
            if (mounted) setState(() => _showingName = false);
            break;
          case CustomerOnboardingPhase.questionnaireRequired:
            context.go(AppRoutes.customerSetup);
            return;
          case CustomerOnboardingPhase.ready:
            final destination =
                result.intent == CustomerJourneyIntent.startNewPlan
                ? AppRoutes.plans
                : AppRoutes.home;
            final container = ProviderScope.containerOf(context, listen: false);
            final router = GoRouter.of(context);
            context.go(destination);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (router.routeInformationProvider.value.uri.path !=
                  destination) {
                return;
              }
              final current = container.read(
                customerOnboardingCoordinatorProvider,
              );
              if (current.phase == CustomerOnboardingPhase.ready &&
                  current.profile?.profileId == result.profile?.profileId &&
                  current.intent == result.intent) {
                container
                    .read(customerOnboardingCoordinatorProvider.notifier)
                    .consumeIntent();
              }
            });
            return;
          case CustomerOnboardingPhase.recoverableError:
            setState(() => _hasError = true);
            return;
          case CustomerOnboardingPhase.loadingProfile:
            break;
        }
      }
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
                  style: const TextStyle(
                    color: AppColors.darkGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () {
                    _refresh = true;
                    unawaited(_resolve());
                  },
                  child: Text(context.customerCopy('TRY AGAIN')),
                ),
              ],
            )
          : _showingName
          ? const SizedBox.shrink()
          : const CircularProgressIndicator(color: AppColors.emeraldGreen),
    ),
  );
}
