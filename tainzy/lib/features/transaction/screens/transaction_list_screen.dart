import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tainzy/app/models/models.dart';
import 'package:tainzy/app/repositories/transaction_repository.dart';
import 'package:tainzy/features/invoice/invoice_generator.dart';
import 'package:tainzy/features/patient/providers/patient_providers.dart';
import 'package:tainzy/features/transaction/providers/transaction_providers.dart';

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  // Helper method for the delete action
  Future<void> _deleteTransaction(BuildContext context, WidgetRef ref, Transaction tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete the transaction for "${tx.productName}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(transactionRepositoryProvider).deleteTransaction(tx.id!);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction deleted successfully.')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting transaction: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the filtered provider for the list
    final filteredTransactionsAsync = ref.watch(filteredTransactionsProvider);
    final patientsAsync = ref.watch(patientsStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by Patient or Product...',
                prefixIcon: Icon(Icons.search),
              ),
              // Connect the text field to the search provider
              onChanged: (query) => ref.read(transactionSearchQueryProvider.notifier).state = query,
            ),
          ),
          Expanded(
            child: filteredTransactionsAsync.isEmpty
                ? const Center(child: Text('No transactions match your search.'))
                : patientsAsync.when(
              data: (patients) {
                final patientMap = {for (var p in patients) p.id: p};

                return ListView.builder(
                  itemCount: filteredTransactionsAsync.length,
                  itemBuilder: (context, index) {
                    final tx = filteredTransactionsAsync[index];
                    final patient = patientMap[tx.patientId];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.primaryColor.withOpacity(0.1),
                          child: Icon(Icons.receipt_long_outlined, color: theme.primaryColor),
                        ),
                        title: Text(tx.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Patient: ${tx.patientName}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  NumberFormat.currency(locale: 'en_PK', symbol: 'Rs ').format(tx.saleAmount),
                                  style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor),
                                ),
                                Text(DateFormat.yMMMd().format(tx.dateOfPurchase)),
                              ],
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                switch (value) {
                                  case 'invoice':
                                    if (patient != null) {
                                      await InvoiceGenerator.generateAndShowInvoice(tx, patient);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Error: Patient data not found.')),
                                      );
                                    }
                                    break;
                                  case 'edit':
                                    context.go('/transaction/${tx.id}/edit');
                                    break;
                                  case 'delete':
                                    await _deleteTransaction(context, ref, tx);
                                    break;
                                }
                              },
                              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'invoice',
                                  child: ListTile(leading: Icon(Icons.description_outlined), title: Text('Generate Invoice')),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'edit',
                                  child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit')),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red))),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}