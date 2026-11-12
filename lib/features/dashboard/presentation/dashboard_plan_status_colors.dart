import 'package:flutter/material.dart';

/// Dashboard presentation only; order and pause state are owned by the API.
({Color background, Color foreground}) dashboardPlanStatusColors(
  String status,
) => switch (status) {
  'UPCOMING' => (
    background: const Color(0xFFDDF1ED),
    foreground: const Color(0xFF236C63),
  ),
  'PENDING' || 'PENDING_APPROVAL' => (
    background: const Color(0xFFF0EBFA),
    foreground: const Color(0xFF66518C),
  ),
  'PAUSE_REQUESTED' => (
    background: const Color(0xFFFFF0E8),
    foreground: const Color(0xFFA45F40),
  ),
  'PAUSED' || 'PAUSE_SCHEDULED' => (
    background: const Color(0xFFE8EEF4),
    foreground: const Color(0xFF45627D),
  ),
  'CANCELLED' => (
    background: const Color(0xFFF0F0EE),
    foreground: const Color(0xFF727775),
  ),
  _ => (background: const Color(0xFF285747), foreground: Colors.white),
};
