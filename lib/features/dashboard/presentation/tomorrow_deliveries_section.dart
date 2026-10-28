import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/dashboard/domain/tomorrow_menu.dart';
import 'package:diet_time/features/dashboard/presentation/tomorrow_menu_section.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// One header for the dashboard; each keyed child owns its order's API session,
/// draft, cutoff timer and confirmation flow even when cards are reordered.
class TomorrowDeliveriesSection extends StatefulWidget {
  const TomorrowDeliveriesSection({super.key, required this.orders});

  final List<CustomerOrderSummary> orders;

  @override
  State<TomorrowDeliveriesSection> createState() =>
      _TomorrowDeliveriesSectionState();
}

class _TomorrowDeliveriesSectionState extends State<TomorrowDeliveriesSection> {
  final Map<String, TomorrowMenu> _menus = {};
  final Set<String> _loaded = {};

  int _priority(String id) {
    final menu = _menus[id];
    if (menu?.canConfirm == true && menu?.readOnly == false) return 0;
    return menu?.readOnly == true ? 2 : 1;
  }

  void _received(String orderId, TomorrowMenu? menu) {
    // A load can finish as a child is mounting or changing locale.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.orders.any((order) => order.id == orderId)) {
        return;
      }
      setState(() {
        _loaded.add(orderId);
        if (menu == null) {
          _menus.remove(orderId);
        } else {
          _menus[orderId] = menu;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final copy = lookupAppLocalizations(locale);
    final ids = widget.orders.map((order) => order.id).toSet();
    final menus = _menus.entries
        .where((entry) => ids.contains(entry.key))
        .map((entry) => entry.value)
        .toList();
    final scheduled = menus.where((menu) => menu.scheduledForTomorrow).length;
    final sorted = widget.orders.indexed.toList()
      ..sort((a, b) {
        final priority = _priority(a.$2.id).compareTo(_priority(b.$2.id));
        return priority == 0 ? a.$1.compareTo(b.$1) : priority;
      });
    return Column(
      key: const ValueKey('tomorrowDeliveries'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          copy.deliveriesTitle,
          style: const TextStyle(
            color: AppColors.darkGreen,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 10,
          runSpacing: 4,
          children: [
            if (menus.isNotEmpty)
              Text(
                DateFormat(
                  'EEEE, d MMMM',
                  locale.languageCode == 'ar' ? 'ar' : null,
                ).format(menus.first.deliveryDate),
                key: const ValueKey('tomorrowDeliveryDate'),
                style: const TextStyle(
                  color: AppColors.darkGreen,
                  fontSize: 12,
                ),
              ),
            Text(
              !ids.every(_loaded.contains)
                  ? copy.deliveriesLoading
                  : menus.length < ids.length
                  ? copy.deliveriesUnavailable
                  : copy.deliveriesScheduled(scheduled),
              key: const ValueKey('tomorrowDeliveryCount'),
              style: TextStyle(
                color: AppColors.darkGreen.withValues(alpha: .65),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final (_, order) in sorted)
          Padding(
            key: ValueKey('deliveryOrder-${order.id}'),
            padding: _menus[order.id]?.scheduledForTomorrow == false
                ? EdgeInsets.zero
                : const EdgeInsets.only(bottom: 10),
            child: TomorrowMenuSection(
              key: ValueKey('tomorrow-${order.id}'),
              orderId: order.id,
              orderReference: order.orderNumber,
              scheduledOnly: true,
              onMenuLoaded: (menu) => _received(order.id, menu),
            ),
          ),
      ],
    );
  }
}
