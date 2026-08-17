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
          content: Text(
            "Are you sure you want to delete '${client.name}'?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
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
      const SnackBar(
        content: Text(
          "Client deleted successfully.",
        ),
      ),
    );
  }

  Widget buildClientCard(Client client) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "Client ID : ${client.clientId}",
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            Row(
              children: [
                const Icon(Icons.phone, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(client.phone),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(client.address),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  "Balance : Rs. ${client.balance.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    client.notes.isEmpty ? "No notes" : client.notes,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(client.createdAt),
              ],
            ),
            const SizedBox(height: 25),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentFormScreen(client: client),
                      ),
                    );
                    if (result == true) {
                      loadClients();
                    }
                  },
                  icon: const Icon(Icons.add_card),
                  label: const Text("Pay"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentHistoryScreen(
                          userId: widget.userId,
                          client: client,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history),
                  label: const Text("History"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClientFormScreen(
                          userId: widget.userId,
                          client: client,
                        ),
                      ),
                    );
                    loadClients();
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit"),
                ),
                OutlinedButton.icon(
                  onPressed: () => deleteClient(client),
                  icon: const Icon(Icons.delete),
                  label: const Text("Delete"),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                ),
              ],
            ),
          ],
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
                    MaterialPageRoute(
                      builder: (_) => ClientFormScreen(userId: widget.userId),
                    ),
                  );
                  loadClients();
                },
                icon: const Icon(Icons.person_add),
                label: const Text("Add Client"),
              ),
              body: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search by name, phone or client ID...",
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  searchClients("");
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: isLoading
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : filteredClients.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.people_outline,
                                        size: 80,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 15),
                                      Text(
                                        "No Clients Found",
                                        style: TextStyle(
                                          fontSize: 22,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: filteredClients.length,
                                  itemBuilder: (context, index) {
                                    return buildClientCard(
                                      filteredClients[index],
                                    );
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
