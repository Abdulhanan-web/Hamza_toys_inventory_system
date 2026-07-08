// lib/screens/product_form_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../models/product.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({
    super.key,
    this.product,
  });

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _productIdController;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _boxesController;
  late final TextEditingController _quantityPerBoxController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _arrivalDateController;

  bool _isLoading = false;

  bool get isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();

    _productIdController = TextEditingController(
      text: widget.product?.productId ?? "",
    );

    _nameController = TextEditingController(
      text: widget.product?.name ?? "",
    );

    _descriptionController = TextEditingController(
      text: widget.product?.description ?? "",
    );

    _boxesController = TextEditingController(
      text: widget.product?.boxes.toString() ?? "",
    );

    _quantityPerBoxController = TextEditingController(
      text: widget.product?.quantityPerBox.toString() ?? "",
    );

    _purchasePriceController = TextEditingController(
      text: widget.product?.purchasePrice.toString() ?? "",
    );

    _arrivalDateController = TextEditingController(
      text: widget.product?.arrivalDate ??
          DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
  }

  @override
  void dispose() {
    _productIdController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _boxesController.dispose();
    _quantityPerBoxController.dispose();
    _purchasePriceController.dispose();
    _arrivalDateController.dispose();

    super.dispose();
  }
  Future<void> _pickArrivalDate() async {
    final DateTime initialDate =
        DateTime.tryParse(_arrivalDateController.text) ?? DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      _arrivalDateController.text =
          DateFormat('yyyy-MM-dd').format(pickedDate);
    }
  }

  Widget buildField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "$label is required";
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final product = Product(
        id: widget.product?.id,
        productId: _productIdController.text.trim(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        boxes: int.parse(_boxesController.text),
        quantityPerBox: int.parse(_quantityPerBoxController.text),
        purchasePrice: double.parse(_purchasePriceController.text),
        arrivalDate: _arrivalDateController.text,
      );

      if (isEdit) {
        await DatabaseHelper.instance.updateProduct(product);
      } else {
        await DatabaseHelper.instance.insertProduct(product);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            isEdit
                ? "Product updated successfully."
                : "Product added successfully.",
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e, stackTrace) {
      print("========== PRODUCT ERROR ==========");
      print(e);

      print("========== STACK TRACE ==========");
      print(stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error: $e"),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? "Edit Product" : "Add Product",
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SizedBox(
          width: 700,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        isEdit ? Icons.edit : Icons.inventory_2,
                        color: Colors.blue,
                        size: 70,
                      ),

                      const SizedBox(height: 15),

                      Text(
                        isEdit ? "Edit Product" : "Add New Product",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 35),

                      buildField(
                        label: "Product ID",
                        controller: _productIdController,
                      ),

                      buildField(
                        label: "Product Name",
                        controller: _nameController,
                      ),

                      buildField(
                        label: "Description",
                        controller: _descriptionController,
                        maxLines: 3,
                      ),

                      buildField(
                        label: "Number of Boxes",
                        controller: _boxesController,
                        keyboardType: TextInputType.number,
                      ),

                      buildField(
                        label: "Quantity Per Box",
                        controller: _quantityPerBoxController,
                        keyboardType: TextInputType.number,
                      ),

                      buildField(
                        label: "Purchase Price",
                        controller: _purchasePriceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),

                      buildField(
                        label: "Arrival Date",
                        controller: _arrivalDateController,
                        readOnly: true,
                        onTap: _pickArrivalDate,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_month),
                          onPressed: _pickArrivalDate,
                        ),
                      ),

                      const SizedBox(height: 25),

                      SizedBox(
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _saveProduct,
                          icon: _isLoading
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : Icon(
                            isEdit ? Icons.save : Icons.add,
                          ),
                          label: Text(
                            _isLoading
                                ? "Please wait..."
                                : (isEdit
                                ? "Update Product"
                                : "Add Product"),
                            style: const TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),

                      if (isEdit) ...[
                        const SizedBox(height: 15),

                        SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                            label: const Text("Cancel"),
                          ),
                        ),
                      ],
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