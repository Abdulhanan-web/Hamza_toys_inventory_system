import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/client.dart';
import '../models/payment.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final int userId;
  final Client? client; // Optional: if null, show all payments for userId

  const PaymentHistoryScreen({
    super.key,
    required this.userId,
    this.client,
  });

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<Map<String, dynamic>> allPayments = []; // Stores payment + clientName
  List<Map<String, dynamic>> filteredPayments = [];
  bool isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadPayments();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    setState(() => isLoading = true);
    
    if (widget.client != null) {
      // Load specific client payments
      final data = await DatabaseHelper.instance.getPaymentsByClient(widget.client!.id!);
      allPayments = data.map((p) => {
        ...p.toMap(),
        'clientName': widget.client!.name,
      }).toList();
    } else {
      // Load all payments for the user
      allPayments = await DatabaseHelper.instance.getAllPaymentsWithClientNames(widget.userId);
    }

    setState(() {
      filteredPayments = allPayments;
      isLoading = false;
    });
  }

  void _applyFilters() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredPayments = allPayments.where((p) {
        // Search by Client Name
        final nameMatch = p['clientName'].toString().toLowerCase().contains(query);
        
        // Date Filtering
        bool dateMatch = true;
        if (p['date'] != null) {
          try {
            // Payment date format is yyyy-MM-dd HH:mm:ss or yyyy-MM-dd
            DateTime pDate = DateTime.parse(p['date'].toString());
            // Normalize dates to year-month-day for comparison
            DateTime normalizedPDate = DateTime(pDate.year, pDate.month, pDate.day);

            if (_startDate != null && _endDate != null) {
              dateMatch = normalizedPDate.isAtSameMomentAs(_startDate!) || 
                          normalizedPDate.isAtSameMomentAs(_endDate!) ||
                          (normalizedPDate.isAfter(_startDate!) && normalizedPDate.isBefore(_endDate!));
            } else if (_startDate != null) {
              dateMatch = normalizedPDate.isAtSameMomentAs(_startDate!) || normalizedPDate.isAfter(_startDate!);
            }
          } catch (e) {
            debugPrint("Error parsing date: $e");
          }
        }

        return nameMatch && dateMatch;
      }).toList();
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _startDate != null && _endDate != null 
          ? DateTimeRange(start: _startDate!, end: _endDate!) 
          : null,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.start.year, picked.start.month, picked.start.day);
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day);
      });
      _applyFilters();
    }
  }

  Future<void> _selectSingleDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.year, picked.month, picked.day);
        _endDate = DateTime(picked.year, picked.month, picked.day);
      });
      _applyFilters();
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _startDate = null;
      _endDate = null;
      filteredPayments = allPayments;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.client != null 
            ? "Payment History - ${widget.client!.name}" 
            : "All Payments History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayments,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search Client Name...",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectSingleDate,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(_startDate != null && _startDate == _endDate
                            ? DateFormat('MMM dd, yyyy').format(_startDate!)
                            : "Select Date"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectDateRange,
                        icon: const Icon(Icons.date_range, size: 18),
                        label: Text(_startDate != null && _endDate != null && _startDate != _endDate
                            ? "${DateFormat('MMM dd').format(_startDate!)} - ${DateFormat('MMM dd').format(_endDate!)}"
                            : "Date Range"),
                      ),
                    ),
                    if (_startDate != null || _searchController.text.isNotEmpty)
                      IconButton(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.filter_alt_off, color: Colors.red),
                        tooltip: "Clear Filters",
                      ),
                  ],
                ),
              ],
            ),
          ),

          // List Section
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredPayments.isEmpty
                    ? const Center(child: Text("No payments found for the selected criteria."))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredPayments.length,
                        itemBuilder: (context, index) {
                          final p = filteredPayments[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.green,
                                child: Icon(Icons.currency_rupee, color: Colors.white, size: 20),
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      p['clientName'] ?? "Unknown Client",
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Text(
                                    "Rs. ${p['amount'].toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(p['date'] ?? ""),
                                      ],
                                    ),
                                    if (p['notes'] != null && p['notes'].toString().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2.0),
                                        child: Text("Note: ${p['notes']}"),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
