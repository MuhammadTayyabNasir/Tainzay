// lib/features/product/screens/product_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/models/product_model.dart';
import '../../../app/services/firestore_service.dart';
import '../providers/product_providers.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  Future<void> _deleteProduct(BuildContext context, WidgetRef ref, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete product "${product.name}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(firestoreServiceProvider).deleteProduct(product.id!);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted successfully.')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting product: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncProducts = ref.watch(productsStreamProvider);
    final filteredProducts = ref.watch(filteredProductsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs ');

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            _FilterChips(),
            const Divider(height: 1),
            Expanded(
              child: asyncProducts.when(
                data: (_) {
                  if (filteredProducts.isEmpty) {
                    return const Center(
                      child: Text(
                        'No Inventory',
                        style: TextStyle(fontSize: 20, color: Colors.grey),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredProducts.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return ListTile(
                        title: Text(product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Batch: ${product.batch} | By: ${product.manufacturer}\nExpires: ${DateFormat.yMMMd().format(product.expiryDate)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currencyFormat.format(product.price),
                              style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  context.go('/product/${product.id}/edit');
                                } else if (value == 'delete') {
                                  _deleteProduct(context, ref, product);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChips extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(productTypeFilterProvider);
    final Map<String, ProductType> chipMap = {
      'Injection (INJ)': ProductType.injection,
      'Tablet (TAB)': ProductType.tablet,
      'Sachet (SAC)': ProductType.sachet,
      'Syrup (SYP)': ProductType.syrup,
    };

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: const Text('All'),
                selected: selectedType == null,
                onSelected: (isSelected) {
                  ref.read(productTypeFilterProvider.notifier).state = null;
                },
              ),
              const SizedBox(width: 8),
              ...chipMap.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: FilterChip(
                    label: Text(entry.key),
                    selected: selectedType == entry.value,
                    onSelected: (isSelected) {
                      ref.read(productTypeFilterProvider.notifier).state = isSelected ? entry.value : null;
                    },
                  ),
                );
              })
            ],
          ),
        )
    );
  }
}