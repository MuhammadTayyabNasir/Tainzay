// lib/app/services/firestore_service.dart

// Hide Flutter's built-in Transaction class to avoid name conflicts with our model.
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/doctor_model.dart';
import '../models/patient_model.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';

// --- ARCHITECTURAL IMPROVEMENT ---
// The FirestoreService provider is now defined here, in one central place.
// Other provider files will import this file to access it.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- PATIENT CRUD ---
  Stream<List<Patient>> getPatients() => _db
      .collection('patients')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Patient.fromFirestore(doc)).toList());
  Future<DocumentReference> addPatientAndGetRef(Patient patient) async => _db.collection('patients').add(patient.toFirestore());
  Future<void> updatePatient(String id, Patient patient) async => _db.collection('patients').doc(id).update(patient.toFirestore());
  Future<void> deletePatient(String id) async => _db.collection('patients').doc(id).delete();


  // --- DOCTOR CRUD ---
  Stream<List<Doctor>> getDoctors() => _db
      .collection('doctors')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Doctor.fromFirestore(doc)).toList());
  Future<void> addDoctor(Doctor doctor) async => _db.collection('doctors').add(doctor.toFirestore());
  Future<void> updateDoctor(String id, Doctor doctor) async => _db.collection('doctors').doc(id).update(doctor.toFirestore());
  Future<void> deleteDoctor(String id) async => _db.collection('doctors').doc(id).delete();

  // --- PRODUCT CRUD ---
  Stream<List<Product>> getProducts() => _db
      .collection('products')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  Future<void> addProduct(Product product) async => _db.collection('products').add(product.toFirestore());
  Future<void> updateProduct(String id, Product product) async => _db.collection('products').doc(id).update(product.toFirestore());
  Future<void> deleteProduct(String id) async => _db.collection('products').doc(id).delete();

  // --- TRANSACTION CRUD ---
  Stream<List<Transaction>> getTransactions() => _db
      .collection('transactions')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Transaction.fromFirestore(doc)).toList());
  Future<void> addTransaction(Transaction transaction) async => _db.collection('transactions').add(transaction.toFirestore());
  Future<void> updateTransaction(String id, Transaction transaction) async => _db.collection('transactions').doc(id).update(transaction.toFirestore());
  Future<void> deleteTransaction(String id) async => _db.collection('transactions').doc(id).delete();
// --- FIXED: ADDED THE MISSING METHOD ---
  Stream<Doctor?> getDoctorById(String doctorId) {
    return _db.collection('doctors').doc(doctorId).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return Doctor.fromFirestore(snapshot);
      }
      return null;
    });
  }

}