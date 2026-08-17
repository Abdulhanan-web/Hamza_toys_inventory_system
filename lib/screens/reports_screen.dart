import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../widgets/app_sidebar.dart';

class ReportsScreen extends StatefulWidget {
  final int userId;

  const ReportsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool isLoading = true;

  double totalClientBalance = 0;
  double totalInventoryValue = 0;
  double totalProfit = 0;
  int totalBoxes = 0;
  int totalOrders = 0;

  double periodSpending = 0;
  double periodSales = 0;

  DateTimeRange? selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => isLoading = true);

    final balance = await DatabaseHelper.instance.getTotalClientBalance(widget.userId);
    final invValue = await DatabaseHelper.instance.getTotalInventoryValue(widget.userId);
    final profit = await DatabaseHelper.instance.getTotalProfit(widget.userId);
    final boxes = await DatabaseHelper.instance.getTotalBoxes(widget.userId);
    final orderCount = await DatabaseHelper.instance.getOrderCount(widget.userId);

    setState(() {
      totalClientBalance = balance;
      totalInventoryValue = invValue;
      totalProfit = profit;
      totalBoxes = boxes;
      totalOrders = orderCount;
      isLoading = false;
    });
  }

  Future<void> _loadPeriodReports() async {
    if (selectedDateRange == null) return;

    final start = DateFormat('yyyy-MM-dd').format(selectedDateRange!.start);
    final end = DateFormat('yyyy-MM-dd').format(selectedDateRange!.end);

    final spending = await DatabaseHelper.instance.getSpendingByDate(widget.userId, start, end);
    final sales = await DatabaseHelper.instance.getSalesByDate(widget.userId, start, end);

    setState(() {
      periodSpending = spending;
      periodSales = sales;
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
      });
      _loadPeriodReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            userId: widget.userId,
            onRefresh: _loadSummary,
            currentPage: "reports",
          ),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: const Text("Detailed Reports"),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadSummary,
                  ),
                ],
              ),
              body: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Financial Summary", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 15),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.5,
                            children: [
                              _buildReportCard("Client Balances", totalClientBalance, Colors.red, Icons.account_balance_wallet),
                              _buildReportCard("Inventory Value", totalInventoryValue, Colors.blue, Icons.inventory),
                              _buildReportCard("Total Profit", totalProfit, Colors.green, Icons.trending_up),
                              _buildReportCard("Total Orders", totalOrders.toDouble(), Colors.orange, Icons.shopping_cart, isInteger: true),
                            ],
                          ),
                          const SizedBox(height: 30),
                          const Divider(),
                          const SizedBox(height: 15),
                          const Text("Inventory Health", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.all_inbox, size: 40, color: Colors.blueGrey),
                              title: const Text("Total Boxes in Stock"),
                              trailing: Text("$totalBoxes", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Divider(),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Period Reports", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ElevatedButton.icon(
                                onPressed: _selectDateRange,
                                icon: const Icon(Icons.date_range),
                                label: Text(selectedDateRange == null 
                                  ? "Select Dates" 
                                  : "${DateFormat('MMM d').format(selectedDateRange!.start)} - ${DateFormat('MMM d').format(selectedDateRange!.end)}"),
                                style: ElevatedButton.styleFrom(minimumSize: const Size(100, 40)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          if (selectedDateRange != null) ...[
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    _buildPeriodRow("Spending (Purchases)", periodSpending, Colors.red),
                                    const Divider(height: 20),
                                    _buildPeriodRow("Sales (Orders)", periodSales, Colors.green),
                                    const Divider(height: 20),
                                    _buildPeriodRow("Net Cash Flow", periodSales - periodSpending, 
                                      (periodSales - periodSpending) >= 0 ? Colors.green : Colors.red, isBold: true),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text("Select a date range to see spending and sales.", style: TextStyle(color: Colors.grey)),
                              ),
                            ),
                          ],
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, double value, Color color, IconData icon, {bool isInteger = false}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const Spacer(),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                isInteger ? value.toInt().toString() : "Rs. ${value.toStringAsFixed(2)}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodRow(String label, double value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text("Rs. ${value.toStringAsFixed(2)}", 
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
