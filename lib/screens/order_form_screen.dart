import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/client.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../widgets/app_sidebar.dart';
import 'invoice_screen.dart';

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
  int? _editingIndex;
  bool _isLoading = false;

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

  void _clearForm() {
    _boxesController.clear();
    _loosePiecesController.text = "0";
    _qpbController.clear();
    _sellingPriceController.clear();
    selectedProduct = null;
    _editingIndex = null;
  }

  int _getAvailableStock(Product product) {
    int piecesInCart = 0;
    for (int i = 0; i < orderItems.length; i++) {
      if (_editingIndex != null && i == _editingIndex) continue;
      if (orderItems[i].productId == product.id) {
        piecesInCart += (orderItems[i].boxes * orderItems[i].quantityPerBox) + orderItems[i].loosePieces;
      }
    }
    return product.totalPieces - piecesInCart;
  }

  String _getStockDisplay(Product product) {
    int total = _getAvailableStock(product);
    if (product.quantityPerBox > 0) {
      int boxes = total ~/ product.quantityPerBox;
      int loose = total % product.quantityPerBox;
      return "$boxes boxes, $loose loose pcs ($total total pcs)";
    }
    return "$total total pcs";
  }

  void _addItem() {
    if (selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.orange, content: Text("Please select a product first.")),
      );
      return;
    }
    
    int boxes = int.tryParse(_boxesController.text) ?? 0;
    int loose = int.tryParse(_loosePiecesController.text) ?? 0;
    int qpb = int.tryParse(_qpbController.text) ?? 0;
    double price = double.tryParse(_sellingPriceController.text) ?? selectedProduct!.purchasePrice;

    if ((boxes <= 0 && loose <= 0) || qpb <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.orange, content: Text("Enter valid quantity and boxes.")),
      );
      return;
    }

    int totalRequested = (boxes * qpb) + loose;
    int availableStock = _getAvailableStock(selectedProduct!);

    if (totalRequested > availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Insufficient stock! Available: ${_getStockDisplay(selectedProduct!)}"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
      if (_editingIndex != null) {
        orderItems[_editingIndex!] = newItem;
      } else {
        int existingIndex = orderItems.indexWhere((item) => 
          item.productId == newItem.productId && 
          item.sellingPrice == newItem.sellingPrice &&
          item.quantityPerBox == newItem.quantityPerBox
        );

        if (existingIndex != -1) {
          final existing = orderItems[existingIndex];
          int newBoxes = existing.boxes + newItem.boxes;
          int newLoose = existing.loosePieces + newItem.loosePieces;
          int newTotalPieces = (newBoxes * newItem.quantityPerBox) + newLoose;

          orderItems[existingIndex] = OrderItem(
            orderId: 0,
            productId: newItem.productId,
            boxes: newBoxes,
            loosePieces: newLoose,
            quantityPerBox: newItem.quantityPerBox,
            sellingPrice: newItem.sellingPrice,
            totalPrice: newTotalPieces * newItem.sellingPrice,
            discount: 0,
          );
        } else {
          orderItems.add(newItem);
        }
      }
      _clearForm();
    });
    _calculateTotals();
  }

  void _editItem(int index) {
    final item = orderItems[index];
    setState(() {
      _editingIndex = index;
      selectedProduct = products.firstWhere((p) => p.id == item.productId);
      _boxesController.text = item.boxes.toString();
      _loosePiecesController.text = item.loosePieces.toString();
      _qpbController.text = item.quantityPerBox.toString();
      _sellingPriceController.text = item.sellingPrice.toString();
    });
  }

  Future<void> _saveOrder() async {
    if (selectedClient == null || orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.orange, content: Text("Please select a client and add at least one product.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final orderNo = "ORD-${DateTime.now().millisecondsSinceEpoch}";
      final currentOrderGrandTotal = grandTotal - discount;
      final previousBalance = selectedClient!.balance;
      
      final order = Order(
        userId: widget.userId,
        orderNo: orderNo,
        clientId: selectedClient!.id!,
        orderDate: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
        totalAmount: grandTotal,
        discount: discount,
        grandTotal: currentOrderGrandTotal,
        previousBalance: previousBalance,
        paidAmount: 0,
        remainingAmount: currentOrderGrandTotal,
        status: "Pending",
        remarks: _remarksController.text,
      );

      final clientForInvoice = selectedClient!;
      final itemsForInvoice = List<OrderItem>.from(orderItems);
      final productsForInvoice = List<Product>.from(products);

      await DatabaseHelper.instance.insertCompleteOrder(order, orderItems);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text("Order saved successfully!")),
        );
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => InvoiceScreen(
              order: order,
              client: clientForInvoice,
              items: itemsForInvoice,
              products: productsForInvoice,
              previousBalance: previousBalance,
              discount: discount,
              isFromOrderForm: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          labelStyle: const TextStyle(fontSize: 14),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double previousBalance = selectedClient?.balance ?? 0.0;
    double netTotal = grandTotal + previousBalance - discount;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          AppSidebar(
            userId: widget.userId,
            onRefresh: _loadData,
            currentPage: "add_order",
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
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              "Create New Order",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.blueGrey),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),

                            // CLIENT SECTION
                            _buildSectionTitle("Client Details"),
                            DropdownButtonFormField<Client>(
                              isExpanded: true,
                              value: (selectedClient != null && clients.contains(selectedClient)) ? selectedClient : null,
                              items: clients.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                              onChanged: (val) => setState(() => selectedClient = val),
                              decoration: InputDecoration(
                                labelText: "Select Client",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: Colors.grey[50],
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                            if (selectedClient != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.withOpacity(0.1)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Phone: ${selectedClient!.phone}", style: const TextStyle(fontSize: 13)),
                                        Text("Address: ${selectedClient!.address}", style: const TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                    Text(
                                      "Balance: ${selectedClient!.balance.toStringAsFixed(2)}",
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 25),
                            const Divider(),

                            // ADD PRODUCT SECTION
                            _buildSectionTitle(_editingIndex == null ? "Select Product" : "Edit Order Item"),
                            DropdownButtonFormField<Product>(
                              isExpanded: true,
                              value: (selectedProduct != null && products.contains(selectedProduct)) ? selectedProduct : null,
                              items: products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                              onChanged: (val) {
                                setState(() {
                                  selectedProduct = val;
                                  if (val != null && _editingIndex == null) {
                                    _qpbController.text = val.quantityPerBox.toString();
                                    _sellingPriceController.clear();
                                  }
                                });
                              },
                              decoration: InputDecoration(
                                labelText: "Product",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: Colors.grey[50],
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                            if (selectedProduct != null) ...[
                              Padding(
                                padding: const EdgeInsets.only(top: 6, left: 4),
                                child: Text(
                                  "Stock: ${_getStockDisplay(selectedProduct!)}",
                                  style: TextStyle(
                                    color: _getAvailableStock(selectedProduct!) <= 0 ? Colors.red : Colors.blueGrey,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Expanded(child: buildField(label: "Boxes", controller: _boxesController, keyboardType: TextInputType.number)),
                                const SizedBox(width: 12),
                                Expanded(child: buildField(label: "Loose", controller: _loosePiecesController, keyboardType: TextInputType.number)),
                                const SizedBox(width: 12),
                                Expanded(child: buildField(label: "Qty/Box", controller: _qpbController, keyboardType: TextInputType.number)),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: buildField(
                                    label: "Selling Price",
                                    controller: _sellingPriceController,
                                    keyboardType: TextInputType.number,
                                    hintText: selectedProduct != null ? "Rs. ${selectedProduct!.purchasePrice}" : "0.0",
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 1,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 48,
                                          child: ElevatedButton(
                                            onPressed: _addItem,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _editingIndex != null ? Colors.orange : Colors.blue,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            child: Text(_editingIndex == null ? "Add Item" : "Update"),
                                          ),
                                        ),
                                      ),
                                      if (_editingIndex != null) ...[
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.cancel, color: Colors.red),
                                          onPressed: () => setState(() => _clearForm()),
                                        )
                                      ]
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 25),
                            const Divider(),

                            // ORDER ITEMS SECTION
                            if (orderItems.isNotEmpty) ...[
                              _buildSectionTitle("Items in Order"),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                      ),
                                      child: Row(
                                        children: const [
                                          Expanded(flex: 3, child: Text("Product", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                          Expanded(flex: 1, child: Text("Boxes", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                          Expanded(flex: 1, child: Text("Qty/Box", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                          Expanded(flex: 1, child: Text("Loose", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                          Expanded(flex: 1, child: Text("Price", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                          Expanded(flex: 1, child: Text("Total", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                          SizedBox(width: 80),
                                        ],
                                      ),
                                    ),
                                    const Divider(height: 1),
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: orderItems.length,
                                      separatorBuilder: (context, index) => const Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        final item = orderItems[index];
                                        final product = products.firstWhere((p) => p.id == item.productId);
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 3,
                                                child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                              ),
                                              Expanded(
                                                flex: 1,
                                                child: Text("${item.boxes}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
                                              ),
                                              Expanded(
                                                flex: 1,
                                                child: Text("${item.quantityPerBox}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
                                              ),
                                              Expanded(
                                                flex: 1,
                                                child: Text("${item.loosePieces}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
                                              ),
                                              Expanded(
                                                flex: 1,
                                                child: Text(item.sellingPrice.toStringAsFixed(2), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
                                              ),
                                              Expanded(
                                                flex: 1,
                                                child: Text(
                                                  item.totalPrice.toStringAsFixed(2),
                                                  textAlign: TextAlign.right,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 13),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 80,
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueGrey),
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                      onPressed: () => _editItem(index),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    IconButton(
                                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                      onPressed: () {
                                                        setState(() {
                                                          orderItems.removeAt(index);
                                                          if (_editingIndex == index) _clearForm();
                                                          _calculateTotals();
                                                        });
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 30),

                            // SUMMARY SECTION
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  _buildTotalRow("Order Total", grandTotal.toStringAsFixed(2)),
                                  const SizedBox(height: 12),
                                  if (selectedClient != null) ...[
                                    _buildTotalRow("Previous Balance", previousBalance.toStringAsFixed(2)),
                                    const SizedBox(height: 12),
                                  ],
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("Discount", style: TextStyle(color: Colors.blueGrey)),
                                      SizedBox(
                                        width: 100,
                                        height: 40,
                                        child: TextFormField(
                                          controller: _discountController,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.right,
                                          decoration: InputDecoration(
                                            isDense: true,
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                                  _buildTotalRow(
                                    "Net Total (Closing Balance)",
                                    netTotal.toStringAsFixed(2),
                                    isBold: true,
                                    color: Colors.blue,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 35),
                            SizedBox(
                              height: 55,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _saveOrder,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text("SAVE ORDER", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                            ),
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

  Widget _buildTotalRow(String label, String value, {bool isBold = false, bool isSmall = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : (isSmall ? 13 : 14),
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isSmall ? Colors.grey : Colors.blueGrey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : (isSmall ? 13 : 14),
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? (isSmall ? Colors.grey : Colors.blueGrey),
          ),
        ),
      ],
    );
  }
}
