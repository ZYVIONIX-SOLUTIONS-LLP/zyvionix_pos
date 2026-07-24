import 'package:flutter/material.dart';
import 'package:zyvionix_pos/views/billing/bill_hystory.dart';
import 'package:zyvionix_pos/views/notifications/notification_screen.dart';
import 'package:zyvionix_pos/views/profile/edit_profile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        MaterialPageRoute(builder: (context) => BillHystory()),
                      );
                    },
                  ),
                  _divider(),
                  _buildMenuItem(
                    icon: Icons.person_outline_rounded,
                    iconColor: Colors.blue,
                    title: 'Edit Profile',
                    subtitle: 'Update your personal information',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditProfile()),
                      );
                    },
                  ),
                  _divider(),
                  _buildMenuItem(
                    icon: Icons.notifications_none_rounded,
                    iconColor: Colors.orange,
                    title: 'Notifications',
                    subtitle: 'Manage notification preferences',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationScreen(),
                        ),
                      );
                    },
                  ),
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
                    onTap: () {
                      // Navigate to Privacy Policy screen
                    },
                  ),
                  _divider(),
                  _buildMenuItem(
                    icon: Icons.description_outlined,
                    iconColor: Colors.indigo,
                    title: 'Terms & Conditions',
                    onTap: () {
                      // Navigate to Terms & Conditions screen
                    },
                  ),
                  _divider(),
                  _buildMenuItem(
                    icon: Icons.help_outline_rounded,
                    iconColor: Colors.green,
                    title: 'Help & Support',
                    onTap: () {
                      // Navigate to Help & Support screen
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
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
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.deepPurple.shade100,
                    width: 3,
                  ),
                ),
                child: const CircleAvatar(
                  radius: 48,
                  backgroundColor: Color(0xFFEDEBFF),
                  backgroundImage: NetworkImage('https://i.pravatar.cc/300'),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    // Handle image edit/upload
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Melvin Cherian',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'melvincherian@gmail.com',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // // ---------- STATS ROW ----------
  // Widget _buildStatsRow() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 20),
  //     child: Row(
  //       children: [
  //         Expanded(
  //           child: _statCard(
  //             '24',
  //             'Total Bills',
  //             Icons.receipt_rounded,
  //             Colors.deepPurple,
  //           ),
  //         ),
  //         const SizedBox(width: 12),
  //         Expanded(
  //           child: _statCard(
  //             '₹12.4k',
  //             'This Month',
  //             Icons.currency_rupee_rounded,
  //             Colors.orange,
  //           ),
  //         ),
  //         const SizedBox(width: 12),
  //         Expanded(
  //           child: _statCard(
  //             '3',
  //             'Pending',
  //             Icons.pending_actions_rounded,
  //             Colors.blue,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _statCard(String value, String label, IconData icon, Color color) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(16),
  //       boxShadow: const [
  //         BoxShadow(
  //           color: Color(0x0A000000),
  //           blurRadius: 8,
  //           offset: Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       children: [
  //         Icon(icon, color: color, size: 22),
  //         const SizedBox(height: 8),
  //         Text(
  //           value,
  //           style: const TextStyle(
  //             fontSize: 15,
  //             fontWeight: FontWeight.bold,
  //             color: Color(0xFF1E1E1E),
  //           ),
  //         ),
  //         const SizedBox(height: 2),
  //         Text(
  //           label,
  //           textAlign: TextAlign.center,
  //           style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
  //         ),
  //       ],
  //     ),
  //   );
  // }

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
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
