// lib/features/dashboard/providers/dashboard_providers.dart

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../doctor/providers/doctor_providers.dart';
import '../../patient/providers/patient_providers.dart';
import '../../product/providers/product_providers.dart';
import '../../transaction/providers/transaction_providers.dart';
import '../../../app/models/product_model.dart';
import '../../../app/models/transaction_model.dart';

// Provider for general dashboard statistics
final dashboardStatsProvider = Provider<Map<String, int>>((ref) {
  final patients = ref.watch(patientsStreamProvider).asData?.value ?? [];
  final doctors = ref.watch(doctorsStreamProvider).asData?.value ?? [];
  final products = ref.watch(productsStreamProvider).asData?.value ?? [];
  final transactions = ref.watch(transactionsStreamProvider).asData?.value ?? [];

  return {
    'patients': patients.length,
    'doctors': doctors.length,
    'products': products.length,
    'transactions': transactions.length,
  };
});

// Provider to get the 5 most recent transactions
final recentTransactionsProvider = Provider<List<Transaction>>((ref) {
  final transactions = ref.watch(transactionsStreamProvider).asData?.value ?? [];
  // Sort by date descending
  transactions.sort((a, b) => b.dateOfPurchase.compareTo(a.dateOfPurchase));
  return transactions.take(5).toList();
});

// Provider to calculate total sales per product type for the chart
final salesByTypeProvider = Provider<Map<ProductType, double>>((ref) {
  final products = ref.watch(productsStreamProvider).asData?.value ?? [];
  final transactions = ref.watch(transactionsStreamProvider).asData?.value ?? [];

  if (products.isEmpty || transactions.isEmpty) {
    return {};
  }

  // Create a fast lookup map for product name to product type
  final productTypeMap = {for (var p in products) p.name: p.type};

  final salesMap = <ProductType, double>{};

  for (final transaction in transactions) {
    final type = productTypeMap[transaction.productName];
    if (type != null) {
      salesMap.update(
        type,
            (value) => value + transaction.saleAmount,
        ifAbsent: () => transaction.saleAmount,
      );
    }
  }
  return salesMap;
});