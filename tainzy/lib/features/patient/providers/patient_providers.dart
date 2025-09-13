// lib/features/patient/providers/patient_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/models/patient_model.dart';
import '../../../app/repositories/repositories.dart';

// 1. StreamProvider to get the real-time list of all patients from the repository.
final patientsStreamProvider = StreamProvider<List<Patient>>((ref) {
  // REFACTORED: Now depends on the abstract PatientRepository provider.
  return ref.watch(patientRepositoryProvider).getPatients();
});

// 2. StateProvider to hold the current search/filter query
final patientSearchQueryProvider = StateProvider<String>((ref) => '');

// 3. A provider that combines the stream and search query to return a filtered list
final filteredPatientsProvider = Provider<List<Patient>>((ref) {
  final patientsAsyncValue = ref.watch(patientsStreamProvider);
  final searchQuery = ref.watch(patientSearchQueryProvider);

  return patientsAsyncValue.when(
    data: (patients) {
      if (searchQuery.isEmpty) return patients;

      final query = searchQuery.toLowerCase();
      return patients.where((patient) {
        return patient.name.toLowerCase().contains(query) ||
            patient.city.toLowerCase().contains(query) ||
            patient.phoneNumber.contains(query) ||
            patient.referringDoctor.toLowerCase().contains(query);
      }).toList();
    },
    loading: () => [],
    error: (e, st) => [],
  );
});