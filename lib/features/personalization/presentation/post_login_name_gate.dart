import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/features/personalization/data/display_name_repository.dart';
import 'package:diet_time/features/personalization/presentation/display_name_panel.dart';
import 'package:diet_time/features/personalization/presentation/post_login_landing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PostLoginNameGate extends ConsumerStatefulWidget {
  const PostLoginNameGate({required this.onContinue, super.key});

  final VoidCallback onContinue;

  @override
  ConsumerState<PostLoginNameGate> createState() => _PostLoginNameGateState();
}

class _PostLoginNameGateState extends ConsumerState<PostLoginNameGate> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureNameIfNeeded());
  }

  Future<void> _captureNameIfNeeded() async {
    final repository = ref.read(displayNameRepositoryProvider);
    final existingName = await repository.load();
    if (!mounted || existingName != null) return;

    final name = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.darkGreen.withValues(alpha: .42),
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, _, _) => const DisplayNamePanel(),
      transitionBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, .45),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
    if (!mounted || name == null) return;
    await repository.save(name);
  }

  @override
  Widget build(BuildContext context) {
    return PostLoginLandingScreen(onContinue: widget.onContinue);
  }
}
