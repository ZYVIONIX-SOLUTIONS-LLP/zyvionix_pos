import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/product_controller.dart';
import '../../models/product.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _categoryController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    _categoryController = TextEditingController(text: widget.product?.category ?? '');
    _descriptionController = TextEditingController(text: widget.product?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final controller = context.read<ProductController>();
      
      final name = _nameController.text.trim();
      final price = double.parse(_priceController.text.trim());
      final category = _categoryController.text.trim();
      final description = _descriptionController.text.trim();

      if (widget.product == null) {
        // Add new
        final newProduct = Product.create(
          name: name,
          price: price,
          category: category,
          description: description,
        );
        controller.addProduct(newProduct);
      } else {
        // Edit existing
        widget.product!.name = name;
        widget.product!.price = price;
        widget.product!.category = category;
        widget.product!.description = description;
        controller.updateProduct(widget.product!);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Item' : 'Add Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                label: 'Item Name',
                hint: 'Enter item name',
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an item name';
                  }
                  return null;
                },
              ),
              CustomTextField(
                label: 'Price (₹)',
                hint: 'Enter price',
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              CustomTextField(
                label: 'Category (Optional)',
                hint: 'e.g. Food, Drinks',
                controller: _categoryController,
              ),
              CustomTextField(
                label: 'Description (Optional)',
                hint: 'Enter description',
                controller: _descriptionController,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Save',
                onPressed: _saveProduct,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
