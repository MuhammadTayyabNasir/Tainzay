// Run this file from your project root using: dart run populate_firestore.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faker/faker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart'; // <-- ADD THIS IMPORT
import 'firebase_options.dart';

// The rest of the file remains exactly the same...

Future<void> main() async {
  // 1. Initialize Firebase
  print('Initializing Firebase...');
  WidgetsFlutterBinding.ensureInitialized(); // <-- ALSO ADD THIS LINE
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Firebase Initialized Successfully.');

  final db = FirebaseFirestore.instance;
  final faker = Faker();
  final now = DateTime.now();

  // --- CONFIGURATION ---
  const int numberOfPatients = 15;
  final List<Map<String, dynamic>> productTemplates = [
    {
      'name': 'Neurobion Injection',
      'type': 'injection',
      'reminderUnit': 'weeks',
      'reminderInterval': 2, // Every 2 weeks
      'price': 150.0,
      'stock': 100,
    },
    {
      'name': 'Vitamin D Sachet',
      'type': 'sachet',
      'reminderUnit': 'days',
      'reminderInterval': 7, // Every 7 days
      'price': 50.0,
      'stock': 200,
    },
    {
      'name': 'Thyroxine 50mcg Tablet',
      'type': 'tablet',
      'reminderUnit': 'months',
      'reminderInterval': 1, // Every month
      'price': 450.0,
      'stock': 150,
    },
    {
      'name': 'Ferinject IV',
      'type': 'injection',
      'reminderUnit': 'months',
      'reminderInterval': 3, // Every 3 months
      'price': 5500.0,
      'stock': 50
    },
    {
      'name': 'Panadol Syrup',
      'type': 'syrup',
      'reminderUnit': 'none', // No reminder for this one
      'reminderInterval': 0,
      'price': 90.0,
      'stock': 300,
    }
  ];

  // --- BATCH WRITER FOR EFFICIENCY ---
  final batch = db.batch();

  // 2. Create Products
  print('\n--- Creating Products ---');
  final List<DocumentReference> productRefs = [];
  for (final template in productTemplates) {
    final productRef = db.collection('products').doc();
    productRefs.add(productRef);
    batch.set(productRef, {
      ...template,
      'batch': List.generate(8, (index) {
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return chars[random.integer(chars.length)];
    }).join(),
      'manufacturer': faker.company.name(),
      'activeIngredients': [faker.lorem.word()],
      'expiryDate': Timestamp.fromDate(DateTime(now.year + 2, now.month, now.day)),
    });
    print('  - Queued: ${template['name']}');
  }

  // 3. Create Patients, Transactions, and Reminders
  print('\n--- Creating Patients, Transactions, and Reminders ---');
  for (int i = 0; i < numberOfPatients; i++) {
    // ---- Create Patient ----
    final patientRef = db.collection('patients').doc();
    final patientName = faker.person.name();
    batch.set(patientRef, {
      'name': patientName,
      'phoneNumber': faker.phoneNumber.us(),
      'city': faker.address.city(),
      'referringDoctor': 'Dr. ${faker.person.lastName()}',
      'note': 'Sample note for testing.',
      'dateAdded': Timestamp.now(),
    });

    // ---- Create a Transaction for this Patient ----
    final productIndex = i % productTemplates.length;
    final product = productTemplates[productIndex];
    final purchaseDate = now.subtract(Duration(days: faker.randomGenerator.integer(60)));

    if (product['reminderUnit'] == 'none') {
      print('  - Queued: Patient ${patientName} (No reminder product)');
      continue;
    }

    final transactionRef = db.collection('transactions').doc();
    batch.set(transactionRef, {
      'patientId': patientRef.id,
      'productName': product['name'],
      'paymentStatus': 'paid',
      'dateOfPurchase': Timestamp.fromDate(purchaseDate),
      'saleAmount': product['price'],
      'qty': 1,
      'discountPercentage': 0.0,
      'discountAmount': 0.0,
    });


    // ---- Create a corresponding Reminder ----
    final reminderRef = db.collection('reminders').doc();
    final reminderInterval = product['reminderInterval'] as int;
    final reminderUnit = product['reminderUnit'] as String;
    late DateTime nextDueDate;

    switch (reminderUnit) {
      case 'days':
        nextDueDate = purchaseDate.add(Duration(days: reminderInterval));
        break;
      case 'weeks':
        nextDueDate = purchaseDate.add(Duration(days: reminderInterval * 7));
        break;
      case 'months':
        nextDueDate = DateTime(purchaseDate.year, purchaseDate.month + reminderInterval, purchaseDate.day);
        break;
    }

    // Assign a random status to test the UI filters
    final status = ReminderStatus.values[faker.randomGenerator.integer(ReminderStatus.values.length)];

    batch.set(reminderRef, {
      'patientId': patientRef.id,
      'patientName': patientName,
      'productName': product['name'],
      'transactionId': transactionRef.id,
      'lastPurchaseDate': Timestamp.fromDate(purchaseDate),
      'nextDueDate': Timestamp.fromDate(nextDueDate),
      'status': status.name,
    });
    print('  - Queued: Patient ${patientName} -> ${product['name']} (Due: ${nextDueDate.toIso8601String().substring(0,10)})');
  }

  // 4. Commit all operations to Firestore
  try {
    print('\nCommitting batch to Firestore...');
    await batch.commit();
    print('\n✅✅✅ Success! Dummy data has been added to your Firestore database.');
    print('Please refresh your app to see the new data in the "Medicine Schedules" page.');
  } catch (e) {
    print('\n❌❌❌ An error occurred while writing to Firestore:');
    print(e);
  }
}

// Simple enum to match the one in the app
enum ReminderStatus { due, contacted, no_response, completed }