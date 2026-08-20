import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/client.dart';
import '../models/product.dart';
import '../widgets/app_sidebar.dart';

class InvoiceScreen extends StatelessWidget {
  final Order order;
  final Client client;
  final List<OrderItem> items;
  final List<Product> products;
  final double previousBalance;
  final double discount;

  const InvoiceScreen({
    super.key,
    required this.order,
    required this.client,
    required this.items,
    required this.products,
    required this.previousBalance,
    required this.discount,
  });

  @override
  Widget build(BuildContext context) {
    double totalBill = items.fold(0, (sum, item) => sum + item.totalPrice);
    double netBalance = (totalBill - discount) + previousBalance;
    int totalItems = items.length;
    int totalQuantity = items.fold(0, (sum, item) => sum + item.totalPieces);

    DateTime orderDateTime = DateFormat('yyyy-MM-dd HH:mm').parse(order.orderDate);
    String date = DateFormat('dd-MMM-yyyy').format(orderDateTime);
    String time = DateFormat('hh:mm a').format(orderDateTime);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          AppSidebar(
            userId: order.userId,
            currentPage: "view_orders",
          ),
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.blueGrey),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text("Invoice", style: TextStyle(color: Colors.blueGrey)),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.print, color: Colors.blueGrey),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Printing feature coming soon!")),
                      );
                    },
                  ),
                ],
              ),
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Card(
                    margin: const EdgeInsets.all(20),
                    elevation: 4,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Center(
                            child: Column(
                              children: [
                                const Text(
                                  "HAMZA TOYS",
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Invoice",
                                  style: TextStyle(fontSize: 18, color: Colors.grey[600], letterSpacing: 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          
                          // Order & Client Info
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoText("Invoice No:", order.orderNo),
                                  _buildInfoText("Date:", date),
                                  _buildInfoText("Time:", time),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildInfoText("Client Name:", client.name),
                                  _buildInfoText("Phone:", client.phone),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 40),
                          
                          // Items Table
                          const Text(
                            "Order Details",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Table(
                            border: TableBorder.all(color: Colors.grey.shade300),
                            columnWidths: const {
                              0: FlexColumnWidth(3),
                              1: FlexColumnWidth(1),
                              2: FlexColumnWidth(1),
                              3: FlexColumnWidth(1),
                              4: FlexColumnWidth(1.5),
                            },
                            children: [
                              TableRow(
                                decoration: BoxDecoration(color: Colors.grey[100]),
                                children: [
                                  _buildTableCell("Product", isHeader: true),
                                  _buildTableCell("Boxes", isHeader: true, textAlign: TextAlign.center),
                                  _buildTableCell("Loose", isHeader: true, textAlign: TextAlign.center),
                                  _buildTableCell("Price", isHeader: true, textAlign: TextAlign.center),
                                  _buildTableCell("Total", isHeader: true, textAlign: TextAlign.right),
                                ],
                              ),
                              ...items.map((item) {
                                final product = products.firstWhere((p) => p.id == item.productId,
                                    orElse: () => Product(name: "Unknown", userId: 0, productId: "", description: "", totalPieces: 0, quantityPerBox: 0, purchasePrice: 0, arrivalDate: ""));
                                return TableRow(
                                  children: [
                                    _buildTableCell(product.name),
                                    _buildTableCell(item.boxes.toString(), textAlign: TextAlign.center),
                                    _buildTableCell(item.loosePieces.toString(), textAlign: TextAlign.center),
                                    _buildTableCell(item.sellingPrice.toStringAsFixed(2), textAlign: TextAlign.center),
                                    _buildTableCell(item.totalPrice.toStringAsFixed(2), textAlign: TextAlign.right),
                                  ],
                                );
                              }),
                            ],
                          ),
                          
                          const SizedBox(height: 30),
                          
                          // Totals
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoText("Total Items:", totalItems.toString()),
                                  _buildInfoText("Total Quantity:", totalQuantity.toString()),
                                ],
                              ),
                              SizedBox(
                                width: 250,
                                child: Column(
                                  children: [
                                    _buildTotalRow("Total Bill:", totalBill),
                                    _buildTotalRow("Previous Balance:", previousBalance),
                                    _buildTotalRow("Discount:", discount, isNegative: true),
                                    const Divider(),
                                    _buildTotalRow("Net Balance:", netBalance, isBold: true),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 50),
                          const Center(
                            child: Text(
                              "Thank you for your business!",
                              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          Center(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.print),
                              label: const Text("PRINT INVOICE"),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Printing feature coming soon!")),
                                );
                              },
                            ),
                          ),
                        ],
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

  Widget _buildInfoText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 5),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, TextAlign textAlign = TextAlign.start}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: textAlign,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double value, {bool isBold = false, bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
          Text(
            "${isNegative ? '-' : ''}${value.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
              color: isBold ? Colors.blue : null,
            ),
          ),
        ],
      ),
    );
  }
}
