import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/models/product_model.dart';
import '../../../app/services/firestore_service.dart';

final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(firestoreServiceProvider).getProducts();
});

final productSearchQueryProvider = StateProvider<String>((ref) => '');

// New provider to hold the selected product type for filtering
final productTypeFilterProvider = StateProvider<ProductType?>((ref) => null);

final filteredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(productsStreamProvider).asData?.value ?? [];
  final query = ref.watch(productSearchQueryProvider).toLowerCase();
  final selectedType = ref.watch(productTypeFilterProvider);

  // Filter by search query first
  final searchedProducts = query.isEmpty
      ? products
      : products.where((product) {
    return product.name.toLowerCase().contains(query) ||
        product.batch.toLowerCase().contains(query) ||
        product.manufacturer.toLowerCase().contains(query);
  }).toList();

  // Then, filter by selected type
  if (selectedType == null) {
    return searchedProducts; // No type filter applied
  }

  return searchedProducts.where((product) => product.type == selectedType).toList();
});