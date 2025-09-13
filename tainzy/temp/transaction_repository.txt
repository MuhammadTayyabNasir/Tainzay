import 'package:cloud_firestore/cloud_firestore.dart'hide Transaction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tainzy/app/models/transaction_model.dart';

class TransactionRepository {
  final FirebaseFirestore _db;
  TransactionRepository(this._db);

  // Get a stream of all transactions
  Stream<List<Transaction>> getTransactions() {
    return _db
        .collection('transactions')
        .orderBy('dateOfPurchase', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Transaction.fromFirestore(doc))
        .toList());
  }

  // Add a new transaction and return its document reference
  Future<DocumentReference> addTransaction(Transaction transaction) {
    return _db.collection('transactions').add(transaction.toFirestore());
  }

  // Update an existing transaction
  Future<void> updateTransaction(String id, Transaction transaction) {
    return _db.collection('transactions').doc(id).update(transaction.toFirestore());
  }

  // Delete a transaction
  Future<void> deleteTransaction(String id) {
    return _db.collection('transactions').doc(id).delete();
  }
}

// Provider for the Firebase Firestore instance
final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// Provider for the TransactionRepository
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(firebaseFirestoreProvider));
});