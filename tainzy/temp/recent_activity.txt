// lib/features/dashboard/widgets/recent_activity.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/providers.dart';

class RecentActivity extends ConsumerWidget {
  const RecentActivity({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recentTxs = ref.watch(recentTransactionsProvider);
    final pkrFormat = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs ');

    return Container(
      height: 350,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Activity', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          Expanded(
            child: recentTxs.isEmpty
                ? const Center(child: Text('No transactions yet.'))
                : ListView.separated(
              itemCount: recentTxs.length,
              itemBuilder: (context, index) {
                final tx = recentTxs[index];
                return ListTile(
                  leading: const Icon(Icons.receipt, color: Colors.green),
                  title: Text(tx.productName, maxLines: 1),
                  subtitle: Text(DateFormat.yMMMd().format(tx.dateOfPurchase)),
                  trailing: Text(pkrFormat.format(tx.saleAmount)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                );
              },
              separatorBuilder: (_, __) => const Divider(height: 12),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton(onPressed: () => context.go('/transactions'), child: const Text('View All Transactions')),
          )
        ],
      ),
    );
  }
}