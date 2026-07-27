import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  String? _imagePath;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    _categoryController = TextEditingController(text: widget.product?.category ?? '');
    _descriptionController = TextEditingController(text: widget.product?.description ?? '');
    _imagePath = widget.product?.imagePath;
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
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
          imagePath: _imagePath,
        );
        controller.addProduct(newProduct);
      } else {
        // Edit existing
        widget.product!.name = name;
        widget.product!.price = price;
        widget.product!.category = category;
        widget.product!.description = description;
        widget.product!.imagePath = _imagePath;
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
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                      image: _imagePath != null
                          ? DecorationImage(
                              image: FileImage(File(_imagePath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _imagePath == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Add Photo', style: TextStyle(color: Colors.grey)),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
