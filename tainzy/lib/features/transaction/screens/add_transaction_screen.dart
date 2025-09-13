// lib/features/transaction/screens/add_transaction_screen.dart
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tainzy/features/invoice/invoice_generator.dart'; // Import the generator

import 'package:tainzy/app/models/models.dart';
import 'package:tainzy/app/repositories/repositories.dart';
import 'package:tainzy/features/patient/providers/patient_providers.dart';
import 'package:tainzy/features/product/providers/product_providers.dart';
import 'package:tainzy/features/transaction/providers/transaction_providers.dart';

import '../../../app/repositories/product_repository.dart';
import '../../../app/repositories/transaction_repository.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final String? transactionId;
  const AddTransactionScreen({super.key, this.transactionId});
  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController(text: '1');
  final _discountPercentController = TextEditingController(text: '0');

  // --- NEW STATE FOR PATIENT SELECTION ---
  Patient? _selectedPatient;

  Product? _selectedProduct;
  PaymentStatus _paymentStatus = PaymentStatus.paid;
  DateTime _purchaseDate = DateTime.now();
  double _saleAmount = 0.0;
  double _discountAmount = 0.0;
  bool _isLoading = false;
  bool get _isEditing => widget.transactionId != null;
  bool _initialDataLoaded = false;
  Transaction? _transactionToEdit;


  @override
  void initState() {
    super.initState();
    _qtyController.addListener(_calculateTotals);
    _discountPercentController.addListener(_calculateTotals);
  }

  @override
  void dispose() {
    _qtyController.removeListener(_calculateTotals);
    _discountPercentController.removeListener(_calculateTotals);
    _qtyController.dispose();
    _discountPercentController.dispose();
    super.dispose();
  }

  void _populateFields(Transaction tx, List<Product> products, List<Patient> patients) {
    _qtyController.text = tx.qty.toString();
    _discountPercentController.text = tx.discountPercentage.toString();
    _paymentStatus = tx.paymentStatus;
    _purchaseDate = tx.dateOfPurchase;
    _selectedProduct = products.firstWhereOrNull((p) => p.name == tx.productName);

    // Also populate the selected patient when editing
    if (tx.patientId != null) {
      _selectedPatient = patients.firstWhereOrNull((p) => p.id == tx.patientId);
    }

    _calculateTotals();
    _initialDataLoaded = true;
  }

  void _calculateTotals() {
    if (_selectedProduct == null) return;

    final qty = int.tryParse(_qtyController.text) ?? 0;
    final discountPercent =
        double.tryParse(_discountPercentController.text) ?? 0.0;

    final totalAmount = (_selectedProduct!.price * qty);
    final discount = totalAmount * (discountPercent / 100);
    final finalAmount = totalAmount - discount;

    setState(() {
      _discountAmount = discount;
      _saleAmount = finalAmount;
    });
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedProduct == null || (_selectedPatient == null && !_isEditing)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please select a patient and a product.'),
            backgroundColor: Colors.orange));
        return;
      }
      setState(() => _isLoading = true);

      final transactionData = Transaction(
        id: widget.transactionId,
        patientId: _isEditing ? _transactionToEdit!.patientId : _selectedPatient!.id,
        // --- FIXED: Pass the required patientName ---
        patientName: _isEditing ? _transactionToEdit!.patientName : _selectedPatient!.name,
        productName: _selectedProduct!.name,
        paymentStatus: _paymentStatus,
        dateOfPurchase: _purchaseDate,
        saleAmount: _saleAmount,
        qty: int.tryParse(_qtyController.text) ?? 0,
        discountPercentage:
        double.tryParse(_discountPercentController.text) ?? 0.0,
        discountAmount: _discountAmount,
      );

      try {
        final repo = ref.read(transactionRepositoryProvider);
        if (_isEditing) {
          await repo.updateTransaction(widget.transactionId!, transactionData);
        } else {
          await repo.addTransaction(transactionData);
          // Also update stock when creating a standalone transaction
          await ref.read(productRepositoryProvider).updateStock(_selectedProduct!.id!, transactionData.qty);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Transaction ${_isEditing ? 'updated' : 'saved'} successfully!')));
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing && !_initialDataLoaded) {
      final txAsync = ref.watch(transactionsStreamProvider);
      final productsAsync = ref.watch(productsStreamProvider);
      final patientsAsync = ref.watch(patientsStreamProvider); // Load patients to find the name

      if (txAsync.hasValue && productsAsync.hasValue && patientsAsync.hasValue) {
        _transactionToEdit = txAsync.value!.firstWhere((tx) => tx.id == widget.transactionId);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _populateFields(_transactionToEdit!, productsAsync.value!, patientsAsync.value!);
            });
          }
        });
      }
    }

    final productsAsyncValue = ref.watch(productsStreamProvider);
    final patientsAsyncValue = ref.watch(patientsStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Transaction' : 'Add New Transaction')),
      body: (_isEditing && !_initialDataLoaded)
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          if (!_isEditing)
                            patientsAsyncValue.when(
                              data: (patients) {
                                return DropdownButtonFormField<Patient>(
                                  value: _selectedPatient,
                                  decoration: const InputDecoration(labelText: 'Select Patient'),
                                  isExpanded: true,
                                  items: patients.map((patient) {
                                    return DropdownMenuItem(value: patient, child: Text(patient.name));
                                  }).toList(),
                                  onChanged: (value) => setState(() => _selectedPatient = value),
                                  validator: (v) => v == null ? 'Please select a patient' : null,
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (e, st) => Text('Error loading patients: $e'),
                            )
                          else
                            TextFormField(
                              readOnly: true,
                              initialValue: _selectedPatient?.name ?? 'Loading...',
                              decoration: const InputDecoration(
                                labelText: 'Patient',
                              ),
                            ),
                          const SizedBox(height: 16),
                          productsAsyncValue.when(
                            data: (products) {
                              return DropdownButtonFormField<Product>(
                                value: _selectedProduct,
                                decoration: const InputDecoration(labelText: 'Select Product'),
                                isExpanded: true,
                                items: products.where((p) => p.stock > 0 || _isEditing).map((product) {
                                  return DropdownMenuItem(
                                      value: product,
                                      child: Text(
                                          '${product.name} (Rs ${product.price})'));
                                }).toList(),
                                onChanged: (value) => setState(() {
                                  _selectedProduct = value;
                                  _calculateTotals();
                                }),
                                validator: (v) =>
                                v == null ? 'Please select a product' : null,
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, st) => Text('Error loading products: $e'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(controller: _qtyController, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null),
                          const SizedBox(height: 16),
                          TextFormField(controller: _discountPercentController, decoration: const InputDecoration(labelText: 'Discount %', suffixText: '%'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<PaymentStatus>(
                            value: _paymentStatus,
                            decoration: const InputDecoration(labelText: 'Payment Status'),
                            items: PaymentStatus.values.map((status) {
                              return DropdownMenuItem(value: status, child: Text(status.name.replaceAll('_', ' ').toUpperCase()));
                            }).toList(),
                            onChanged: (value) => setState(() => _paymentStatus = value!),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: theme.primaryColor.withOpacity(0.05),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Transaction Summary', style: theme.textTheme.titleLarge?.copyWith(color: theme.primaryColor)),
                          const Divider(height: 20),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Discount:'), Text('- Rs ${_discountAmount.toStringAsFixed(2)}')]),
                          const SizedBox(height: 8),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Amount:', style: theme.textTheme.titleMedium), Text('Rs ${_saleAmount.toStringAsFixed(2)}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 0,
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
              onPressed: _saveTransaction,
              child: Text(_isEditing ? 'Save Changes' : 'Save Transaction')),
        ),
      ),
    );
  }
}