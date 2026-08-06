import 'package:flutter/material.dart';
import 'package:zyvionix_pos/database/hive_boxes.dart';
import 'package:zyvionix_pos/widgets/primary_button.dart';
import 'package:floating_snackbar/floating_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:zyvionix_pos/controllers/product_controller.dart';
import 'package:zyvionix_pos/controllers/bill_controller.dart';
import 'package:zyvionix_pos/views/employees/manage_employees_screen.dart';

class ShopDashboardScreen extends StatelessWidget {
  final dynamic shop;
  final bool isActive;
  final VoidCallback onStatusChanged;

  const ShopDashboardScreen({
    super.key,
    required this.shop,
    required this.isActive,
    required this.onStatusChanged,
  });

  Future<void> _setActiveShop(BuildContext context) async {
    final box = HiveBoxes.getSettingsBox();
    await box.put('shop_id', shop['_id']);
    await box.put('shop_name', shop['name']);
    await box.put('current_shop_id', shop['_id']);
    
    if (context.mounted) {
      context.read<ProductController>().init();
      context.read<BillController>().init();
      
      floatingSnackBar(
        message: 'Active shop changed successfully',
        context: context,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      onStatusChanged();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: Text(
          shop['name'] ?? 'Shop Dashboard',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1EA1F2), Color(0xFF0C79C9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1EA1F2).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.storefront_rounded, color: Colors.white, size: 40),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'CURRENT ACTIVE',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      shop['name'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    if (shop['address'] != null && shop['address'].isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        shop['address'],
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              if (!isActive) ...[
                PrimaryButton(
                  text: 'Set as Active Shop',
                  onPressed: () => _setActiveShop(context),
                ),
                const SizedBox(height: 30),
              ],

              const Text(
                'Management',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              
              _buildMenuCard(
                children: [
                  _buildMenuItem(
                    icon: Icons.people_outline_rounded,
                    iconColor: Colors.deepPurple,
                    title: 'Employees',
                    subtitle: 'Manage staff for this shop',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ManageEmployeesScreen(shopId: shop['_id'])));
                    },
                  ),
                  _divider(),
                  _buildMenuItem(
                    icon: Icons.bar_chart_rounded,
                    iconColor: Colors.orange,
                    title: 'Reports & Analytics',
                    subtitle: 'View sales and performance',
                    onTap: () {
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => const ShopReportsScreen()));
                      floatingSnackBar(message: 'Coming soon', context: context);
                    },
                  ),
                  _divider(),
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    iconColor: Colors.blueGrey,
                    title: 'Shop Settings',
                    subtitle: 'Edit details and preferences',
                    onTap: () {
                      floatingSnackBar(message: 'Coming soon', context: context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade100,
      indent: 60,
    );
  }
}
