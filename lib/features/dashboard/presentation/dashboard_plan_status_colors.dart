import 'package:flutter/material.dart';

/// Dashboard presentation only; order and pause state are owned by the API.
({Color background, Color foreground}) dashboardPlanStatusColors(
  String status,
) => switch (status) {
  'UPCOMING' => (
    background: const Color(0xFFDDF1ED),
    foreground: const Color(0xFF176B62),
  ),
  'PENDING' || 'PENDING_APPROVAL' || 'PAUSE_REQUESTED' => (
    background: const Color(0xFFFFF0D5),
    foreground: const Color(0xFF8A601E),
  ),
  'PAUSE_SCHEDULED' => (
    background: const Color(0xFFDCEAF4),
    foreground: const Color(0xFF285A7A),
  ),
  'PAUSED' => (
    background: const Color(0xFFE5E7EB),
    foreground: const Color(0xFF475569),
  ),
  'CANCELLED' => (
    background: const Color(0xFFF5E6E8),
    foreground: const Color(0xFFA34452),
  ),
  _ => (background: const Color(0xFF205B46), foreground: Colors.white),
};
