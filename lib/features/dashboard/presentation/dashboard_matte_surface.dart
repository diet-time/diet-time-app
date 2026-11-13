import 'package:flutter/material.dart';

/// Quiet tonal layers derived entirely from the dashboard's existing colors.
class DashboardMatteSurface extends StatelessWidget {
  const DashboardMatteSurface({
    super.key,
    required this.color,
    required this.child,
  });

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Ink(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color, Color.alphaBlend(const Color(0x08000000), color)],
      ),
    ),
    child: Stack(
      children: [
        Positioned(left: -52, bottom: -85, child: _curve(190, 120)),
        Positioned(right: -45, bottom: -105, child: _curve(220, 150)),
        child,
      ],
    ),
  );

  Widget _curve(double width, double height) => IgnorePointer(
    child: ExcludeSemantics(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .025),
          borderRadius: BorderRadius.all(Radius.elliptical(width, height)),
        ),
      ),
    ),
  );
}
