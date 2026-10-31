import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_tour_controller.dart';
import 'tour_copy.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';

class AppTourSetting extends ConsumerWidget {
  const AppTourSetting({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appTourControllerProvider);
    final enabled = ref
        .watch(personalizationControllerProvider)
        .isAppTourEnabled;
    return SwitchListTile.adaptive(
      key: const ValueKey('appTourSetting'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      title: Text(tourCopy(context, 'enable')),
      subtitle: Text(tourCopy(context, 'description')),
      value: enabled,
      onChanged: state.saving
          ? null
          : (value) async {
              final controller = ref.read(appTourControllerProvider.notifier);
              final saved = await controller.setEnabled(value);
              if (context.mounted && saved && value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tourCopy(context, 'enabled'))),
                );
              }
            },
    );
  }
}

class AppTourHost extends ConsumerStatefulWidget {
  const AppTourHost({required this.child, super.key});
  final Widget child;
  @override
  ConsumerState<AppTourHost> createState() => _AppTourHostState();
}

class _AppTourHostState extends ConsumerState<AppTourHost>
    with WidgetsBindingObserver {
  final _content = GlobalKey(), _stack = GlobalKey();
  Rect? _rect;
  int _generation = 0;
  String? _prepared;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _prepared = null;
    if (mounted) setState(() {});
  }

  Element? _find(List<String> targets) {
    final root = _content.currentContext as Element?;
    if (root == null) return null;
    for (final target in targets) {
      Element? found;
      void visit(Element element) {
        if (found != null) return;
        if (element.widget is Offstage &&
            (element.widget as Offstage).offstage) {
          return;
        }
        final key = element.widget.key;
        if (key is ValueKey<String> &&
            (key.value == target ||
                target.endsWith('-') && key.value.startsWith(target))) {
          final render = element.findRenderObject();
          if (render is RenderBox &&
              render.attached &&
              render.hasSize &&
              !render.size.isEmpty) {
            found = element;
            return;
          }
        }
        element.visitChildren(visit);
      }

      root.visitChildren(visit);
      if (found != null) return found;
    }
    return null;
  }

  ScrollPosition? _visibleScroll() {
    ScrollPosition? result;
    void visit(Element element) {
      if (element.widget is Offstage && (element.widget as Offstage).offstage) {
        return;
      }
      if (element is StatefulElement && element.state is ScrollableState) {
        final position = (element.state as ScrollableState).position;
        if (position.axis == Axis.vertical &&
            position.hasContentDimensions &&
            position.maxScrollExtent > 0) {
          result = position;
        }
      }
      element.visitChildren(visit);
    }

    (_content.currentContext as Element?)?.visitChildren(visit);
    return result;
  }

  Future<void> _prepare(TourStep step) async {
    final generation = ++_generation;
    if (!ref.read(appTourControllerProvider).running ||
        ref.read(appTourControllerProvider).step.id != step.id) {
      return;
    }
    _rect = null;
    final controller = ref.read(appTourControllerProvider.notifier);
    try {
      await controller.navigate?.call(step.destination);
      for (var attempt = 0; attempt < 25; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        if (!mounted ||
            generation != _generation ||
            !ref.read(appTourControllerProvider).running) {
          return;
        }
        final target = _find(step.targets);
        if (target == null) {
          // Later attempts reveal lazily built content below the viewport.
          final scroll = _visibleScroll();
          if (attempt > 5 && scroll != null) {
            final next = (scroll.pixels + scroll.viewportDimension * .65).clamp(
              scroll.minScrollExtent,
              scroll.maxScrollExtent,
            );
            if (next != scroll.pixels) scroll.jumpTo(next);
          }
          continue;
        }
        final animation = ModalRoute.of(target)?.animation;
        if (animation != null &&
            animation.status != AnimationStatus.completed) {
          continue;
        }
        await Scrollable.ensureVisible(
          target,
          duration: Duration.zero,
          alignment: .2,
        );
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted || generation != _generation) return;
        final box = target.findRenderObject();
        final stack = _stack.currentContext?.findRenderObject();
        if (box is! RenderBox || !box.attached || stack is! RenderBox) continue;
        final rect = box.localToGlobal(Offset.zero, ancestor: stack) & box.size;
        setState(() => _rect = rect.intersect(Offset.zero & stack.size));
        return;
      }
    } catch (_) {
      /* A feature may disappear during a refresh. Skip remains available. */
    }
    if (mounted && generation == _generation && step.optional) {
      controller.unavailable();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tour = ref.watch(appTourControllerProvider);
    final id = tour.running ? '${tour.step.id}:${tour.index}' : null;
    if (id != _prepared) {
      _prepared = id;
      _generation++;
      _rect = null;
      if (id != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_prepare(tour.step));
        });
      } else {
        _generation++;
        _rect = null;
      }
    }
    final controller = ref.read(appTourControllerProvider.notifier);
    return Stack(
      key: _stack,
      fit: StackFit.expand,
      children: [
        KeyedSubtree(
          key: _content,
          child: ExcludeSemantics(excluding: tour.running, child: widget.child),
        ),
        if (!tour.running && tour.failedValue != null)
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: const Color(0xFFFFF5DF),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(child: Text(tourCopy(context, 'failed'))),
                      TextButton(
                        onPressed: () =>
                            controller.setEnabled(tour.failedValue!),
                        child: Text(tourCopy(context, 'retry')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (tour.running) ...[
          Positioned.fill(
            child: AbsorbPointer(
              child: CustomPaint(painter: _Spotlight(_rect)),
            ),
          ),
          // AbsorbPointer paints but does not capture hit tests outside a child. This barrier does.
          const Positioned.fill(
            child: ModalBarrier(dismissible: false, color: Colors.transparent),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => Align(
                alignment:
                    _rect != null &&
                        _rect!.center.dy > constraints.maxHeight / 2
                    ? Alignment.topCenter
                    : Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 440,
                      maxHeight: constraints.maxHeight * .60,
                    ),
                    child: Material(
                      key: const ValueKey('appTourTooltip'),
                      color: const Color(0xFFFFFCF2),
                      elevation: 8,
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Flexible(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${tour.index + 1} ${tourCopy(context, 'of')} ${tour.steps.length}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelMedium,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      tourCopy(
                                        context,
                                        '${tour.step.id}.title',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: const Color(0xFF075A43),
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(tourCopy(context, tour.step.id)),
                                    if (tour.index == 0)
                                      CheckboxListTile(
                                        contentPadding: EdgeInsets.zero,
                                        dense: true,
                                        value: tour.detailed,
                                        onChanged: (v) =>
                                            controller.detail(v ?? false),
                                        title: Text(
                                          tourCopy(context, 'detail'),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4,
                              children: [
                                TextButton(
                                  key: const ValueKey('tourSkip'),
                                  onPressed: controller.finish,
                                  child: Text(tourCopy(context, 'skip')),
                                ),
                                TextButton(
                                  key: const ValueKey('tourPrevious'),
                                  onPressed: tour.index == 0
                                      ? null
                                      : () => controller.move(-1),
                                  child: Text(tourCopy(context, 'previous')),
                                ),
                                FilledButton(
                                  key: const ValueKey('tourNext'),
                                  onPressed: tour.index == tour.steps.length - 1
                                      ? controller.finish
                                      : () => controller.move(1),
                                  child: Text(
                                    tourCopy(
                                      context,
                                      tour.index == tour.steps.length - 1
                                          ? 'finish'
                                          : 'next',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Spotlight extends CustomPainter {
  _Spotlight(this.rect);
  final Rect? rect;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRect(Offset.zero & size);
    if (rect != null && !rect!.isEmpty) {
      path.addRRect(
        RRect.fromRectAndRadius(rect!.inflate(4), const Radius.circular(12)),
      );
    }
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: .68));
    if (rect != null && !rect!.isEmpty) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect!.inflate(4), const Radius.circular(12)),
        Paint()
          ..color = const Color(0xFFB8DFC8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_Spotlight old) => old.rect != rect;
}
