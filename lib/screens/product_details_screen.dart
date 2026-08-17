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
      batches = list;
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Info Header
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.name,
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Text("Product ID: ${widget.product.productId}", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                            const Divider(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _infoTile("Total Pieces", widget.product.totalPieces.toString()),
                                _infoTile("Qty / Box", widget.product.quantityPerBox.toString()),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _infoTile("Total Boxes", widget.product.fullBoxes.toString()),
                                _infoTile("Loose Pieces", widget.product.loosePieces.toString()),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "Stock Batches",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : batches.isEmpty
                            ? const Text("No batches found.")
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: batches.length,
                                itemBuilder: (context, index) {
                                  final batch = batches[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: batch.quantityRemaining > 0 ? Colors.green.shade100 : Colors.red.shade100,
                                        child: Icon(
                                          batch.quantityRemaining > 0 ? Icons.inventory : Icons.inventory_2_outlined,
                                          color: batch.quantityRemaining > 0 ? Colors.green : Colors.red,
                                        ),
                                      ),
                                      title: Text("Arrival: ${batch.purchaseDate}"),
                                      subtitle: Text("Price: ₹${batch.purchasePrice}"),
                                      trailing: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "${batch.quantityRemaining} Remaining",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: batch.quantityRemaining > 0 ? Colors.green : Colors.red,
                                            ),
                                          ),
                                          Text("Purchased: ${batch.quantityPurchased}"),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                    const SizedBox(height: 20),
                    if (widget.product.description.isNotEmpty) ...[
                      const Text(
                        "Description",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(widget.product.description, style: const TextStyle(fontSize: 16)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
