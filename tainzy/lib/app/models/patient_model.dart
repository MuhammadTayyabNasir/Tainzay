// lib/app/models/patient_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Patient {
  final String? id;
  final String name;
  final String phoneNumber;
  final String city;
  final String referringDoctor;
  final String? note;
  final Timestamp? dateAdded; // Added field

  Patient({
    this.id,
    required this.name,
    required this.phoneNumber,
    required this.city,
    required this.referringDoctor,
    this.note,
    this.dateAdded, // Added to constructor
  });

  // Factory constructor to create a Patient from a Firestore document
  factory Patient.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    return Patient(
      id: snapshot.id,
      name: data?['name'] ?? '',
      phoneNumber: data?['phoneNumber'] ?? '',
      city: data?['city'] ?? '',
      referringDoctor: data?['referringDoctor'] ?? '',
      note: data?['note'],
      dateAdded: data?['dateAdded'], // Added mapping
    );
  }

  // Method to convert Patient instance to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'city': city,
      'referringDoctor': referringDoctor,
      if (note != null && note!.isNotEmpty) 'note': note,
      'dateAdded': dateAdded ?? FieldValue.serverTimestamp(), // Set current time on creation
    };
  }
}