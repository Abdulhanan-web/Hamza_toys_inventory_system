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
    bool isOptional = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        validator: (value) {
          if (!isOptional && (value == null || value.trim().isEmpty)) {
            return "$label is required";
          }

          if (value != null && value.trim().isNotEmpty) {
            if (label == "Phone Number") {
              if (value.length < 11) {
                return "Enter valid phone number";
              }
            }

            if (label == "Balance") {
              if (double.tryParse(value) == null) {
                return "Enter valid balance";
              }
            }
          }

          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          filled: readOnly,
          fillColor: readOnly ? Colors.grey.shade100 : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          suffixIcon: suffixIcon,
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
    } catch (e, stackTrace) {
      debugPrint("========== CLIENT ERROR ==========");
      debugPrint(e.toString());

      debugPrint("========== STACK TRACE ==========");
      debugPrint(stackTrace.toString());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error: $e"),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            userId: widget.userId,
            currentPage: "clients",
          ),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  isEdit ? "Edit Client" : "Add Client",
                ),
                centerTitle: true,
                automaticallyImplyLeading: !isEdit,
              ),
              body: Center(
                child: SizedBox(
                  width: 700,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(25),
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(25),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                            children: [
                              Icon(
                                isEdit
                                    ? Icons.person
                                    : Icons.person_add,
                                color: Colors.blue,
                                size: 70,
                              ),
                              const SizedBox(height: 15),
                              Text(
                                isEdit
                                    ? "Edit Client"
                                    : "Add New Client",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 35),
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
                              ),
                              buildField(
                                label: "Address",
                                controller: _addressController,
                                maxLines: 3,
                              ),
                              buildField(
                                label: "Balance",
                                controller: _balanceController,
                                keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                              ),
                              buildField(
                                label: "Notes",
                                controller: _notesController,
                                maxLines: 4,
                                isOptional: true,
                              ),
                              buildField(
                                label: "Created Date",
                                controller: _createdAtController,
                                readOnly: true,
                                onTap: _pickDate,
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.calendar_month,
                                  ),
                                  onPressed: _pickDate,
                                ),
                              ),
                              const SizedBox(height: 25),
                              SizedBox(
                                height: 55,
                                child: ElevatedButton.icon(
                                  onPressed:
                                  _isLoading ? null : _saveClient,
                                  icon: _isLoading
                                      ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child:
                                    CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                      : Icon(
                                    isEdit
                                        ? Icons.save
                                        : Icons.person_add,
                                  ),
                                  label: Text(
                                    _isLoading
                                        ? "Please wait..."
                                        : (isEdit
                                        ? "Update Client"
                                        : "Add Client"),
                                    style: const TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              if (isEdit) ...[
                                const SizedBox(height: 15),
                                SizedBox(
                                  height: 50,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    icon: const Icon(Icons.close),
                                    label: const Text("Cancel"),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
