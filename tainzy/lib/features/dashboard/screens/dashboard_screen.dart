// lib/features/dashboard/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:tainzy/features/dashboard/screens/widgets/recent_activity.dart';
import 'package:tainzy/features/dashboard/screens/widgets/sales_chart.dart';
import 'package:tainzy/features/dashboard/screens/widgets/stats_grid.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome, Operator.', style: theme.textTheme.headlineMedium),
          Text("Here's your system overview for today.", style: theme.textTheme.bodyLarge),
          const SizedBox(height: 24),
          // RESPONSIVE NOTE: The `StatsGrid` widget's implementation is key.
          // It should use a `Wrap` widget or a `GridView.builder` with a
          // responsive grid delegate (e.g., SliverGridDelegateWithMaxCrossAxisExtent)
          // to ensure the stat cards reflow gracefully on different screen sizes.
          const StatsGrid(),
          const SizedBox(height: 24),
          ResponsiveBuilder(
            builder: (context, sizingInfo) {
              // RESPONSIVE NOTE: The `SalesChart` and `RecentActivity` widgets
              // must also be internally responsive. For example, the chart might
              // show fewer labels on smaller screens to avoid clutter.
              if (sizingInfo.isDesktop || sizingInfo.isTablet) {
                // Desktop layout uses a Row for side-by-side content.
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(flex: 3, child: SalesChart()),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: RecentActivity()),
                  ],
                );
              }
              // On Mobile, stack them vertically.
              return Column(
                children: [
                  const SalesChart(),
                  const SizedBox(height: 24),
                  RecentActivity(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}