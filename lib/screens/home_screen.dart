// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../widgets/app_sidebar.dart';
import 'product_form_screen.dart';
import 'add_stock_screen.dart';
import 'product_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final int userId;
  final String username;

  const HomeScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    final list = await DatabaseHelper.instance.getProducts(widget.userId);

    setState(() {
      products = list;
      isLoading = false;
    });
  }

  Future<void> deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Product"),
          content: Text(
            "Are you sure you want to delete '${product.name}'?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
            SizedBox(
              width: 100,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(0, 40),
                ),
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text("Delete"),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await DatabaseHelper.instance.deleteProduct(product.id!);

    loadProducts();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Product deleted successfully."),
      ),
    );
  }

  Widget buildProductCard(Product product) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(product: product),
            ),
          );
          loadProducts();
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.inventory_2, size: 18, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Text(
                    "Stock: ${product.fullBoxes} Boxes, ${product.loosePieces} Pieces",
                    style: const TextStyle(fontSize: 16),
                  )
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.category, size: 18, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Text(
                    "Quantity / Box: ${product.quantityPerBox}",
                    style: const TextStyle(fontSize: 16),
                  )
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 45),
                      ),
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                      label: const Text("Add Stock"),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddStockScreen(product: product),
                          ),
                        );
                        if (result == true) {
                          loadProducts();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 45),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductFormScreen(
                              userId: widget.userId,
                              product: product,
                            ),
                          ),
                        );
                        loadProducts();
                      },
                      child: const Icon(Icons.edit, size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 45),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () {
                        deleteProduct(product);
                      },
                      child: const Icon(Icons.delete, size: 18),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            userId: widget.userId,
            username: widget.username,
            onRefresh: loadProducts,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 35,
                            child: Icon(
                              Icons.person,
                              size: 35,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Welcome",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  widget.username,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    "Dashboard",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: isLoading
                        ? const Center(
                      child: CircularProgressIndicator(),
                    )
                        : products.isEmpty
                        ? const Center(
                      child: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 80,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 15),
                          Text(
                            "No Products Added",
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        return buildProductCard(
                          products[index],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
