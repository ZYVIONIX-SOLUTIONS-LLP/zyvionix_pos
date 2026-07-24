import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/theme_controller.dart';
import '../../database/hive_boxes.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _box = HiveBoxes.getSettingsBox();
  late TextEditingController _shopNameController;
  late TextEditingController _shopAddressController;
  late TextEditingController _shopPhoneController;

  @override
  void initState() {
    super.initState();
    _shopNameController = TextEditingController(
      text: _box.get('shop_name', defaultValue: 'ZYVIONIX POS'),
    );
    _shopAddressController = TextEditingController(
      text: _box.get('shop_address', defaultValue: 'Kochi, Kaatithara Road'),
    );
    _shopPhoneController = TextEditingController(
      text: _box.get('shop_phone', defaultValue: '6282714883'),
    );
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _shopPhoneController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    _box.put('shop_name', _shopNameController.text.trim());
    _box.put('shop_address', _shopAddressController.text.trim());
    _box.put('shop_phone', _shopPhoneController.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'App Preferences',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Consumer<ThemeController>(
              builder: (context, themeController, _) {
                return SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Enable dark theme'),
                  value: themeController.isDarkMode,
                  onChanged: (value) {
                    themeController.toggleTheme();
                  },
                  contentPadding: EdgeInsets.zero,
                  activeColor: Theme.of(context).colorScheme.primary,
                );
              },
            ),
            const SizedBox(height: 32),
            Text('Shop Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Shop Name',
              controller: _shopNameController,
            ),
            CustomTextField(
              label: 'Shop Address',
              controller: _shopAddressController,
            ),
            CustomTextField(
              label: 'Shop Phone Number',
              controller: _shopPhoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            PrimaryButton(text: 'Save Settings', onPressed: _saveSettings),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
