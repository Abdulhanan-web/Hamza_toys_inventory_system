import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/client.dart';
import '../models/payment.dart';
import '../widgets/app_sidebar.dart';

class PaymentFormScreen extends StatefulWidget {
  final Client client;

  const PaymentFormScreen({super.key, required this.client});

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateController = TextEditingController(
    text: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
  );

  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final payment = Payment(
      clientId: widget.client.id!,
      amount: double.parse(_amountController.text),
      date: _dateController.text,
      notes: _notesController.text,
    );

    await DatabaseHelper.instance.insertPayment(payment);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment recorded successfully")),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            userId: widget.client.userId,
          ),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Text("Record Payment - ${widget.client.name}"),
                automaticallyImplyLeading: false,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            children: [
                              const Text("Current Balance", style: TextStyle(fontSize: 16)),
                              Text(
                                "Rs. ${widget.client.balance.toStringAsFixed(2)}",
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: "Amount Paid",
                          border: OutlineInputBorder(),
                          prefixText: "Rs. ",
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Please enter amount";
                          if (double.tryParse(value) == null) return "Enter a valid number";
                          if (double.parse(value) <= 0) return "Amount must be greater than 0";
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _dateController,
                        decoration: const InputDecoration(
                          labelText: "Date & Time",
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDate != null) {
                            TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (pickedTime != null) {
                              final fullDateTime = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                              _dateController.text = DateFormat('yyyy-MM-dd HH:mm:ss').format(fullDateTime);
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: "Notes (Optional)",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _savePayment,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text("SAVE PAYMENT", style: TextStyle(fontSize: 18)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
