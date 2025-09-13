// lib/features/product/screens/add_edit_product_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tainzy/app/repositories/repositories.dart';
import 'package:tainzy/features/product/providers/product_providers.dart';
import '../../../app/models/models.dart';
import '../../../app/repositories/product_repository.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final String? productId;
  const AddEditProductScreen({super.key, this.productId});
  @override
  _AddEditProductScreenState createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _batchController = TextEditingController();
  final _priceController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _ingredientController = TextEditingController();
  final _stockController = TextEditingController();
  final _reminderIntervalController = TextEditingController();

  List<String> _activeIngredients = [];
  ProductType _selectedType = ProductType.injection;
  ReminderUnit _selectedReminderUnit = ReminderUnit.none;
  DateTime? _expiryDate;
  bool _isLoading = false;
  bool get _isEditing => widget.productId != null;
  bool _initialDataLoaded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _batchController.dispose();
    _priceController.dispose();
    _manufacturerController.dispose();
    _ingredientController.dispose();
    _stockController.dispose();
    _reminderIntervalController.dispose();
    super.dispose();
  }

  void _populateFields(Product product) {
    _nameController.text = product.name;
    _batchController.text = product.batch;
    _priceController.text = product.price.toString();
    _manufacturerController.text = product.manufacturer;
    _activeIngredients = List<String>.from(product.activeIngredients);
    _selectedType = product.type;
    _expiryDate = product.expiryDate;
    _stockController.text = product.stock.toString();
    _selectedReminderUnit = product.reminderUnit;
    if (product.reminderInterval > 0) {
      _reminderIntervalController.text = product.reminderInterval.toString();
    }
    _initialDataLoaded = true;
  }

  void _addIngredient() {
    if (_ingredientController.text.trim().isNotEmpty) {
      setState(() {
        if (!_activeIngredients.contains(_ingredientController.text.trim())) {
          _activeIngredients.add(_ingredientController.text.trim());
        }
        _ingredientController.clear();
      });
    }
  }

  Future<void> _selectExpiryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _expiryDate) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_expiryDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please select an expiry date.'),
            backgroundColor: Colors.orange));
        return;
      }
      setState(() => _isLoading = true);

      final productData = Product(
        id: widget.productId,
        name: _nameController.text.trim(),
        batch: _batchController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0.0,
        manufacturer: _manufacturerController.text.trim(),
        activeIngredients: _activeIngredients,
        type: _selectedType,
        expiryDate: _expiryDate!,
        stock: int.tryParse(_stockController.text) ?? 0,
        reminderUnit: _selectedReminderUnit,
        reminderInterval: _selectedReminderUnit != ReminderUnit.none
            ? (int.tryParse(_reminderIntervalController.text) ?? 0)
            : 0,
      );

      try {
        final repo = ref.read(productRepositoryProvider);
        if (_isEditing) {
          await repo.updateProduct(widget.productId!, productData);
        } else {
          await repo.addProduct(productData);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Product ${_isEditing ? 'updated' : 'saved'} successfully!')));
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
      final productsAsync = ref.watch(productsStreamProvider);
      if(productsAsync.hasValue) {
        final product = productsAsync.value!.firstWhere((p) => p.id == widget.productId, orElse: () => throw Exception('Product not found'));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _populateFields(product));
        });
      }
    }

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Product' : 'Add Product')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: (_isEditing && !_initialDataLoaded)
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Product Name (required)'), validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<ProductType>(
                        value: _selectedType,
                        decoration: const InputDecoration(labelText: 'Product Type'),
                        items: ProductType.values.map((type) {
                          final text = type.name[0].toUpperCase() + type.name.substring(1);
                          return DropdownMenuItem(value: type, child: Text(text));
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedType = value);
                          }
                        },
                        validator: (v) => v == null ? 'Please select a type' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Product Price', prefixText: 'Rs. '), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: 16),
                      TextFormField(controller: _stockController, decoration: const InputDecoration(labelText: 'Stock Quantity'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                      const SizedBox(height: 16),
                      TextFormField(controller: _batchController, decoration: const InputDecoration(labelText: 'Product Batch')),
                      const SizedBox(height: 16),
                      TextFormField(controller: _manufacturerController, decoration: const InputDecoration(labelText: 'Manufacturer Name')),
                      const SizedBox(height: 24),

                      Text('Reminder Schedule', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final reminderUnitDropdown = DropdownButtonFormField<ReminderUnit>(
                            value: _selectedReminderUnit,
                            decoration: const InputDecoration(labelText: 'Unit'),
                            items: ReminderUnit.values.map((unit) {
                              final text = unit.name[0].toUpperCase() + unit.name.substring(1);
                              return DropdownMenuItem(value: unit, child: Text(text));
                            }).toList(),
                            onChanged: (value) => setState(() {
                              _selectedReminderUnit = value!;
                              if (value == ReminderUnit.none) {
                                _reminderIntervalController.clear();
                              }
                            }),
                          );

                          final reminderIntervalField = TextFormField(
                            controller: _reminderIntervalController,
                            decoration: const InputDecoration(labelText: 'Interval (e.g., 30)'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (v) => _selectedReminderUnit != ReminderUnit.none && (v == null || v.isEmpty) ? 'Required' : null,
                          );

                          if (constraints.maxWidth < 400 || _selectedReminderUnit == ReminderUnit.none) {
                            return Column(
                              children: [
                                reminderUnitDropdown,
                                if (_selectedReminderUnit != ReminderUnit.none) ...[
                                  const SizedBox(height: 16),
                                  reminderIntervalField,
                                ]
                              ],
                            );
                          } else {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 2, child: reminderUnitDropdown),
                                const SizedBox(width: 16),
                                Expanded(flex: 3, child: reminderIntervalField),
                              ],
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () => _selectExpiryDate(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                              labelText: 'Expiry Date',
                              errorText: _expiryDate == null? 'Expiry date is required' : null
                          ),
                          child: Text(_expiryDate == null ? 'Select Date' : DateFormat.yMMMd().format(_expiryDate!)),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => context.go('/products'), child: const Text('Cancel')),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _saveProduct,
                            icon: _isLoading ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_outlined),
                            label: Text(_isEditing ? 'Save Changes' : 'Add Product'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}