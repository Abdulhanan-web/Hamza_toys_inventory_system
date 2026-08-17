import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/batch.dart';
import '../widgets/app_sidebar.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  List<ProductBatch> batches = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadBatches();
  }

  Future<void> loadBatches() async {
    final list = await DatabaseHelper.instance.getBatchesForProduct(widget.product.id!);
    setState(() {
      // Filter out batches with zero or less remaining stock
      batches = list.where((batch) => batch.quantityRemaining > 0).toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            userId: widget.product.userId,
            currentPage: "dashboard",
          ),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: const Text("Product Details"),
                automaticallyImplyLeading: true,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Product ID
                    Text(
                      "ID: ${widget.product.productId}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // 2. Product Name
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // 3. Description
                    if (widget.product.description.isNotEmpty) ...[
                      Text(
                        widget.product.description,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade800,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // 5. Inventory Details
                    const Text(
                      "Inventory Summary",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _inventoryItem("Boxes", widget.product.fullBoxes.toString()),
                          _inventoryItem("Loose Pcs", widget.product.loosePieces.toString()),
                          _inventoryItem("Qty/Box", widget.product.quantityPerBox.toString()),
                          _inventoryItem("Total Pcs", widget.product.totalPieces.toString()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 6. Batches of Stock
                    const Text(
                      "Stock Batches",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : batches.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text("No active stock batches found."),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: batches.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final batch = batches[index];
                                  final int bBoxes = widget.product.quantityPerBox > 0
                                      ? batch.quantityRemaining ~/ widget.product.quantityPerBox
                                      : 0;
                                  final int bLoose = widget.product.quantityPerBox > 0
                                      ? batch.quantityRemaining % widget.product.quantityPerBox
                                      : batch.quantityRemaining;

                                  return Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    batch.purchaseDate,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                "₹${batch.purchasePrice.toStringAsFixed(2)}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 12),
                                            child: Divider(),
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              _batchInfoItem("Boxes", bBoxes.toString()),
                                              _batchInfoItem("Loose", bLoose.toString()),
                                              _batchInfoItem("Total Remaining", batch.quantityRemaining.toString()),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inventoryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _batchInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
