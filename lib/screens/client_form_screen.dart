// lib/screens/client_form_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/client.dart';
import '../widgets/app_sidebar.dart';

class ClientFormScreen extends StatefulWidget {
  final int userId;
  final Client? client;

  const ClientFormScreen({
    super.key,
    required this.userId,
    this.client,
  });

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _clientIdController;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _balanceController;
  late final TextEditingController _notesController;
  late final TextEditingController _createdAtController;

  bool _isLoading = false;

  bool get isEdit => widget.client != null;

  @override
  void initState() {
    super.initState();

    _clientIdController = TextEditingController(
      text: widget.client?.clientId ?? "CLI-${DateTime.now().millisecondsSinceEpoch}",
    );

    _nameController = TextEditingController(
      text: widget.client?.name ?? "",
    );

    _phoneController = TextEditingController(
      text: widget.client?.phone ?? "",
    );

    _addressController = TextEditingController(
      text: widget.client?.address ?? "",
    );

    _balanceController = TextEditingController(
      text: widget.client?.balance.toString() ?? "0",
    );

    _notesController = TextEditingController(
      text: widget.client?.notes ?? "",
    );

    _createdAtController = TextEditingController(
      text: widget.client?.createdAt ??
          DateFormat("yyyy-MM-dd").format(DateTime.now()),
    );
  }

  @override
  void dispose() {
    _clientIdController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _balanceController.dispose();
    _notesController.dispose();
    _createdAtController.dispose();

    super.dispose();
  }

  Future<void> _pickDate() async {
    final initialDate =
        DateTime.tryParse(_createdAtController.text) ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      _createdAtController.text =
          DateFormat("yyyy-MM-dd").format(picked);
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
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        validator: validator ?? (value) {
          if (value == null || value.trim().isEmpty) {
            return "$label is required";
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 14),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final client = Client(
        id: widget.client?.id,
        userId: widget.userId,
        clientId: _clientIdController.text.trim(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        balance: double.parse(_balanceController.text),
        notes: _notesController.text.trim(),
        createdAt: _createdAtController.text,
      );

      if (isEdit) {
        await DatabaseHelper.instance.updateClient(client);
      } else {
        await DatabaseHelper.instance.insertClient(client);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            isEdit
                ? "Client updated successfully."
                : "Client added successfully.",
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error: $e"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          AppSidebar(
            userId: widget.userId,
            currentPage: "clients",
          ),
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  Positioned(
                    top: 20,
                    left: 20,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                      color: Colors.blueGrey,
                    ),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                        child: Container(
                          padding: const EdgeInsets.all(35),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  isEdit ? "Update Client" : "New Client",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blueGrey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 30),
                                buildField(
                                  label: "Client ID",
                                  controller: _clientIdController,
                                  readOnly: true,
                                ),
                                buildField(
                                  label: "Client Name",
                                  controller: _nameController,
                                ),
                                buildField(
                                  label: "Phone Number",
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return "Phone number is required";
                                    }
                                    if (value.trim().length < 11) {
                                      return "Enter valid phone number";
                                    }
                                    return null;
                                  },
                                ),
                                buildField(
                                  label: "Address",
                                  controller: _addressController,
                                  maxLines: 2,
                                ),
                                buildField(
                                  label: "Opening Balance",
                                  controller: _balanceController,
                                  keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return "Balance is required";
                                    }
                                    if (double.tryParse(value) == null) {
                                      return "Enter valid balance";
                                    }
                                    return null;
                                  },
                                ),
                                buildField(
                                  label: "Notes",
                                  controller: _notesController,
                                  maxLines: 2,
                                  validator: (value) => null,
                                ),
                                buildField(
                                  label: "Created Date",
                                  controller: _createdAtController,
                                  readOnly: true,
                                  onTap: _pickDate,
                                  suffixIcon: const Icon(Icons.calendar_today, size: 20),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 55,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _saveClient,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            isEdit ? "Update Client" : "Add Client",
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                if (isEdit) ...[
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      "Cancel",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
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
