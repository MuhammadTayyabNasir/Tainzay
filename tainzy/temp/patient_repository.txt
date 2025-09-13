// lib/app/repositories/patient_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository(FirebaseFirestore.instance);
});

class PatientRepository {
  final FirebaseFirestore _db;
  PatientRepository(this._db);

  CollectionReference<Patient> get _patientsRef =>
      _db.collection('patients').withConverter<Patient>(
        fromFirestore: (snapshot, _) => Patient.fromFirestore(snapshot),
        toFirestore: (patient, _) => patient.toFirestore(),
      );

  Stream<List<Patient>> getPatients() =>
      _patientsRef.snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

  Future<DocumentReference> addPatientAndGetRef(Patient patient) async =>
      _db.collection('patients').add(patient.toFirestore());

  Future<void> updatePatient(String id, Patient patient) =>
      _patientsRef.doc(id).set(patient, SetOptions(merge: true));

  Future<void> deletePatient(String id) => _patientsRef.doc(id).delete();
}