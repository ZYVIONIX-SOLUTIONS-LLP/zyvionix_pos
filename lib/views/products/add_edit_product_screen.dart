import 'dart:io';
import 'package:flutter/material.dart';
import 'package:floating_snackbar/floating_snackbar.dart';
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

  String? _imagePath;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(
      text: widget.product?.price.toString() ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.product?.category ?? '',
    );

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
    super.dispose();
  }

  void _saveProduct() {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<ProductController>();

    final name = _nameController.text.trim();
    final price = double.parse(_priceController.text.trim());
    final category = _categoryController.text.trim();

    String message;

    if (widget.product == null) {
      final newProduct = Product.create(
        name: name,
        price: price,
        category: category.isEmpty ? null : category,
        imagePath: _imagePath,
      );

      controller.addProduct(newProduct);
      message = "Product added successfully!";
    } else {
      widget.product!.name = name;
      widget.product!.price = price;
      widget.product!.category = category.isEmpty ? null : category;
      widget.product!.imagePath = _imagePath;

      controller.updateProduct(widget.product!);
      message = "Product updated successfully!";
    }

    floatingSnackBar(
      message: message,
      context: context,
      textColor: Colors.white,
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    );

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Item' : 'Add Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                              image: _imagePath!.startsWith('http')
                                  ? NetworkImage(_imagePath!) as ImageProvider
                                  : FileImage(File(_imagePath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _imagePath == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Add Photo',
                                style: TextStyle(color: Colors.grey),
                              ),
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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
              const SizedBox(height: 24),

              PrimaryButton(
                text: isEditing ? 'Update Product' : 'Save Product',
                onPressed: _saveProduct,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
