// lib/screens/home_screen.dart

import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/product.dart';
import 'login_screen.dart';
import 'product_form_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;

  const HomeScreen({
    super.key,
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
    final list = await DatabaseHelper.instance.getProducts();

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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Delete"),
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

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  Widget sidebarButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget buildProductCard(Product product) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              product.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.inventory_2,size:18),
                const SizedBox(width:8),
                Text("Boxes : ${product.boxes}")
              ],
            ),

            const SizedBox(height:6),

            Row(
              children: [
                const Icon(Icons.category,size:18),
                const SizedBox(width:8),
                Text("Quantity / Box : ${product.quantityPerBox}")
              ],
            ),

            const SizedBox(height:6),

            Row(
              children: [
                const Icon(Icons.currency_rupee,size:18),
                const SizedBox(width:8),
                Text("Purchase Price : ${product.purchasePrice}")
              ],
            ),

            const SizedBox(height: 6),

            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18),
                const SizedBox(width: 8),
                Text("Arrival Date : ${product.arrivalDate}")
              ],
            ),

            const SizedBox(height:20),

            Row(
              children: [

                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit"),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductFormScreen(
                            product: product,
                          ),
                        ),
                      );

                      loadProducts();
                    },
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    icon: const Icon(Icons.delete),
                    label: const Text("Delete"),
                    onPressed: () {
                      deleteProduct(product);
                    },
                  ),
                ),

              ],
            )

          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [

          //======================
          // LEFT SIDEBAR
          //======================

          Container(
            width: 240,
            color: Colors.blueGrey.shade900,
            child: SafeArea(
              child: Column(
                children: [

                  const SizedBox(height: 20),

                  const Icon(
                    Icons.inventory,
                    color: Colors.white,
                    size: 60,
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Inventory System",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const Divider(
                    color: Colors.white24,
                    height: 40,
                  ),

                  sidebarButton(
                    icon: Icons.dashboard,
                    title: "Dashboard",
                    onTap: () {},
                  ),

                  sidebarButton(
                    icon: Icons.add_box,
                    title: "Add Product",
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProductFormScreen(),
                        ),
                      );

                      loadProducts();
                    },
                  ),

                  sidebarButton(
                    icon: Icons.people,
                    title: "Customers",
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Customers module coming soon.",
                          ),
                        ),
                      );
                    },
                  ),

                  sidebarButton(
                    icon: Icons.shopping_cart,
                    title: "Sales",
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Sales module coming soon.",
                          ),
                        ),
                      );
                    },
                  ),

                  sidebarButton(
                    icon: Icons.bar_chart,
                    title: "Reports",
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Reports module coming soon.",
                          ),
                        ),
                      );
                    },
                  ),

                  const Spacer(),

                  const Divider(
                    color: Colors.white24,
                  ),

                  sidebarButton(
                    icon: Icons.logout,
                    title: "Logout",
                    color: Colors.redAccent,
                    onTap: logout,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          //======================
          // RIGHT CONTENT
          //======================

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Welcome Card

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
