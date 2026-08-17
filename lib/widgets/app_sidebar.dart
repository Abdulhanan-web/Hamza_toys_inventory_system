import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/product_form_screen.dart';
import '../screens/client_list_screen.dart';
import '../screens/order_form_screen.dart';
import '../screens/order_list_screen.dart';
import '../screens/payment_history_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/login_screen.dart';

class AppSidebar extends StatelessWidget {
  final int userId;
  final String? username;
  final VoidCallback? onRefresh;

  const AppSidebar({
    super.key,
    required this.userId,
    this.username,
    this.onRefresh,
  });

  Widget sidebarButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }

  void logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: Colors.blueGrey.shade900,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(
              Icons.inventory,
              color: Colors.white,
              size: 60,
            ),
            const SizedBox(height: 10),
            const Text(
              "Inventory System",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(
              color: Colors.white24,
              height: 40,
            ),
            sidebarButton(
              icon: Icons.dashboard,
              title: "Dashboard",
              onTap: () {
                if (ModalRoute.of(context)?.settings.name == '/home') {
                   onRefresh?.call();
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeScreen(
                        userId: userId,
                        username: username ?? "User",
                      ),
                      settings: const RouteSettings(name: '/home'),
                    ),
                  );
                }
              },
            ),
            sidebarButton(
              icon: Icons.add_box,
              title: "Add Product",
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductFormScreen(userId: userId),
                  ),
                );
                onRefresh?.call();
              },
            ),
            sidebarButton(
              icon: Icons.people,
              title: "Clients",
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClientListScreen(userId: userId),
                  ),
                );
                onRefresh?.call();
              },
            ),
            sidebarButton(
              icon: Icons.shopping_cart,
              title: "Add Order",
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderFormScreen(userId: userId),
                  ),
                );
                onRefresh?.call();
              },
            ),
            sidebarButton(
              icon: Icons.list_alt,
              title: "View Orders",
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderListScreen(userId: userId),
                  ),
                );
                onRefresh?.call();
              },
            ),
            sidebarButton(
              icon: Icons.history,
              title: "Payment History",
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentHistoryScreen(userId: userId),
                  ),
                );
                onRefresh?.call();
              },
            ),
            sidebarButton(
              icon: Icons.bar_chart,
              title: "Reports",
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportsScreen(userId: userId),
                  ),
                );
                onRefresh?.call();
              },
            ),
            const Spacer(),
            const Divider(
              color: Colors.white24,
            ),
            sidebarButton(
              icon: Icons.logout,
              title: "Logout",
              color: Colors.redAccent,
              onTap: () => logout(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
