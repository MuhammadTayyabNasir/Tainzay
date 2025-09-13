import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/models/doctor_model.dart';
import '../../../app/models/patient_model.dart';
import '../../../app/models/transaction_model.dart';
import '../../../app/services/firestore_service.dart';
import '../../patient/providers/patient_providers.dart' hide firestoreServiceProvider;
import '../../transaction/providers/transaction_providers.dart';

// Helper class to bundle patient with their latest transaction status
class PatientWithStatus {
  final Patient patient;
  final PaymentStatus? lastStatus;
  PatientWithStatus({required this.patient, this.lastStatus});
}

final doctorsStreamProvider = StreamProvider<List<Doctor>>((ref) {
  return ref.watch(firestoreServiceProvider).getDoctors();
});

final doctorSearchQueryProvider = StateProvider<String>((ref) => '');

final selectedDoctorProvider = StateProvider<Doctor?>((ref) => null);

// Provider for the status filter chips (All, Pending, Completed)
final paymentStatusFilterProvider = StateProvider<PaymentStatus?>((ref) => null);


final filteredDoctorsProvider = Provider<List<Doctor>>((ref) {
  final doctors = ref.watch(doctorsStreamProvider).asData?.value ?? [];
  final query = ref.watch(doctorSearchQueryProvider).toLowerCase();

  if (query.isEmpty) return doctors;

  return doctors.where((doctor) {
    return doctor.name.toLowerCase().contains(query) ||
        doctor.profession.toLowerCase().contains(query) ||
        doctor.qualification.toLowerCase().contains(query);
  }).toList();
});


// New complex provider to get patients for a doctor and enrich them with their latest payment status
final affiliatedPatientsWithStatusProvider = Provider<List<PatientWithStatus>>((ref) {
  final selectedDoctor = ref.watch(selectedDoctorProvider);
  final allPatients = ref.watch(patientsStreamProvider).asData?.value ?? [];
  final allTransactions = ref.watch(transactionsStreamProvider).asData?.value ?? [];

  if (selectedDoctor == null) return [];

  // 1. Get all patients for the selected doctor
  final doctorPatients = allPatients
      .where((p) => p.referringDoctor == selectedDoctor.name)
      .toList();

  // 2. For each patient, find their latest transaction
  return doctorPatients.map((patient) {
    final patientTransactions = allTransactions
        .where((t) => t.patientId == patient.id)
        .sortedBy<DateTime>((t) => t.dateOfPurchase)
        .toList();

    return PatientWithStatus(
      patient: patient,
      lastStatus: patientTransactions.isEmpty ? null : patientTransactions.last.paymentStatus,
    );
  }).toList();
});




