import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/theme_controller.dart';
import '../controllers/language_controller.dart';

class ThemeSelectorSheet extends StatelessWidget {
  const ThemeSelectorSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const ThemeSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final isDark = themeController.isDarkMode;
    final isDarkThemeActive = Theme.of(context).brightness == Brightness.dark;

    final sheetBg = isDarkThemeActive ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkThemeActive ? Colors.white : const Color(0xFF1A1D1E);
    final subtitleColor = isDarkThemeActive ? Colors.white70 : Colors.grey.shade600;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle indicator
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDarkThemeActive ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E50FF).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.palette_rounded,
                  color: Color(0xFF1E50FF),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('app_theme'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('select_theme'),
                      style: TextStyle(
                        fontSize: 13,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, color: subtitleColor),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Light Mode Option Card
          _buildThemeCard(
            context: context,
            title: context.tr('light_mode'),
            subtitle: 'Clean & bright appearance',
            icon: Icons.light_mode_rounded,
            iconColor: Colors.amber.shade700,
            isSelected: !isDark,
            onTap: () {
              themeController.setDarkMode(false);
            },
          ),
          const SizedBox(height: 12),

          // Dark Mode Option Card
          _buildThemeCard(
            context: context,
            title: context.tr('dark_mode'),
            subtitle: 'Sleek dark theme, easy on eyes',
            icon: Icons.dark_mode_rounded,
            iconColor: Colors.deepPurpleAccent,
            isSelected: isDark,
            onTap: () {
              themeController.setDarkMode(true);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildThemeCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDarkThemeActive = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDarkThemeActive 
        ? (isSelected ? const Color(0xFF1E50FF).withOpacity(0.18) : const Color(0xFF2A2A2A))
        : (isSelected ? const Color(0xFF1E50FF).withOpacity(0.08) : Colors.grey.shade50);
        
    final borderColor = isSelected 
        ? const Color(0xFF1E50FF)
        : (isDarkThemeActive ? Colors.grey.shade800 : Colors.grey.shade200);

    final textColor = isDarkThemeActive ? Colors.white : const Color(0xFF1A1D1E);
    final subtitleColor = isDarkThemeActive ? Colors.white70 : Colors.grey.shade600;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  shape: BoxShape.circle,
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? const Color(0xFF1E50FF) : textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFF1E50FF) : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF1E50FF) : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
