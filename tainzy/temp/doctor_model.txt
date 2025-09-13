// lib/app/models/doctor_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PracticeDetail {
  String hospitalName;
  String days;
  String timing;

  PracticeDetail({
    required this.hospitalName,
    required this.days,
    required this.timing,
  });

  factory PracticeDetail.fromMap(Map<String, dynamic> map) {
    return PracticeDetail(
      hospitalName: map['hospitalName'] ?? '',
      days: map['days'] ?? '',
      timing: map['timing'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hospitalName': hospitalName,
      'days': days,
      'timing': timing,
    };
  }
}

class Doctor {
  final String? id;
  final String name;
  final String profession;
  final String qualification;
  final List<PracticeDetail> practiceDetails;

  Doctor({
    this.id,
    required this.name,
    required this.profession,
    required this.qualification,
    required this.practiceDetails,
  });

  factory Doctor.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    final practiceDetailsData = data['practiceDetails'] as List<dynamic>? ?? [];
    return Doctor(
      id: snapshot.id,
      name: data['name'] ?? '',
      profession: data['profession'] ?? '',
      qualification: data['qualification'] ?? '',
      practiceDetails: practiceDetailsData
          .map((detail) => PracticeDetail.fromMap(detail as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'profession': profession,
      'qualification': qualification,
      'practiceDetails': practiceDetails.map((detail) => detail.toMap()).toList(),
    };
  }
}