import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../widgets/app_sidebar.dart';

class OrderListScreen extends StatefulWidget {
  final int userId;

  const OrderListScreen({super.key, required this.userId});

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
    final data = await DatabaseHelper.instance.getAllOrdersWithClients(widget.userId);
    setState(() {
      orders = data;
      isLoading = false;
    });
  }

  Future<void> _viewOrderDetails(Map<String, dynamic> order) async {
    final items = await DatabaseHelper.instance.getOrderDetails(order['id']);
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Order Details: ${order['orderNo']}"),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Client: ${order['clientName']}"),
                Text("Date: ${order['orderDate']}"),
                const Divider(),
                const Text("Items:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item['name']),
                        subtitle: Text("${item['boxes']} boxes x ${item['quantityPerBox']} qty, ${item['loosePieces']} loose pieces @ Rs.${item['sellingPrice']}"),
                        trailing: Text("Rs.${item['totalPrice']}"),
                      );
                    },
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Grand Total:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Rs.${order['grandTotal']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Text("Paid: Rs.${order['paidAmount']}"),
                Text("Remaining: Rs.${order['remainingAmount']}"),
                if (order['remarks'] != null && order['remarks'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text("Remarks: ${order['remarks']}"),
                  ),
              ],
            ),
          ),
          actions: [
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
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            userId: widget.userId,
            onRefresh: _loadOrders,
          ),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: const Text("All Orders"),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadOrders,
                  ),
                ],
              ),
              body: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : orders.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
                              SizedBox(height: 16),
                              Text("No orders found", style: TextStyle(fontSize: 18, color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            final date = order['orderDate'];
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
                                    Text(
                                      order['orderNo'],
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      "Rs.${order['grandTotal']}",
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text("Client: ${order['clientName']}"),
                                    Text("Date: $date"),
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
                                        TextButton(
                                          onPressed: () => _viewOrderDetails(order),
                                          child: const Text("View Details"),
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
