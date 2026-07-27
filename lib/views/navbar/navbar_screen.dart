import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zyvionix_pos/database/hive_boxes.dart';
import 'package:zyvionix_pos/provider/navbar/navbar_provider.dart';
import 'package:zyvionix_pos/views/billing/billing_screen.dart';
import 'package:zyvionix_pos/views/home_screen.dart';
import 'package:zyvionix_pos/views/profile/profile_screen.dart';
import 'package:zyvionix_pos/widgets/subscription_modal.dart';

class NavbarScreen extends StatefulWidget {
  const NavbarScreen({super.key});

  @override
  State<NavbarScreen> createState() => _NavbarScreenState();
}

class _NavbarScreenState extends State<NavbarScreen> {
  static const List<Widget> _pages = [
    HomeScreen(),
    BillingScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSubscription();
    });
  }

  Future<void> _checkSubscription() async {
    final box = HiveBoxes.getSettingsBox();
    final storageType = box.get('storageType', defaultValue: 'Device Storage');
    final hasShown = box.get('subscriptionModalShown', defaultValue: false);

    if (storageType == 'Cloud Storage' && !hasShown) {
      await box.put('subscriptionModalShown', true);
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const SubscriptionModal(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<BottomNavbarProvider>();
    final currentIndex = navProvider.currentIndex;
    final bool showNavBar = currentIndex != 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      extendBody: true,
      body: _pages[currentIndex],
      floatingActionButton: showNavBar
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF165FF2),
              shape: const CircleBorder(),
              elevation: 4,
              onPressed: () => navProvider.setIndex(1),
              child: const Icon(
                Icons.post_add_rounded,
                color: Colors.white,
                size: 28,
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: showNavBar
          ? BottomAppBar(
              color: Colors.white,
              shape: const CircularNotchedRectangle(),
              notchMargin: 10.0,
              elevation: 16,
              shadowColor: Colors.black45,
              child: SizedBox(
                height: 65,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      isSelected: currentIndex == 0,
                      onTap: () => navProvider.setIndex(0),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const SizedBox(height: 28),
                        Text(
                          'New Bill',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    _buildNavItem(
                      icon: Icons.menu_rounded,
                      label: 'Menu',
                      isSelected: currentIndex == 2,
                      onTap: () => navProvider.setIndex(2),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final Color color = isSelected
        ? const Color(0xFF165FF2)
        : Colors.grey.shade600;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
