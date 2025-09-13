// lib/app/models/transaction_model.dart
// --- FIXED: Added 'hide Transaction' here as well for consistency and safety ---
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;

enum PaymentStatus { pending, paid, cancelled }

class Transaction {
  final String? id;
  final String? patientId;
  final String productName;
  final String patientName;
  final PaymentStatus paymentStatus;
  final DateTime dateOfPurchase;
  final double saleAmount;
  final int qty;
  final double discountPercentage;
  final double discountAmount;

  Transaction({
    this.id,
    this.patientId,
    required this.productName,
    required this.patientName,
    required this.paymentStatus,
    required this.dateOfPurchase,
    required this.saleAmount,
    required this.qty,
    required this.discountPercentage,
    required this.discountAmount,
  });

  Transaction copyWith({
    String? id,
    String? patientId,
    String? productName,
    String? patientName,
    PaymentStatus? paymentStatus,
    DateTime? dateOfPurchase,
    double? saleAmount,
    int? qty,
    double? discountPercentage,
    double? discountAmount,
  }) {
    return Transaction(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      productName: productName ?? this.productName,
      patientName: patientName ?? this.patientName,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      dateOfPurchase: dateOfPurchase ?? this.dateOfPurchase,
      saleAmount: saleAmount ?? this.saleAmount,
      qty: qty ?? this.qty,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }

  factory Transaction.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return Transaction(
      id: snapshot.id,
      patientId: data['patientId'] as String?,
      productName: data['productName'] as String? ?? 'Unknown Product',
      patientName: data['patientName'] as String? ?? 'Unknown Patient',
      paymentStatus: PaymentStatus.values.firstWhere(
            (e) => e.name == data['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      dateOfPurchase: (data['dateOfPurchase'] as Timestamp).toDate(),
      saleAmount: (data['saleAmount'] as num? ?? 0).toDouble(),
      qty: data['qty'] as int? ?? 0,
      discountPercentage: (data['discountPercentage'] as num? ?? 0).toDouble(),
      discountAmount: (data['discountAmount'] as num? ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (patientId != null) 'patientId': patientId,
      'productName': productName,
      'patientName': patientName,
      'paymentStatus': paymentStatus.name,
      'dateOfPurchase': Timestamp.fromDate(dateOfPurchase),
      'saleAmount': saleAmount,
      'qty': qty,
      'discountPercentage': discountPercentage,
      'discountAmount': discountAmount,
    };
  }



}
