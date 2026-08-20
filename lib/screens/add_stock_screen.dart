import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../widgets/app_sidebar.dart';

class AddStockScreen extends StatefulWidget {
  final Product product;

  const AddStockScreen({super.key, required this.product});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _boxesController = TextEditingController();
  final TextEditingController _piecesController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    // Price controller is left empty to allow hintText to show as placeholder
  }

  @override
  void dispose() {
    _boxesController.dispose();
    _piecesController.dispose();
    _priceController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      int boxes = int.tryParse(_boxesController.text) ?? 0;
      int pieces = int.tryParse(_piecesController.text) ?? 0;
      int totalNewPieces = (boxes * widget.product.quantityPerBox) + pieces;
      
      // Use existing purchase price if the field is left empty (placeholder logic)
      double newPrice = double.tryParse(_priceController.text) ?? widget.product.purchasePrice;
      String date = _dateController.text;

      if (totalNewPieces <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid quantity.")),
        );
        return;
      }

      await DatabaseHelper.instance.addStock(
        widget.product.id!,
        totalNewPieces,
        newPrice,
        date,
      );

      if (mounted) {
        Navigator.pop(context, true);
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
            userId: widget.product.userId,
            currentPage: "dashboard",
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned(
                  top: 20,
                  left: 20,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                    color: Colors.blueGrey,
                  ),
                ),
                Center(
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
                                widget.product.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Current Stock: ${widget.product.fullBoxes} Bx, ${widget.product.loosePieces} Pcs",
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 25),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _boxesController,
                                      decoration: InputDecoration(
                                        labelText: "Boxes to Add",
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _piecesController,
                                      decoration: InputDecoration(
                                        labelText: "Extra Pieces",
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _priceController,
                                decoration: InputDecoration(
                                  labelText: "New Purchase Price (per piece)",
                                  hintText: "Rs. ${widget.product.purchasePrice.toStringAsFixed(2)}",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  prefixIcon: const Icon(Icons.currency_rupee),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  // Field is no longer required as it falls back to existing price
                                  if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                                    return "Invalid price";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _dateController,
                                decoration: InputDecoration(
                                  labelText: "Arrival Date",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  suffixIcon: const Icon(Icons.calendar_today),
                                ),
                                readOnly: true,
                                onTap: _selectDate,
                              ),
                              const SizedBox(height: 35),
                              SizedBox(
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _save,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    "Add Stock",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  "Cancel",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
