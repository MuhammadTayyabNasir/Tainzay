// lib/app/models/product.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductType { injection, tablet, sachet, syrup, other }
enum ReminderUnit { none, days, weeks, months }

class Product {
  final String? id;
  final String name;
  final String batch;
  final double price;
  final String manufacturer;
  final List<String> activeIngredients;
  final ProductType type;
  final DateTime expiryDate;

  // --- NEW FIELDS ---
  final int stock;
  final int reminderInterval;
  final ReminderUnit reminderUnit;

  Product({
    this.id,
    required this.name,
    required this.batch,
    required this.price,
    required this.manufacturer,
    required this.activeIngredients,
    required this.type,
    required this.expiryDate,
    // --- NEW IN CONSTRUCTOR ---
    this.stock = 0,
    this.reminderInterval = 0,
    this.reminderUnit = ReminderUnit.none,
  });

  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return Product(
      id: snapshot.id,
      name: data['name'] ?? '',
      batch: data['batch'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      manufacturer: data['manufacturer'] ?? '',
      activeIngredients: List<String>.from(data['activeIngredients'] ?? []),
      type: ProductType.values.byName(data['type'] ?? 'other'),
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      // --- NEW MAPPINGS ---
      stock: data['stock'] ?? 0,
      reminderInterval: data['reminderInterval'] ?? 0,
      reminderUnit: ReminderUnit.values.byName(data['reminderUnit'] ?? 'none'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'batch': batch,
      'price': price,
      'manufacturer': manufacturer,
      'activeIngredients': activeIngredients,
      'type': type.name,
      'expiryDate': Timestamp.fromDate(expiryDate),
      // --- NEW TO MAP ---
      'stock': stock,
      'reminderInterval': reminderInterval,
      'reminderUnit': reminderUnit.name,
    };
  }
}