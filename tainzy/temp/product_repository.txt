// lib/app/repositories/product_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(FirebaseFirestore.instance);
});

class ProductRepository {
  final FirebaseFirestore _db;
  ProductRepository(this._db);

  CollectionReference<Product> get _productsRef =>
      _db.collection('products').withConverter<Product>(
        fromFirestore: (snapshot, _) => Product.fromFirestore(snapshot),
        toFirestore: (product, _) => product.toFirestore(),
      );

  // NOTE: This is an example, you would create repositories for each model
  Stream<List<Product>> getProducts() =>
      _productsRef.snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

  Future<void> addProduct(Product product) => _productsRef.add(product);

  Future<void> updateProduct(String id, Product product) => _productsRef.doc(id).set(product);

  Future<void> deleteProduct(String id) => _productsRef.doc(id).delete();

  // --- NEW METHOD: ATOMIC STOCK UPDATE ---
  Future<void> updateStock(String productId, int quantityChange) {
    // Use a transaction to safely read the current stock and then update it.
    // This prevents race conditions if multiple sales happen at once.
    return _db.runTransaction((transaction) async {
      final productRef = _productsRef.doc(productId);
      final snapshot = await transaction.get(productRef);

      if (!snapshot.exists) {
        throw Exception("Product does not exist!");
      }

      final newStock = (snapshot.data()?.stock ?? 0) - quantityChange;
      transaction.update(productRef, {'stock': newStock});
    });
  }
}