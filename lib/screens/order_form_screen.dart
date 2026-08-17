import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/client.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../widgets/app_sidebar.dart';

class OrderFormScreen extends StatefulWidget {
  final int userId;

  const OrderFormScreen({super.key, required this.userId});

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();

  List<Client> clients = [];
  List<Product> products = [];

  Client? selectedClient;
  Product? selectedProduct;

  final TextEditingController _boxesController = TextEditingController();
  final TextEditingController _loosePiecesController = TextEditingController(text: "0");
  final TextEditingController _qpbController = TextEditingController();
  final TextEditingController _sellingPriceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  List<OrderItem> orderItems = [];
  double grandTotal = 0.0;
  double discount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _discountController.addListener(_calculateTotals);
  }

  @override
  void dispose() {
    _boxesController.dispose();
    _loosePiecesController.dispose();
    _qpbController.dispose();
    _sellingPriceController.dispose();
    _discountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final cList = await DatabaseHelper.instance.getClients(widget.userId);
    final pList = await DatabaseHelper.instance.getProducts(widget.userId);
    setState(() {
      clients = cList;
      products = pList;
    });
  }

  void _calculateTotals() {
    double total = 0;
    for (var item in orderItems) {
      total += item.totalPrice;
    }
    double disc = double.tryParse(_discountController.text) ?? 0.0;
    setState(() {
      grandTotal = total;
      discount = disc;
    });
  }

  void _addItem() {
    if (selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a product first.")),
      );
      return;
    }
    
    int boxes = int.tryParse(_boxesController.text) ?? 0;
    int loose = int.tryParse(_loosePiecesController.text) ?? 0;
    int qpb = int.tryParse(_qpbController.text) ?? 0;
    double price = double.tryParse(_sellingPriceController.text) ?? selectedProduct!.purchasePrice;

    if ((boxes <= 0 && loose <= 0) || qpb <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid quantity and boxes.")),
      );
      return;
    }

    // STOCK CHECK
    int totalRequested = (boxes * qpb) + loose;
    int piecesInCart = orderItems
        .where((item) => item.productId == selectedProduct!.id)
        .fold(0, (sum, item) => sum + (item.boxes * item.quantityPerBox) + item.loosePieces);

    if (piecesInCart + totalRequested > selectedProduct!.totalPieces) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Insufficient stock! Available: ${selectedProduct!.totalPieces}, Already in cart: $piecesInCart"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Calculation based on total pieces
    double itemTotal = totalRequested * price;

    final newItem = OrderItem(
      orderId: 0, 
      productId: selectedProduct!.id!,
      boxes: boxes,
      loosePieces: loose,
      quantityPerBox: qpb,
      sellingPrice: price,
      totalPrice: itemTotal,
      discount: 0,
    );

    setState(() {
      orderItems.add(newItem);
      _boxesController.clear();
      _loosePiecesController.text = "0";
      _qpbController.clear();
      _sellingPriceController.clear();
      selectedProduct = null;
    });
    _calculateTotals();
  }

  Future<void> _saveOrder() async {
    if (selectedClient == null || orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a client and add at least one product.")),
      );
      return;
    }

    final orderNo = "ORD-${DateTime.now().millisecondsSinceEpoch}";
    final finalTotal = grandTotal - discount;
    
    final order = Order(
      userId: widget.userId,
      orderNo: orderNo,
      clientId: selectedClient!.id!,
      orderDate: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      grandTotal: finalTotal,
      paidAmount: 0,
      remainingAmount: finalTotal,
      status: "Pending",
      remarks: _remarksController.text,
    );

    await DatabaseHelper.instance.insertCompleteOrder(order, orderItems);

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order saved successfully!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            userId: widget.userId,
            onRefresh: _loadData,
            currentPage: "add_order",
          ),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: const Text("Create New Order"),
                automaticallyImplyLeading: false,
              ),
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // CLIENT SECTION
                        const Text("Select Client", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<Client>(
                          isExpanded: true,
                          value: selectedClient,
                          items: clients.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                          onChanged: (val) => setState(() => selectedClient = val),
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                        ),
                        if (selectedClient != null) ...[
                          const SizedBox(height: 10),
                          Card(
                            color: Colors.blueGrey.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Phone: ${selectedClient!.phone}"),
                                  Text("Address: ${selectedClient!.address}"),
                                  Text("Current Balance: ${selectedClient!.balance.toStringAsFixed(2)}", 
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const Divider(height: 40),
                        // ADD PRODUCT SECTION
                        const Text("Add Product", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<Product>(
                          isExpanded: true,
                          value: selectedProduct,
                          items: products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedProduct = val;
                              if (val != null) {
                                _qpbController.text = val.quantityPerBox.toString();
                              }
                            });
                          },
                          decoration: const InputDecoration(labelText: "Product", border: OutlineInputBorder()),
                        ),
                        if (selectedProduct != null) ...[
                          const SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text(
                              "Stock: ${selectedProduct!.totalPieces} pcs (${selectedProduct!.fullBoxes} boxes, ${selectedProduct!.loosePieces} loose)",
                              style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _boxesController,
                                decoration: const InputDecoration(labelText: "Boxes", border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _loosePiecesController,
                                decoration: const InputDecoration(labelText: "Loose", border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _qpbController,
                                decoration: const InputDecoration(labelText: "Qty/Box", border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _sellingPriceController,
                                decoration: InputDecoration(
                                  labelText: "Selling Price",
                                  hintText: selectedProduct != null ? "Hint: ${selectedProduct!.purchasePrice}" : "0.0",
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 1,
                              child: SizedBox(
                                height: 55, 
                                child: ElevatedButton(
                                  onPressed: _addItem,
                                  child: const Text("Add", textAlign: TextAlign.center),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // ITEMS LIST
                        if (orderItems.isNotEmpty) ...[
                          const Text("Order Items", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: orderItems.length,
                            itemBuilder: (context, index) {
                              final item = orderItems[index];
                              final product = products.firstWhere((p) => p.id == item.productId);
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(product.name),
                                subtitle: Text("${item.boxes} boxes x ${item.quantityPerBox} qty, ${item.loosePieces} loose  @ ${item.sellingPrice}"),
                                trailing: Text(item.totalPrice.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
                                onLongPress: () {
                                  setState(() {
                                    orderItems.removeAt(index);
                                    _calculateTotals();
                                  });
                                },
                              );
                            },
                          ),
                        ],
                        const Divider(height: 40),
                        // TOTALS SECTION
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                _buildTotalRow("Grand Total:", grandTotal.toStringAsFixed(2)),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Discount:", style: TextStyle(fontSize: 16)),
                                    SizedBox(
                                      width: 100,
                                      child: TextFormField(
                                        controller: _discountController,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.right,
                                        decoration: const InputDecoration(isDense: true),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                _buildTotalRow("Great Grand Total:", (grandTotal - discount).toStringAsFixed(2), isBold: true, color: Colors.green),
                                if (selectedClient != null) ...[
                                  const SizedBox(height: 8),
                                  _buildTotalRow("New Balance:", (selectedClient!.balance + (grandTotal - discount)).toStringAsFixed(2), isSmall: true),
                                ]
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: _saveOrder,
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                          child: const Text("SAVE ORDER", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 20),
                      ],
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

  Widget _buildTotalRow(String label, String value, {bool isBold = false, bool isSmall = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isBold ? 18 : (isSmall ? 14 : 16), fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isSmall ? Colors.grey : null)),
        Text(value, style: TextStyle(fontSize: isBold ? 18 : (isSmall ? 14 : 16), fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? (isSmall ? Colors.grey : null))),
      ],
    );
  }
}
