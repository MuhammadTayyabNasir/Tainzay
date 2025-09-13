// lib/features/patient/screens/patient_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_builder/responsive_builder.dart';
import '../../../app/models/models.dart';
import '../../../app/repositories/repositories.dart';
import '../providers/patient_providers.dart';

class PatientListScreen extends ConsumerWidget {
  const PatientListScreen({super.key});

  // --- FULLY IMPLEMENTED DELETE LOGIC ---
  Future<void> _deletePatient(BuildContext context, WidgetRef ref, Patient patient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete patient "${patient.name}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(patientRepositoryProvider).deletePatient(patient.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Patient deleted successfully.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting patient: $e'), backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPatients = ref.watch(patientsStreamProvider);
    final filteredPatients = ref.watch(filteredPatientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Records'),
        actions: [
          SizedBox(
            width: 250,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search records...',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
                onChanged: (query) {
                  ref.read(patientSearchQueryProvider.notifier).state = query;
                },
              ),
            ),
          )
        ],
      ),
      body: asyncPatients.when(
        data: (_) => ScreenTypeLayout.builder(
          mobile: (context) => _PatientListView(
            patients: filteredPatients,
            onDelete: (patient) => _deletePatient(context, ref, patient),
          ),
          desktop: (context) => _PatientDataTable(
            patients: filteredPatients,
            onDelete: (patient) => _deletePatient(context, ref, patient),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('// ERROR: $error')),
      ),
    );
  }
}

// --- DESKTOP VIEW (with onDelete callback) ---
class _PatientDataTable extends StatelessWidget {
  const _PatientDataTable({required this.patients, required this.onDelete});
  final List<Patient> patients;
  final Function(Patient) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (patients.isEmpty) {
      return const Center(child: Text('// NO RECORDS FOUND'));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        child: DataTable(
          headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          columns: const [
            DataColumn(label: Text('NAME')),
            DataColumn(label: Text('PHONE')),
            DataColumn(label: Text('CITY')),
            DataColumn(label: Text('DOCTOR')),
            DataColumn(label: Text('ACTIONS')),
          ],
          rows: patients.map((patient) {
            return DataRow(
              cells: [
                DataCell(Text(patient.name)),
                DataCell(Text(patient.phoneNumber)),
                DataCell(Text(patient.city)),
                DataCell(Text(patient.referringDoctor)),
                DataCell(
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'edit') {
                        context.go('/patient/${patient.id}/edit');
                      } else if (value == 'delete') {
                        onDelete(patient); // Use the callback
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit Record')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete Record')),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// --- MOBILE VIEW (with onDelete callback) ---
class _PatientListView extends StatelessWidget {
  const _PatientListView({required this.patients, required this.onDelete});
  final List<Patient> patients;
  final Function(Patient) onDelete;

  @override
  Widget build(BuildContext context) {
    if (patients.isEmpty) {
      return const Center(child: Text('// NO RECORDS FOUND'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80), // Padding for FAB
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final patient = patients[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              foregroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.person_outline),
            ),
            title: Text(patient.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${patient.city}\nReferred by: ${patient.referringDoctor}'),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  context.go('/patient/${patient.id}/edit');
                } else if (value == 'delete') {
                  onDelete(patient); // Use the callback
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Record')),
                const PopupMenuItem(value: 'delete', child: Text('Delete Record')),
              ],
            ),
          ),
        );
      },
    );
  }
}