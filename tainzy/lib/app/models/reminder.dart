// lib/app/models/reminder.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum ReminderStatus { due, contacted, no_response, completed }

class Reminder {
  final String? id;
  final String patientId;
  final String patientName;
  final String productName;
  final String transactionId;
  final DateTime lastPurchaseDate;
  final DateTime nextDueDate;
  final ReminderStatus status;

  Reminder({
    this.id,
    required this.patientId,
    required this.patientName,
    required this.productName,
    required this.transactionId,
    required this.lastPurchaseDate,
    required this.nextDueDate,
    this.status = ReminderStatus.due,
  });

  factory Reminder.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return Reminder(
      id: snapshot.id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      productName: data['productName'] ?? '',
      transactionId: data['transactionId'] ?? '',
      lastPurchaseDate: (data['lastPurchaseDate'] as Timestamp).toDate(),
      nextDueDate: (data['nextDueDate'] as Timestamp).toDate(),
      status: ReminderStatus.values.byName(data['status'] ?? 'due'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'productName': productName,
      'transactionId': transactionId,
      'lastPurchaseDate': Timestamp.fromDate(lastPurchaseDate),
      'nextDueDate': Timestamp.fromDate(nextDueDate),
      'status': status.name,
    };
  }
}