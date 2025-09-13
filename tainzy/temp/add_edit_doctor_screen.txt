// lib/features/doctor/screens/add_edit_doctor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/models/doctor_model.dart';
import '../../../app/services/firestore_service.dart';
import '../providers/doctor_providers.dart';

class AddEditDoctorScreen extends ConsumerStatefulWidget {
  final String? doctorId;
  const AddEditDoctorScreen({super.key, this.doctorId});
  @override
  _AddEditDoctorScreenState createState() => _AddEditDoctorScreenState();
}
class _AddEditDoctorScreenState extends ConsumerState<AddEditDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _professionController = TextEditingController();
  final _qualificationController = TextEditingController();

  List<PracticeDetail> _practiceDetails = [];
  bool _isLoading = false;
  bool get _isEditing => widget.doctorId != null;
  bool _initialDataLoaded = false;

  @override
  void initState() {
    super.initState();
    if (!_isEditing && _practiceDetails.isEmpty) {
      // For new doctors, start with one empty detail card for user convenience
      _addPracticeDetail();
    }
  }

  void _populateFields(Doctor doctor) {
    _nameController.text = doctor.name;
    _professionController.text = doctor.profession;
    _qualificationController.text = doctor.qualification;
    _practiceDetails = List<PracticeDetail>.from(doctor.practiceDetails.map((pd) => PracticeDetail.fromMap(pd.toMap())));
    _initialDataLoaded = true;
  }

  void _addPracticeDetail() {
    _addOrEditPracticeDetail(); // Call the dialog to add a new one
  }

  void _addOrEditPracticeDetail({PracticeDetail? existingDetail, int? index}) async {
    final result = await showDialog<PracticeDetail>(
      context: context,
      builder: (context) => _PracticeDetailDialog(practiceDetail: existingDetail),
    );

    if (result != null) {
      setState(() {
        if (index != null) {
          _practiceDetails[index] = result;
        } else {
          _practiceDetails.add(result);
        }
      });
    }
  }

  void _removePracticeDetail(int index) {
    setState(() => _practiceDetails.removeAt(index));
  }


  @override
  void dispose() {
    _nameController.dispose();
    _professionController.dispose();
    _qualificationController.dispose();
    super.dispose();
  }

  Future<void> _saveDoctor() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final doctorData = Doctor(
        id: widget.doctorId,
        name: _nameController.text.trim(),
        profession: _professionController.text.trim(),
        qualification: _qualificationController.text.trim(),
        practiceDetails: _practiceDetails,
      );

      try {
        if (_isEditing) {
          await ref.read(firestoreServiceProvider).updateDoctor(widget.doctorId!, doctorData);
        } else {
          await ref.read(firestoreServiceProvider).addDoctor(doctorData);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Doctor Profile ${ _isEditing ? 'Updated' : 'Created' } Successfully.')));
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_isEditing && !_initialDataLoaded) {
      final doctorsAsync = ref.watch(doctorsStreamProvider);
      if (doctorsAsync.hasValue) {
        final doctorToEdit = doctorsAsync.value!.firstWhere((d) => d.id == widget.doctorId);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _populateFields(doctorToEdit);
            });
          }
        });
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Doctor Info' : 'Add Doctor Info')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: (_isEditing && !_initialDataLoaded)
                ? const Center(child: CircularProgressIndicator())
                : Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Doctor Information', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 24),
                    TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name (required)'), validator: (v) => v!.isEmpty ? 'This field is required' : null),
                    const SizedBox(height: 20),
                    LayoutBuilder(builder: (context, constraints) {
                      if (constraints.maxWidth < 600) {
                        return Column(
                          children: [
                            TextFormField(controller: _professionController, decoration: const InputDecoration(labelText: 'Profession')),
                            const SizedBox(height: 20),
                            TextFormField(controller: _qualificationController, decoration: const InputDecoration(labelText: 'Qualification')),
                          ],
                        );
                      }
                      return Row(children: [
                        Expanded(child: TextFormField(controller: _professionController, decoration: const InputDecoration(labelText: 'Profession'))),
                        const SizedBox(width: 20),
                        Expanded(child: TextFormField(controller: _qualificationController, decoration: const InputDecoration(labelText: 'Qualification'))),
                      ]);
                    }),
                    const Divider(height: 48),
                    Text('Practice Details', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),

                    if (_practiceDetails.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(child: Text("No practice details added yet.", style: TextStyle(color: Colors.grey))),
                      ),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _practiceDetails.length,
                      itemBuilder: (context, index) {
                        final detail = _practiceDetails[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(detail.hospitalName),
                            subtitle: Text("${detail.days}\n${detail.timing}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit_outlined), onPressed: ()=> _addOrEditPracticeDetail(existingDetail: detail, index: index)),
                                IconButton(icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error), onPressed: ()=> _removePracticeDetail(index)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Practice Location'),
                        onPressed: _addPracticeDetail,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                        onPressed: _saveDoctor,
                        child: Text(_isEditing ? 'Save Changes' : 'Save Doctor Profile'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PracticeDetailDialog extends StatefulWidget {
  final PracticeDetail? practiceDetail;
  const _PracticeDetailDialog({this.practiceDetail});

  @override
  State<_PracticeDetailDialog> createState() => _PracticeDetailDialogState();
}

class _PracticeDetailDialogState extends State<_PracticeDetailDialog> {
  final _formKey = GlobalKey<FormState>();
  final _hospitalController = TextEditingController();
  final Set<String> _selectedDays = {};
  String? _fromTime;
  String? _toTime;


  late final List<String> _timeSlots;

  @override
  void initState() {
    super.initState();
    _timeSlots = List.generate(48, (index) {
      final hour = index ~/ 2;
      final minute = (index % 2) * 30;
      final time = TimeOfDay(hour: hour, minute: minute);
      final hourString = time.hour.toString().padLeft(2, '0');
      final minuteString = time.minute.toString().padLeft(2, '0');
      return '$hourString:$minuteString';
    });

    if (widget.practiceDetail != null) {
      _hospitalController.text = widget.practiceDetail!.hospitalName;
      final days = widget.practiceDetail!.days.split(", ").where((d) => d.isNotEmpty);
      _selectedDays.addAll(days);

      final times = widget.practiceDetail!.timing.split(" - ");
      if (times.length == 2) {
        if (_timeSlots.contains(times[0])) _fromTime = times[0];
        if (_timeSlots.contains(times[1])) _toTime = times[1];
      }
    }
  }

  void _confirm() {
    if (_formKey.currentState!.validate()) {
      final daysList = _selectedDays.toList();
      const dayOrder = {"Mon": 1,"Tue": 2,"Wed": 3,"Thu": 4,"Fri": 5,"Sat": 6,"Sun": 7};
      daysList.sort((a, b) => dayOrder[a]!.compareTo(dayOrder[b]!));

      final newDetail = PracticeDetail(
        hospitalName: _hospitalController.text.trim(),
        days: daysList.join(', '),
        timing: '${_fromTime ?? 'N/A'} - ${_toTime ?? 'N/A'}',
      );
      Navigator.of(context).pop(newDetail);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.practiceDetail == null ? 'Add Practice Detail' : 'Edit Practice Detail'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _hospitalController,
                decoration: const InputDecoration(labelText: 'Hospital Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              const Text('Days'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
                  return FilterChip(
                    label: Text(day),
                    selected: _selectedDays.contains(day),
                    onSelected: (isSelected) {
                      setState(() {
                        if (isSelected) _selectedDays.add(day);
                        else _selectedDays.remove(day);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 300;
                final fromDropdown = DropdownButtonFormField<String>(
                  value: _fromTime,
                  decoration: const InputDecoration(labelText: 'From'),
                  items: _timeSlots.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) => setState(() => _fromTime = val),
                );
                final toDropdown = DropdownButtonFormField<String>(
                  value: _toTime,
                  decoration: const InputDecoration(labelText: 'To'),
                  items: _timeSlots.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) => setState(() => _toTime = val),
                );

                if (isNarrow) {
                  return Column(mainAxisSize: MainAxisSize.min, children: [
                    fromDropdown,
                    const SizedBox(height: 16),
                    toDropdown
                  ]);
                } else {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: fromDropdown),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 20.0),
                        child: Text('-'),
                      ),
                      Expanded(child: toDropdown),
                    ],
                  );
                }
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _confirm, child: const Text('Confirm')),
      ],
    );
  }
}