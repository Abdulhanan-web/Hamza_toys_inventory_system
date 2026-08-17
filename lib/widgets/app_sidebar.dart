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
  final String currentPage;

  const AppSidebar({
    super.key,
    required this.userId,
    this.username,
    this.onRefresh,
    this.currentPage = "",
  });

  Widget sidebarButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
    Color activeColor = Colors.blue,
    Color inactiveColor = Colors.white,
  }) {
    final displayColor = isActive ? activeColor : inactiveColor;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? activeColor.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: displayColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: displayColor,
            fontSize: 16,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
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
              isActive: currentPage == "dashboard",
              onTap: () {
                if (currentPage == "dashboard") {
                  onRefresh?.call();
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeScreen(
                        userId: userId,
                        username: username ?? "User",
                      ),
                    ),
                  );
                }
              },
            ),
            sidebarButton(
              icon: Icons.add_box,
              title: "Add Product",
              isActive: currentPage == "add_product",
              onTap: () async {
                if (currentPage == "add_product") return;
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
              isActive: currentPage == "clients",
              onTap: () async {
                if (currentPage == "clients") return;
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
              isActive: currentPage == "add_order",
              onTap: () async {
                if (currentPage == "add_order") return;
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
              isActive: currentPage == "view_orders",
              onTap: () async {
                if (currentPage == "view_orders") return;
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
              isActive: currentPage == "payment_history",
              onTap: () async {
                if (currentPage == "payment_history") return;
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
              isActive: currentPage == "reports",
              onTap: () async {
                if (currentPage == "reports") return;
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
              isActive: false,
              inactiveColor: Colors.redAccent,
              onTap: () => logout(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
