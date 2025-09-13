// lib/features/doctor/screens/doctor_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:responsive_builder/responsive_builder.dart';
import '../../../app/models/doctor_model.dart';
import '../../../app/models/patient_model.dart';
import '../../../app/models/transaction_model.dart';
import '../../../app/services/firestore_service.dart';
import '../providers/doctor_providers.dart';


class DoctorListScreen extends ConsumerWidget {
  const DoctorListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveBuilder(
      builder: (context, sizingInfo) {
        if (sizingInfo.isMobile) {
          // On mobile, just show the list. Tapping an item should navigate to a detail page.
          // For simplicity, we'll just show the list for now.
          return _DoctorList();
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 320, child: _DoctorList()),
            const VerticalDivider(thickness: 1, width: 1),
            const Expanded(child: _DoctorDetailView()),
          ],
        );
      },
    );
  }
}

class _DoctorList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncDoctors = ref.watch(doctorsStreamProvider);
    final filteredDoctors = ref.watch(filteredDoctorsProvider);
    final selectedDoctor = ref.watch(selectedDoctorProvider);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
                decoration: const InputDecoration(hintText: 'Search Doctor...', prefixIcon: Icon(Icons.search)),
                onChanged: (query) => ref.read(doctorSearchQueryProvider.notifier).state = query),
          ),
          const Divider(height: 1),
          Expanded(
            child: asyncDoctors.when(
              data: (_) {
                if (filteredDoctors.isEmpty) return const Center(child: Text('No doctors found.'));
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  itemCount: filteredDoctors.length,
                  itemBuilder: (context, index) {
                    final doctor = filteredDoctors[index];
                    final isSelected = selectedDoctor?.id == doctor.id;
                    return ResponsiveBuilder(
                      builder: (context, sizingInfo) {
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          color: isSelected && !sizingInfo.isMobile ? theme.primaryColor.withOpacity(0.1) : Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.primaryColor.withOpacity(0.1),
                              child: Icon(Icons.medical_services_outlined, color: theme.primaryColor),
                            ),
                            title: Text(doctor.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(doctor.profession, maxLines: 1, overflow: TextOverflow.ellipsis),
                            selected: isSelected && !sizingInfo.isMobile,
                            onTap: () {
                              if (sizingInfo.isMobile) {
                                // On mobile, navigate to the dedicated detail screen
                                context.go('/doctor/${doctor.id}');
                              } else {
                                // On desktop, update the provider to show details in the side pane
                                ref.read(selectedDoctorProvider.notifier).state = doctor;
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
class _DoctorDetailViewState extends ConsumerState<_DoctorDetailView> {
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  String _patientSearchQuery = '';

  Future<void> _deleteDoctor(Doctor doctor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete Dr. ${doctor.name}? This will not delete affiliated patients but will remove the reference.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        ref.read(selectedDoctorProvider.notifier).state = null; // Deselect first
        await ref.read(firestoreServiceProvider).deleteDoctor(doctor.id!);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Doctor deleted successfully.')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting doctor: $e')));
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedDoctor = ref.watch(selectedDoctorProvider);
    final statusFilter = ref.watch(paymentStatusFilterProvider);
    final patientsWithStatus = ref.watch(affiliatedPatientsWithStatusProvider);

    if (selectedDoctor == null) {
      return const Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('Select a doctor to view their details.'),
        ],
      ));
    }

    // Filter and sort logic remains the same
    List<PatientWithStatus> filteredList = patientsWithStatus;
    if (statusFilter != null) {
      filteredList = filteredList.where((p) => p.lastStatus == statusFilter).toList();
    }
    if (_patientSearchQuery.isNotEmpty) {
      filteredList = filteredList.where((p) => p.patient.name.toLowerCase().contains(_patientSearchQuery.toLowerCase())).toList();
    }
    filteredList.sort((a, b) {
      int result;
      final aValueDate = a.patient.dateAdded?.toDate() ?? DateTime(1900);
      final bValueDate = b.patient.dateAdded?.toDate() ?? DateTime(1900);
      switch (_sortColumnIndex) {
        case 0: result = a.patient.name.toLowerCase().compareTo(b.patient.name.toLowerCase()); break;
        case 1: result = aValueDate.compareTo(bValueDate); break;
        default: result = 0;
      }
      return _sortAscending ? result : -result;
    });

    final totalCount = patientsWithStatus.length;
    final completedCount = patientsWithStatus.where((p) => p.lastStatus == PaymentStatus.paid).length;
    final pendingCount = patientsWithStatus.where((p) => p.lastStatus == PaymentStatus.pending).length;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(selectedDoctor.name, style: theme.textTheme.headlineMedium, overflow: TextOverflow.ellipsis),
                    if(selectedDoctor.qualification.isNotEmpty)
                      Text(selectedDoctor.qualification, style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Edit Doctor',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => context.go('/doctor/${selectedDoctor.id}/edit'),
                  ),
                  IconButton(
                    tooltip: 'Delete Doctor',
                    icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                    onPressed: () => _deleteDoctor(selectedDoctor),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              _StatChip(label: 'Total Patients', value: totalCount.toString(), isSelected: statusFilter == null, onTap: () => ref.read(paymentStatusFilterProvider.notifier).state = null),
              _StatChip(label: 'Paid', value: completedCount.toString(), isSelected: statusFilter == PaymentStatus.paid, onTap: () => ref.read(paymentStatusFilterProvider.notifier).state = PaymentStatus.paid),
              _StatChip(label: 'Pending', value: pendingCount.toString(), isSelected: statusFilter == PaymentStatus.pending, onTap: () => ref.read(paymentStatusFilterProvider.notifier).state = PaymentStatus.pending),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(8),
                color: theme.colorScheme.surface,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: filteredList.isEmpty
                    ? const Center(child: Text("No Affiliated Patients", style: TextStyle(color: Colors.grey, fontSize: 16)))
                // **[CHANGE]**: Wrapped the vertical scroll view with a horizontal one for the DataTable.
                    : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      sortColumnIndex: _sortColumnIndex,
                      sortAscending: _sortAscending,
                      headingRowColor: MaterialStateProperty.all(theme.scaffoldBackgroundColor),
                      columns: [
                        DataColumn(label: const Text('PATIENT NAME'), onSort: (i, asc) => setState(() { _sortColumnIndex = i; _sortAscending = asc; })),
                        DataColumn(label: const Text('DATE ADDED'), onSort: (i, asc) => setState(() { _sortColumnIndex = i; _sortAscending = asc; })),
                        const DataColumn(label: Text('LAST PAYMENT')),
                      ],
                      rows: filteredList.map((pws) {
                        final date = pws.patient.dateAdded?.toDate();
                        return DataRow(
                          cells: [
                            DataCell(Text(pws.patient.name)),
                            DataCell(Text(date != null ? DateFormat.yMMMd().format(date) : 'N/A')),
                            DataCell(Text(pws.lastStatus?.name.toUpperCase().replaceAll('_', ' ') ?? 'N/A')),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorDetailView extends ConsumerStatefulWidget {
  const _DoctorDetailView();

  @override
  ConsumerState<_DoctorDetailView> createState() => _DoctorDetailViewState();
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatChip({required this.label, required this.value, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ActionChip(
      onPressed: onTap,
      elevation: 0,
      backgroundColor: isSelected ? theme.primaryColor.withOpacity(0.2) : theme.colorScheme.surface,
      side: BorderSide(color: isSelected ? theme.primaryColor : theme.dividerColor),
      avatar: CircleAvatar(backgroundColor: Colors.transparent, child: Text(value, style: TextStyle(color: isSelected ? theme.primaryColor : theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold))),
      label: Text(label),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    );
  }
}