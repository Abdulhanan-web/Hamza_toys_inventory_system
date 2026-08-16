import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/client.dart';
import '../models/payment.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final Client client;

  const PaymentHistoryScreen({super.key, required this.client});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<Payment> payments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => isLoading = true);
    final data = await DatabaseHelper.instance.getPaymentsByClient(widget.client.id!);
    setState(() {
      payments = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Payment History - ${widget.client.name}"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : payments.isEmpty
              ? const Center(
                  child: Text("No payment records found for this client."),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.payment, color: Colors.green),
                        title: Text(
                          "Amount: Rs. ${payment.amount.toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Date: ${payment.date}"),
                            if (payment.notes.isNotEmpty) Text("Notes: ${payment.notes}"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
