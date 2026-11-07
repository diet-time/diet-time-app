import 'dart:async';
import 'package:diet_time/features/checkout/data/orders_repository.dart';
import 'package:diet_time/features/dashboard/domain/package_management.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final packageManagementProvider = FutureProvider.autoDispose
    .family<PackageManagement, String>((ref, id) async {
      final data = await ref
          .watch(ordersRepositoryProvider)
          .getPackageManagement(id);
      if (ref.mounted) {
        unawaited(
          Future<void>.microtask(() {
            if (ref.mounted) {
              ref
                  .read(packageScheduleChangesProvider.notifier)
                  .observed(id, data.scheduleFingerprint);
            }
          }),
        );
        final timer = Timer(const Duration(seconds: 30), ref.invalidateSelf);
        ref.onDispose(timer.cancel);
      }
      return data;
    }, retry: (_, _) => null);

final packageScheduleChangesProvider =
    NotifierProvider<PackageScheduleChanges, Map<String, int>>(
      PackageScheduleChanges.new,
    );

class PackageScheduleChanges extends Notifier<Map<String, int>> {
  final Map<String, String> _fingerprints = {};
  @override
  Map<String, int> build() => const {};
  void changed(String id) {
    _fingerprints.remove(id);
    state = {...state, id: (state[id] ?? 0) + 1};
  }

  void observed(String id, String fingerprint) {
    final previous = _fingerprints[id];
    _fingerprints[id] = fingerprint;
    if (previous != null && previous != fingerprint) {
      state = {...state, id: (state[id] ?? 0) + 1};
    }
  }
}
