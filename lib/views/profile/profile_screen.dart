// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:zyvionix_pos/database/hive_boxes.dart';
import 'package:zyvionix_pos/provider/navbar/navbar_provider.dart';
import 'package:zyvionix_pos/views/history/bill_history_screen.dart';
// import 'package:zyvionix_pos/views/notifications/notification_screen.dart';
import 'package:zyvionix_pos/views/profile/edit_profile.dart';
import 'package:zyvionix_pos/views/settings/active_plan_screen.dart';
import 'package:zyvionix_pos/views/profile/help_screen.dart';
import 'package:zyvionix_pos/views/auth/login_screen.dart';
import 'package:zyvionix_pos/views/shops/manage_shops_screen.dart';
import 'package:zyvionix_pos/services/api_service.dart';
import 'package:zyvionix_pos/provider/auth_provider.dart';
import 'package:zyvionix_pos/views/settings/upgrade_plan_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:zyvionix_pos/constants/api_constants.dart';
import 'package:zyvionix_pos/provider/auth_provider.dart';
import 'package:zyvionix_pos/controllers/product_controller.dart';
import 'package:zyvionix_pos/controllers/bill_controller.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = ApiService.getProfile();
  }

  void _refreshProfile() {
    setState(() {
      _profileFuture = ApiService.getProfile();
    });
  }

  Future<void> _handleConvertToCloud(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UpgradePlanScreen()),
    );
    if (result == true) {
      _refreshProfile();
      setState(() {});
    }
  }

  Future<void> _showShopSelectionDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final box = HiveBoxes.getSettingsBox();
      final token = box.get('auth_token');
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/shops'),
        headers: {'Authorization': 'Bearer $token'},
      );

      Navigator.pop(context); // close loading

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List shops = data['data'];
        final currentShopId = box.get('current_shop_id');

        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('Select Shop'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: shops.length,
                  itemBuilder: (context, index) {
                    final shop = shops[index];
                    return RadioListTile<String>(
                      title: Text(shop['name']),
                      subtitle: Text(shop['address'] ?? ''),
                      value: shop['_id'],
                      groupValue: currentShopId,
                      onChanged: (value) async {
                        await box.put('current_shop_id', value);
                        await box.put('shop_name', shop['name']);
                        await box.put('shop_id', value);
                        await box.put(
                          'offline_company_address',
                          shop['address'] ?? '',
                        );
                        await box.put('shop_mobile', shop['mobile'] ?? '');
                        if (mounted) {
                          context.read<ProductController>().init();
                          context.read<BillController>().init();
                          setState(() {});
                          Navigator.pop(ctx);
                          showTopSnackBar(
                            Overlay.of(context),
                            CustomSnackBar.info(
                              message: 'Switched to ${shop['name']}',
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      } else {
        if (mounted) {
          showTopSnackBar(
            Overlay.of(context),
            const CustomSnackBar.error(message: 'Failed to fetch shops'),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context); // close loading
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.error(message: 'Network error'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = HiveBoxes.getSettingsBox();
    final storageType = box.get('storageType', defaultValue: 'Device Storage');
    final isEmployee = box.get('user_role') == 'Employee';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.read<BottomNavbarProvider>().setIndex(0);
      },

      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildSectionTitle('Account'),
                _buildMenuCard(
                  children: [
                    _buildMenuItem(
                      icon: Icons.receipt_long_rounded,
                      iconColor: Colors.deepPurple,
                      title: 'Bill History',
                      subtitle: 'View all your past bills',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BillHistoryScreen(),
                          ),
                        );
                      },
                    ),
                    if (!isEmployee) ...[
                      _divider(),
                      _buildMenuItem(
                        icon: Icons.person_outline_rounded,
                        iconColor: Colors.blue,
                        title: 'Edit Profile',
                        subtitle: 'Update your personal information',
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfile(),
                            ),
                          );

                          if (result == true) {
                            _refreshProfile();
                          }
                        },
                      ),
                      _divider(),
                      _buildMenuItem(
                        icon: Icons.cloud_circle_rounded,
                        iconColor: const Color(0xFF1EA1F2),
                        title: 'Subscription Plans',
                        subtitle: 'View and upgrade cloud plans',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ActivePlanScreen(),
                            ),
                          );
                        },
                      ),
                      if (storageType == 'Device Storage') ...[
                        _divider(),
                        _buildMenuItem(
                          icon: Icons.cloud_upload_rounded,
                          iconColor: Colors.blueAccent,
                          title: 'Convert to Cloud',
                          subtitle:
                              'Backup and sync all offline data to the cloud',
                          onTap: () {
                            _handleConvertToCloud(context);
                          },
                        ),
                      ],
                    ],
                    if (storageType == 'Cloud Storage' &&
                        box.get('user_role') == 'Owner') ...[
                      _divider(),
                      _buildMenuItem(
                        icon: Icons.storefront_rounded,
                        iconColor: Colors.deepOrange,
                        title: 'Manage Shops',
                        subtitle: 'View and manage your shops',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ManageShopsScreen(),
                            ),
                          ).then((_) {
                            _refreshProfile();
                          });
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('Legal'),
                _buildMenuCard(
                  children: [
                    _buildMenuItem(
                      icon: Icons.privacy_tip_outlined,
                      iconColor: Colors.teal,
                      title: 'Privacy Policy',
                      onTap: () {},
                    ),
                    _divider(),
                    _buildMenuItem(
                      icon: Icons.description_outlined,
                      iconColor: Colors.indigo,
                      title: 'Terms & Conditions',
                      onTap: () {},
                    ),
                    _divider(),
                    _buildMenuItem(
                      icon: Icons.help_outline_rounded,
                      iconColor: Colors.green,
                      title: 'Help & Support',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HelpScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('Session'),
                _buildMenuCard(
                  children: [
                    _buildMenuItem(
                      icon: Icons.logout_rounded,
                      iconColor: Colors.redAccent,
                      title: 'Logout',
                      titleColor: Colors.redAccent,
                      showArrow: false,
                      onTap: () {
                        _showLogoutDialog(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'App Version 1.0.0',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      // future: ApiService.getProfile(),
      future: _profileFuture,

      builder: (context, snapshot) {
        final profile = snapshot.data;
        final companyName =
            profile?['companyName'] ??
            HiveBoxes.getSettingsBox().get(
              'shop_name',
              defaultValue: 'Zyvionix Solutions',
            );
        final email =
            profile?['email'] ??
            HiveBoxes.getSettingsBox().get('user_email', defaultValue: '');
        final mobile =
            profile?['mobileNumber'] ??
            HiveBoxes.getSettingsBox().get('user_phone', defaultValue: '');
        final address =
            profile?['companyAddress'] ??
            HiveBoxes.getSettingsBox().get(
              'offline_company_address',
              defaultValue: '',
            );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.only(
            top: 16,
            bottom: 30,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
                  onPressed: () {
                    context.read<BottomNavbarProvider>().setIndex(0);
                  },
                ),
              ),
              Column(
                children: [
                  const SizedBox(height: 14),
                  Text(
                    companyName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  if (mobile.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Phone: $mobile',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  if (address.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        address,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
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
    Color? titleColor,
    bool showArrow = true,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? const Color(0xFF1E1E1E),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showArrow)
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      indent: 60,
      endIndent: 16,
      color: Colors.grey.shade200,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              context.read<ProductController>().clear();
              context.read<BillController>().clear();
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                showTopSnackBar(
                  Overlay.of(context),
                  const CustomSnackBar.success(
                    backgroundColor: Colors.red,
                    message: 'Logged out successfully',
                  ),
                  displayDuration: const Duration(seconds: 2),
                );

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
