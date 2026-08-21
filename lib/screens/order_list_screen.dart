import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/client.dart';
import '../models/product.dart';
import '../widgets/app_sidebar.dart';
import 'invoice_screen.dart';

class OrderListScreen extends StatefulWidget {
  final int userId;
  final Client? filterClient;

  const OrderListScreen({super.key, required this.userId, this.filterClient});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => isLoading = true);
    final allData = await DatabaseHelper.instance.getAllOrdersWithClients(widget.userId);
    
    setState(() {
      if (widget.filterClient != null) {
        orders = allData.where((o) => o['clientId'] == widget.filterClient!.id).toList();
      } else {
        orders = allData;
      }
      isLoading = false;
    });
  }

  Future<void> _viewInvoice(Map<String, dynamic> orderMap) async {
    setState(() => isLoading = true);
    try {
      final order = Order.fromMap(orderMap);
      final client = Client(
        id: orderMap['clientId'],
        userId: widget.userId,
        clientId: "", 
        name: orderMap['clientName'] ?? "Unknown",
        phone: orderMap['phone'] ?? "",
        address: orderMap['address'] ?? "",
        balance: orderMap['currentClientBalance'] ?? 0.0,
        notes: "",
        createdAt: "",
      );

      final itemsData = await DatabaseHelper.instance.getOrderItems(order.id!);
      final products = await DatabaseHelper.instance.getProducts(widget.userId);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InvoiceScreen(
            order: order,
            client: client,
            items: itemsData,
            products: products,
            previousBalance: order.previousBalance,
            discount: order.discount,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading invoice: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          )),
        ],
      ),
    );
  }

  Future<void> _viewOrderDetails(Map<String, dynamic> order) async {
    final items = await DatabaseHelper.instance.getOrderDetails(order['id']);
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        double orderDiscount = (order['discount'] as num?)?.toDouble() ?? 0.0;
        double subTotal = (order['totalAmount'] as num?)?.toDouble() ?? (order['grandTotal'] as num).toDouble();
        
        return AlertDialog(
          title: Text("Order Details: ${order['orderNo']}"),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Client: ${order['clientName']}", style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text("Date: ${order['orderDate']}"),
                  const Divider(),
                  const Text("Items:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        subtitle: Text("${item['boxes']} boxes x ${item['quantityPerBox']} qty, ${item['loosePieces']} loose pieces @ Rs.${item['sellingPrice']}", style: const TextStyle(fontSize: 12)),
                        trailing: Text("Rs.${item['totalPrice']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
                  const Divider(),
                  _buildDetailRow("Sub Total:", "Rs.${subTotal.toStringAsFixed(2)}"),
                  if (orderDiscount > 0)
                    _buildDetailRow("Discount:", "- Rs.${orderDiscount.toStringAsFixed(2)}", color: Colors.red),
                  _buildDetailRow("Grand Total:", "Rs.${order['grandTotal']}", isBold: true, color: Colors.blue),
                  const Divider(),
                  _buildDetailRow("Paid:", "Rs.${order['paidAmount']}"),
                  _buildDetailRow("Remaining:", "Rs.${order['remainingAmount']}", 
                      color: (order['remainingAmount'] as double) > 0 ? Colors.orange : Colors.green,
                      isBold: true),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _viewInvoice(order);
              },
              child: const Text("View Invoice"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.filterClient != null ? "Orders: ${widget.filterClient!.name}" : "All Orders";

    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            userId: widget.userId,
            onRefresh: _loadOrders,
            currentPage: widget.filterClient != null ? "clients" : "view_orders",
          ),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Text(title),
                leading: widget.filterClient != null
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      )
                    : null,
                actions: [
                  IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrders),
                ],
              ),
              body: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : orders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text("No orders found", style: TextStyle(fontSize: 18, color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            final remaining = order['remainingAmount'] as double;
                            
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(order['orderNo'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text("Rs.${order['grandTotal']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    if (widget.filterClient == null) Text("Client: ${order['clientName']}"),
                                    Text("Date: ${order['orderDate']}"),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: remaining > 0 ? Colors.orange.shade100 : Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            remaining > 0 ? "Pending: Rs.$remaining" : "Paid",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: remaining > 0 ? Colors.orange.shade900 : Colors.green.shade900,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            TextButton.icon(
                                              icon: const Icon(Icons.receipt_long, size: 16),
                                              label: const Text("Invoice"),
                                              onPressed: () => _viewInvoice(order),
                                            ),
                                            TextButton.icon(
                                              icon: const Icon(Icons.info_outline, size: 16),
                                              label: const Text("Details"),
                                              onPressed: () => _viewOrderDetails(order),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
