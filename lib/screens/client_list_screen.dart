import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/client.dart';
import '../widgets/app_sidebar.dart';
import 'client_form_screen.dart';
import 'payment_form_screen.dart';
import 'payment_history_screen.dart';

class ClientListScreen extends StatefulWidget {
  final int userId;
  const ClientListScreen({super.key, required this.userId});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  List<Client> clients = [];
  List<Client> filteredClients = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadClients();
    _searchController.addListener(() {
      searchClients(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadClients() async {
    final list = await DatabaseHelper.instance.getClients(widget.userId);
    setState(() {
      clients = list;
      filteredClients = list;
      isLoading = false;
    });
  }

  void searchClients(String keyword) {
    final query = keyword.toLowerCase();
    setState(() {
      filteredClients = clients.where((client) {
        return client.name.toLowerCase().contains(query) ||
            client.phone.toLowerCase().contains(query) ||
            client.clientId.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> deleteClient(Client client) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Client"),
          content: Text("Are you sure you want to delete '${client.name}'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;
    await DatabaseHelper.instance.deleteClient(client.id!);
    loadClients();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Client deleted successfully.")),
    );
  }

  Widget buildClientCard(Client client) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        client.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                    Text(
                      "ID: ${client.clientId}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _infoRow(Icons.phone_outlined, client.phone),
                const SizedBox(height: 8),
                _infoRow(Icons.location_on_outlined, client.address),
                const SizedBox(height: 8),
                _infoRow(
                  Icons.account_balance_wallet_outlined,
                  "Balance: Rs. ${client.balance.toStringAsFixed(2)}",
                  textColor: Colors.red[700],
                  isBold: true,
                ),
                const SizedBox(height: 8),
                _infoRow(Icons.notes_outlined, client.notes.isEmpty ? "No notes" : client.notes),
                const SizedBox(height: 8),
                _infoRow(Icons.calendar_today_outlined, "Added: ${client.createdAt}"),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _actionButton(
                  label: "Pay",
                  color: Colors.green,
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PaymentFormScreen(client: client)),
                    );
                    if (result == true) loadClients();
                  },
                ),
                _actionButton(
                  label: "History",
                  color: Colors.amber[700]!,
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentHistoryScreen(userId: widget.userId, client: client),
                      ),
                    );
                  },
                ),
                _actionButton(
                  label: "Edit",
                  color: Colors.blue,
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClientFormScreen(userId: widget.userId, client: client),
                      ),
                    );
                    loadClients();
                  },
                ),
                _actionButton(
                  label: "Delete",
                  color: Colors.red,
                  onPressed: () => deleteClient(client),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? textColor, bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: textColor ?? Colors.black87,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          height: 32,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            userId: widget.userId,
            onRefresh: loadClients,
            currentPage: "clients",
          ),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: const Text("Clients"),
                centerTitle: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.black,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: loadClients,
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ClientFormScreen(userId: widget.userId)),
                  );
                  loadClients();
                },
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                extendedPadding: const EdgeInsets.symmetric(horizontal: 32),
                label: const Text(
                  "Add Client",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
              body: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search by name, phone or ID...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : filteredClients.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.people_outline, size: 80, color: Colors.grey),
                                      SizedBox(height: 15),
                                      Text("No Clients Found",
                                          style: TextStyle(fontSize: 22, color: Colors.grey)),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: filteredClients.length,
                                  itemBuilder: (context, index) {
                                    return buildClientCard(filteredClients[index]);
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
