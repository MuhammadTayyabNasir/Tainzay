// lib/features/dashboard/widgets/sales_chart.dart
import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tainzy/app/models/models.dart';

import '../../providers/providers.dart';

class SalesChart extends ConsumerWidget {
  const SalesChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final salesData = ref.watch(salesByTypeProvider);
    final chartData = salesData.entries.toList();
    final currencyFormat = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs. ');

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
          Text('Sales by Product Type', style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          Expanded(
            child: chartData.isEmpty
                ? const Center(child: Text("No sales data available."))
                : BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                // --- NEW: INTERACTIVE TOOLTIPS ---
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    // tooltipBgColor: Colors.black87,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final type = chartData[groupIndex].key;
                      final value = chartData[groupIndex].value;
                      final typeName = type.name[0].toUpperCase() + type.name.substring(1);

                      return BarTooltipItem(
                        '$typeName\n',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        children: <TextSpan>[
                          TextSpan(
                            text: currencyFormat.format(value),
                            style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.w500),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                barGroups: chartData.mapIndexed((index, entry) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                          toY: entry.value,
                          color: theme.primaryColor,
                          width: 22,
                          borderRadius: BorderRadius.circular(4))
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= chartData.length) return const SizedBox();
                        final type = chartData[value.toInt()].key;
                        return Text(type.name.toUpperCase(), style: theme.textTheme.bodySmall);
                      },
                      reservedSize: 20,
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}