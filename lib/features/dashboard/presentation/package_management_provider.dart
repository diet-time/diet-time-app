import 'package:diet_time/features/checkout/data/orders_repository.dart';
import 'package:diet_time/features/dashboard/domain/package_management.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final packageManagementProvider = FutureProvider.autoDispose
    .family<PackageManagement, String>(
      (ref, id) => ref.watch(ordersRepositoryProvider).getPackageManagement(id),
      retry: (_, _) => null,
    );

final packageScheduleChangesProvider =
    NotifierProvider<PackageScheduleChanges, Map<String, int>>(
      PackageScheduleChanges.new,
    );

class PackageScheduleChanges extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => const {};
  void changed(String id) => state = {...state, id: (state[id] ?? 0) + 1};
}
