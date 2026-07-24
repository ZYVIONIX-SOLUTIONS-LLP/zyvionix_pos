// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:zyvionix_pos/provider/navbar/navbar_provider.dart';
// import 'package:zyvionix_pos/views/billing/billing_screen.dart';
// import 'package:zyvionix_pos/views/home_screen.dart';
// import 'package:zyvionix_pos/views/profile/profile_screen.dart';

// class NavbarScreen extends StatelessWidget {
//   const NavbarScreen({super.key});

//   static const List<Widget> _pages = [
//     HomeScreen(),
//     BillingScreen(),
//     ProfileScreen(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     final navProvider = context.watch<BottomNavbarProvider>();

//     final currentIndex = navProvider.currentIndex;

//     final bool showNavBar = currentIndex != 1;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       extendBody: true,
//       body: _pages[navProvider.currentIndex],

//       // bottomNavigationBar: const CustomBottomNavBar(),
//       bottomNavigationBar: showNavBar ? const CustomBottomNavBar() : null,
//     );
//   }
// }

// class CustomBottomNavBar extends StatelessWidget {
//   const CustomBottomNavBar({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final navProvider = context.watch<BottomNavbarProvider>();
//     final currentIndex = navProvider.currentIndex;

//     return SizedBox(
//       height: 90,
//       child: Stack(
//         alignment: Alignment.bottomCenter,
//         clipBehavior: Clip.none,
//         children: [
//           Container(
//             margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//             height: 65,
//             decoration: BoxDecoration(
//               color: const Color(0xFF1E1E1E),
//               borderRadius: BorderRadius.circular(18),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.2),
//                   blurRadius: 10,
//                   offset: const Offset(0, 5),
//                 ),
//               ],
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 _NavItem(
//                   icon: Icons.home_rounded,
//                   label: 'Home',
//                   isSelected: currentIndex == 0,
//                   onTap: () => navProvider.setIndex(0),
//                 ),
//                 const SizedBox(width: 60),
//                 _NavItem(
//                   icon: Icons.person_rounded,
//                   label: 'Profile',
//                   isSelected: currentIndex == 2,
//                   onTap: () => navProvider.setIndex(2),
//                 ),
//               ],
//             ),
//           ),

//           Positioned(
//             bottom: 40,
//             child: GestureDetector(
//               onTap: () => navProvider.setIndex(1),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Container(
//                     height: 65,
//                     width: 65,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Colors.deepPurple,
//                       border: Border.all(color: Colors.white, width: 4),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.deepPurple.withOpacity(0.4),
//                           blurRadius: 12,
//                           offset: const Offset(0, 4),
//                         ),
//                       ],
//                     ),
//                     child: const Icon(
//                       Icons.receipt_long_rounded,
//                       color: Colors.white,
//                       size: 30,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _NavItem extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final bool isSelected;
//   final VoidCallback onTap;

//   const _NavItem({
//     required this.icon,
//     required this.label,
//     required this.isSelected,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final color = isSelected
//         ? const Color.fromARGB(255, 88, 73, 253)
//         : Colors.white70;

//     return GestureDetector(
//       onTap: onTap,
//       behavior: HitTestBehavior.opaque,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, color: color, size: 24),
//           const SizedBox(height: 2),
//           Text(
//             label,
//             style: TextStyle(
//               color: color,
//               fontSize: 11,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zyvionix_pos/provider/navbar/navbar_provider.dart';
import 'package:zyvionix_pos/views/billing/billing_screen.dart';
import 'package:zyvionix_pos/views/home_screen.dart';
import 'package:zyvionix_pos/views/profile/profile_screen.dart';

class NavbarScreen extends StatelessWidget {
  const NavbarScreen({super.key});

  static const List<Widget> _pages = [
    HomeScreen(),
    BillingScreen(),
    ProfileScreen(),
  ];

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
              backgroundColor: const Color(0xFF165FF2), // Blue from image
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
                    // Space for FAB and "New Bill" text
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const SizedBox(height: 28), // pushes text to bottom
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
                      icon: Icons.menu_rounded, // Changed to Reports icon
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
