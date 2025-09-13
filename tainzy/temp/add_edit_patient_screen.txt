// lib/features/patient/screens/add_edit_patient_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:responsive_builder/responsive_builder.dart';
import '../../../app/models/models.dart';
import '../../../app/repositories/product_repository.dart';
import '../../../app/repositories/reminder_repository.dart';
import '../../../app/repositories/repositories.dart';
import '../../../app/repositories/transaction_repository.dart';
import '../../doctor/providers/doctor_providers.dart';
import '../../product/providers/product_providers.dart';
import '../providers/patient_providers.dart';
import 'pakistan_cities.dart';

class AddEditPatientScreen extends ConsumerStatefulWidget {
  final String? patientId;
  const AddEditPatientScreen({super.key, this.patientId});

  @override
  _AddEditPatientScreenState createState() => _AddEditPatientScreenState();
}

class _AddEditPatientScreenState extends ConsumerState<AddEditPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool get _isEditing => widget.patientId != null;
  bool _initialDataLoaded = false;
  Patient? _patientToEdit;
  bool _isCalculating = false; // Flag to prevent calculation loops

  // Patient Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _doctorController = TextEditingController();
  final _noteController = TextEditingController();
  Doctor? _selectedDoctor;

  // Transaction Controllers & State
  final _productController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _discountPercentController = TextEditingController(text: '0');
  final _basePriceController = TextEditingController();
  final _perUnitSalePriceController = TextEditingController();

  Product? _selectedProduct;
  PaymentStatus _paymentStatus = PaymentStatus.paid;
  double _saleAmount = 0.0;
  double _discountAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _qtyController.addListener(_recalculateTotals);
    _discountPercentController.addListener(_updateSalePriceFromDiscount);
    _perUnitSalePriceController.addListener(_updateDiscountFromSalePrice);
  }

  @override
  void dispose() {
    _qtyController.removeListener(_recalculateTotals);
    _discountPercentController.removeListener(_updateSalePriceFromDiscount);
    _perUnitSalePriceController.removeListener(_updateDiscountFromSalePrice);
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _doctorController.dispose();
    _noteController.dispose();
    _productController.dispose();
    _qtyController.dispose();
    _discountPercentController.dispose();
    _basePriceController.dispose();
    _perUnitSalePriceController.dispose();
    super.dispose();
  }

  void _populateFields(Patient patient, List<Doctor> doctors) {
    _nameController.text = patient.name;
    _phoneController.text = patient.phoneNumber;
    _cityController.text = patient.city;
    _noteController.text = patient.note ?? '';

    final doctor = doctors.firstWhere((d) => d.name == patient.referringDoctor,
        orElse: () => Doctor(name: patient.referringDoctor, profession: '', qualification: '', practiceDetails: []));
    _selectedDoctor = doctor;
    _doctorController.text = doctor.name;
    _initialDataLoaded = true;
  }

  void _onProductSelected(Product selection) {
    setState(() {
      _selectedProduct = selection;
      _basePriceController.text = selection.price.toStringAsFixed(2);
      _updateSalePriceFromDiscount();
    });
  }

  void _updateSalePriceFromDiscount() {
    if (_isCalculating) return;
    _isCalculating = true;

    if (_selectedProduct != null) {
      final discountPercent = double.tryParse(_discountPercentController.text) ?? 0.0;
      final salePrice = _selectedProduct!.price * (1 - (discountPercent / 100));
      _perUnitSalePriceController.text = salePrice.toStringAsFixed(2);
      _recalculateTotals();
    }
    _isCalculating = false;
  }

  void _updateDiscountFromSalePrice() {
    if (_isCalculating) return;
    _isCalculating = true;

    if (_selectedProduct != null && _selectedProduct!.price > 0) {
      final salePrice = double.tryParse(_perUnitSalePriceController.text) ?? 0.0;
      final discount = _selectedProduct!.price - salePrice;
      if (discount >= 0) {
        final discountPercent = (discount / _selectedProduct!.price) * 100;
        _discountPercentController.text = discountPercent.toStringAsFixed(2);
      }
      _recalculateTotals();
    }
    _isCalculating = false;
  }

  void _recalculateTotals() {
    final qty = int.tryParse(_qtyController.text) ?? 0;
    final perUnitSalePrice = double.tryParse(_perUnitSalePriceController.text) ?? 0.0;
    final basePrice = double.tryParse(_basePriceController.text) ?? 0.0;

    setState(() {
      _saleAmount = perUnitSalePrice * qty;
      _discountAmount = (basePrice - perUnitSalePrice) * qty;
    });
  }

  Future<void> _saveData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        if (_isEditing) {
          await _updatePatient();
        } else {
          await _createPatientWithTransaction();
        }
      } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Theme.of(context).colorScheme.error,));
      } finally {
        if(mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updatePatient() async {
    final updatedPatient = Patient(
      id: widget.patientId,
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      city: _cityController.text.trim(),
      referringDoctor: _selectedDoctor!.name,
      note: _noteController.text.trim(),
      dateAdded: _patientToEdit?.dateAdded,
    );
    await ref.read(patientRepositoryProvider).updatePatient(widget.patientId!, updatedPatient);
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Patient updated successfully.')));
      context.go('/patients');
    }
  }

  Future<void> _createPatientWithTransaction() async {
    final productRepo = ref.read(productRepositoryProvider);
    final reminderRepo = ref.read(reminderRepositoryProvider);
    final patientRepo = ref.read(patientRepositoryProvider);
    final transactionRepo = ref.read(transactionRepositoryProvider);

    if (_selectedProduct != null && _selectedProduct!.stock < (int.tryParse(_qtyController.text) ?? 1)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Not enough stock for ${_selectedProduct!.name}. Available: ${_selectedProduct!.stock}'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
      setState(() => _isLoading = false);
      return;
    }

    final patient = Patient(
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      city: _cityController.text.trim(),
      referringDoctor: _selectedDoctor!.name,
      note: _noteController.text.trim(),
      dateAdded: Timestamp.now(),
    );
    final patientRef = await patientRepo.addPatientAndGetRef(patient);
    final newPatientId = patientRef.id;

    final transaction = Transaction(
      patientId: newPatientId,
      productName: _selectedProduct!.name,
      patientName: patient.name, // Pass patient's name here
      paymentStatus: _paymentStatus,
      dateOfPurchase: DateTime.now(),
      saleAmount: _saleAmount,
      qty: int.tryParse(_qtyController.text) ?? 1,
      discountPercentage: double.tryParse(_discountPercentController.text) ?? 0.0,
      discountAmount: _discountAmount,
    );

    final txRef = await transactionRepo.addTransaction(transaction);

    await productRepo.updateStock(_selectedProduct!.id!, transaction.qty);

    if (_selectedProduct!.reminderUnit != ReminderUnit.none && _selectedProduct!.reminderInterval > 0) {
      final now = DateTime.now();
      late DateTime nextDueDate;
      switch (_selectedProduct!.reminderUnit) {
        case ReminderUnit.days:
          nextDueDate = now.add(Duration(days: _selectedProduct!.reminderInterval));
          break;
        case ReminderUnit.weeks:
          nextDueDate = now.add(Duration(days: _selectedProduct!.reminderInterval * 7));
          break;
        case ReminderUnit.months:
          nextDueDate = DateTime(now.year, now.month + _selectedProduct!.reminderInterval, now.day);
          break;
        case ReminderUnit.none:
          break;
      }

      final newReminder = Reminder(
        patientId: newPatientId,
        patientName: patient.name,
        productName: _selectedProduct!.name,
        transactionId: txRef.id,
        lastPurchaseDate: now,
        nextDueDate: nextDueDate,
        status: ReminderStatus.due,
      );
      await reminderRepo.addReminder(newReminder);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Patient & Transaction Created Successfully.')));
      context.go('/patients');
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).primaryColor)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing && !_initialDataLoaded) {
      final patientsAsync = ref.watch(patientsStreamProvider);
      final doctorsAsync = ref.watch(doctorsStreamProvider);
      if (patientsAsync.hasValue && doctorsAsync.hasValue) {
        _patientToEdit = patientsAsync.value!.firstWhere((p) => p.id == widget.patientId);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _populateFields(_patientToEdit!, doctorsAsync.value!));
        });
      }
    }

    final theme = Theme.of(context);
    final doctorsAsync = ref.watch(doctorsStreamProvider);
    final productsAsync = ref.watch(productsStreamProvider);
    final pkrFormat = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs ');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Patient Record' : 'Create New Patient Record'),
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.canPop() ? context.pop() : context.go('/patients')),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.primaryColor.withOpacity(0.4)),
                ),
                child: (_isEditing && !_initialDataLoaded)
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionHeader('Patient Information'),
                    const SizedBox(height: 16),
                    _ResponsiveFormRow(
                      children: [
                        TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Patient Full Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
                        TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Contact Phone'), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Required' : null),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _ResponsiveFormRow(
                      children: [
                        Autocomplete<String>(
                          initialValue: TextEditingValue(text: _cityController.text),
                          optionsBuilder: (v) => v.text == '' ? const Iterable.empty() : pakistanCities.where((o) => o.toLowerCase().contains(v.text.toLowerCase())),
                          onSelected: (s) => _cityController.text = s,
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            return TextFormField(controller: controller, focusNode: focusNode, onChanged: (v) => _cityController.text = v, decoration: const InputDecoration(labelText: 'City of Residence'), validator: (v) => v!.isEmpty ? 'Required' : null);
                          },
                        ),
                        doctorsAsync.when(
                            data: (doctors) => Autocomplete<Doctor>(
                              initialValue: TextEditingValue(text: _doctorController.text),
                              displayStringForOption: (o) => o.name,
                              optionsBuilder: (v) => v.text == '' ? const Iterable.empty() : doctors.where((d) => d.name.toLowerCase().contains(v.text.toLowerCase())),
                              onSelected: (s) => setState(() {
                                _selectedDoctor = s;
                                _doctorController.text = s.name;
                              }),
                              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                return TextFormField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(labelText: 'Referring Doctor'),
                                  validator: (v) => _selectedDoctor == null ? 'Please select a valid doctor.' : null,
                                );
                              },
                            ),
                            loading: () => TextFormField(readOnly: true, decoration: const InputDecoration(labelText: 'Referring Doctor', hintText: 'Loading...')),
                            error: (e, s) => TextFormField(readOnly: true, decoration: const InputDecoration(labelText: 'Referring Doctor', errorText: 'Could not load doctors'))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(controller: _noteController, decoration: const InputDecoration(labelText: 'Custom Note (Optional)'), maxLines: 2),

                    if (!_isEditing) ...[
                      _buildSectionHeader('Initial Transaction Details'),
                      const SizedBox(height: 16),
                      _ResponsiveFormRow(
                        children: [
                          productsAsync.when(
                              data: (products) => Autocomplete<Product>(
                                displayStringForOption: (o) => '${o.name} (Stock: ${o.stock})',
                                optionsBuilder: (v) => v.text == '' ? const Iterable.empty() : products.where((p) => p.name.toLowerCase().contains(v.text.toLowerCase()) && p.stock > 0),
                                onSelected: (s) => _onProductSelected(s),
                                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                  return TextFormField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    decoration: const InputDecoration(labelText: 'Product Name'),
                                    validator: (v) => _selectedProduct == null && !_isEditing ? 'Please select a product.' : null,
                                  );
                                },
                              ),
                              loading: () => TextFormField(readOnly: true, decoration: const InputDecoration(labelText: 'Product Name', hintText: 'Loading...')),
                              error: (e, s) => TextFormField(readOnly: true, decoration: const InputDecoration(labelText: 'Product Name', errorText: 'Could not load products'))),
                          TextFormField(readOnly: true, controller: _basePriceController, decoration: const InputDecoration(labelText: 'Base Price', prefixText: 'Rs '))
                        ],
                      ),
                      const SizedBox(height: 20),
                      _ResponsiveFormRow(
                        children: [
                          TextFormField(controller: _qtyController, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null),
                          TextFormField(controller: _perUnitSalePriceController, decoration: const InputDecoration(labelText: 'Sale Price/Unit', prefixText: 'Rs '), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]),
                          TextFormField(controller: _discountPercentController, decoration: const InputDecoration(labelText: 'Discount %', suffixText: '%'), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<PaymentStatus>(
                              value: _paymentStatus,
                              decoration: const InputDecoration(labelText: 'Payment Status'),
                              items: PaymentStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.replaceAll('_', ' ').toUpperCase()))).toList(),
                              onChanged: (value) => setState(() => _paymentStatus = value!),
                            ),
                          ),
                          Expanded(child: Container()),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Card(
                        color: theme.primaryColor.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Sale Amount:', style: theme.textTheme.titleMedium),
                              Text(pkrFormat.format(_saleAmount), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _isLoading ? const CircularProgressIndicator() : ElevatedButton.icon(onPressed: _saveData, icon: const Icon(Icons.save_alt_outlined), label: Text(_isEditing ? 'Save Changes' : 'Save Record & Transaction')),
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

/// A helper widget that displays children in a Row on wide screens
/// and a Column on narrow screens.
class _ResponsiveFormRow extends StatelessWidget {
  final List<Widget> children;
  final double breakpoint;
  final double spacing;

  const _ResponsiveFormRow({
    required this.children,
    this.breakpoint = 650.0,
    this.spacing = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          // Use a Column for narrow screens
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children
                .map((child) => Padding(
              padding: EdgeInsets.only(bottom: spacing),
              child: child,
            ))
                .toList(),
          );
        } else {
          // Use a Row for wide screens
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                Expanded(child: children[i]),
                if (i < children.length - 1) SizedBox(width: spacing),
              ]
            ],
          );
        }
      },
    );
  }
}