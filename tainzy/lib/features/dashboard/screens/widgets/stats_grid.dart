// lib/features/dashboard/screens/widgets/stats_grid.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tainzy/features/doctor/providers/doctor_providers.dart';
import 'package:tainzy/features/patient/providers/patient_providers.dart';
import 'package:tainzy/features/product/providers/product_providers.dart';
import 'package:tainzy/features/transaction/providers/transaction_providers.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine the number of columns based on width
        int crossAxisCount = 4;
        if (constraints.maxWidth < 850) crossAxisCount = 2;
        if (constraints.maxWidth < 450) crossAxisCount = 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: constraints.maxWidth < 450 ? 1.2 : 1.5, // Adjust aspect ratio for better look on small mobile
          children: [
            _StatCard(
              title: 'Patients',
              icon: Icons.people_alt_outlined,
              color: Colors.blue,
              provider: patientsStreamProvider,
              route: '/patients',
            ),
            _StatCard(
              title: 'Doctors',
              icon: Icons.medical_services_outlined,
              color: Colors.green,
              provider: doctorsStreamProvider,
              route: '/doctors',
            ),
            _StatCard(
              title: 'Stock',
              icon: Icons.inventory_2_outlined,
              color: Colors.orange,
              provider: productsStreamProvider,
              route: '/products',
            ),
            _StatCard(
              title: 'Transactions',
              icon: Icons.receipt_long_outlined,
              color: Colors.purple,
              provider: transactionsStreamProvider,
              route: '/transactions',
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends ConsumerWidget {
  final String title;
  final IconData icon;
  final Color color;
  // --- FIXED: Changed the provider type to the more generic ProviderBase ---
  final ProviderBase<AsyncValue<List<dynamic>>> provider;
  final String route;

  const _StatCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.provider,
    required this.route,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(provider);
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              data.when(
                data: (items) => Text(
                  items.length.toString(),
                  style: theme.textTheme.headlineLarge?.copyWith(color: color, fontWeight: FontWeight.bold,
                    fontSize: (MediaQuery.of(context).size.width<450)?16:24,
                  ),

                ),
                loading: () => const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)),
                error: (e, s) => const Icon(Icons.error_outline, color: Colors.red),
              ),
              Text(
                title,
                style: theme.textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}