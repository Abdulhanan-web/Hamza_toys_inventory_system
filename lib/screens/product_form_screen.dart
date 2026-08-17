// lib/screens/product_form_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../widgets/app_sidebar.dart';

class ProductFormScreen extends StatefulWidget {
  final int userId;
  final Product? product;

  const ProductFormScreen({
    super.key,
    required this.userId,
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
  late final TextEditingController _loosePiecesController;
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
      text: widget.product?.fullBoxes.toString() ?? "0",
    );

    _loosePiecesController = TextEditingController(
      text: widget.product?.loosePieces.toString() ?? "0",
    );

    _quantityPerBoxController = TextEditingController(
      text: widget.product?.quantityPerBox.toString() ?? "0",
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
    _loosePiecesController.dispose();
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
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        validator: validator ?? (value) {
          if (value == null || value.trim().isEmpty) {
            return "$label is required";
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 14),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    int qpb = int.tryParse(_quantityPerBoxController.text) ?? 0;
    int boxes = int.tryParse(_boxesController.text) ?? 0;
    int loose = int.tryParse(_loosePiecesController.text) ?? 0;

    if (qpb > 0 && loose >= qpb) {
      loose = 0;
    }

    int total = (boxes * qpb) + loose;

    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text("Please enter either boxes or loose pieces to add stock."),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String pId = _productIdController.text.trim();
      final bool exists = await DatabaseHelper.instance.productIdExists(
        pId, 
        excludeId: widget.product?.id,
      );

      if (exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("Product ID already exists. Please use a unique ID."),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final product = Product(
        id: widget.product?.id,
        userId: widget.userId,
        productId: pId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        totalPieces: total,
        quantityPerBox: qpb,
        purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0.0,
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error: $e"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          AppSidebar(
            userId: widget.userId,
            currentPage: isEdit ? "dashboard" : "add_product",
          ),
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                    child: Container(
                      padding: const EdgeInsets.all(35),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              isEdit ? "Update Product" : "New Product",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueGrey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),
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
                              maxLines: 2,
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: buildField(
                                    label: "Boxes",
                                    controller: _boxesController,
                                    keyboardType: TextInputType.number,
                                    validator: (value) => null,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: buildField(
                                    label: "Loose Pieces",
                                    controller: _loosePiecesController,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return null;
                                      int loose = int.tryParse(value) ?? 0;
                                      int qpb = int.tryParse(_quantityPerBoxController.text) ?? 0;
                                      if (qpb > 0 && loose >= qpb) {
                                        return "Must be < Qty/Box";
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            buildField(
                              label: "Quantity Per Box",
                              controller: _quantityPerBoxController,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                int boxes = int.tryParse(_boxesController.text) ?? 0;
                                if (boxes > 0) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Required for boxes";
                                  }
                                  int? q = int.tryParse(value);
                                  if (q == null || q <= 0) {
                                    return "Must be > 0";
                                  }
                                }
                                return null;
                              },
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
                              suffixIcon: const Icon(Icons.calendar_today, size: 20),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 55,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _saveProduct,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        isEdit ? "Update Product" : "Add Product",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            if (isEdit) ...[
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  "Cancel",
                                  style: TextStyle(color: Colors.grey),
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
          ),
        ],
      ),
    );
  }
}
