import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tainzy/app/models/transaction_model.dart';
import 'package:tainzy/app/repositories/transaction_repository.dart';

// Provider to get the raw stream of transactions from the repository
final transactionsStreamProvider = StreamProvider<List<Transaction>>((ref) {
  return ref.watch(transactionRepositoryProvider).getTransactions();
});

// State provider to hold the current search query
final transactionSearchQueryProvider = StateProvider<String>((ref) => '');

// Provider to return the filtered list of transactions
final filteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  // Watch the raw data stream and the search query
  final transactions = ref.watch(transactionsStreamProvider).asData?.value ?? [];
  final query = ref.watch(transactionSearchQueryProvider).toLowerCase();

  if (query.isEmpty) {
    return transactions; // Return all if search is empty
  }

  // Filter based on patient name or product name
  return transactions.where((tx) {
    final patientNameMatch = tx.patientName.toLowerCase().contains(query);
    final productNameMatch = tx.productName.toLowerCase().contains(query);
    return patientNameMatch || productNameMatch;
  }).toList();
});