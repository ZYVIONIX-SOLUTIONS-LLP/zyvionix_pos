import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../database/hive_boxes.dart';

class ThemeController extends ChangeNotifier {
  late Box _settingsBox;
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeController() {
    _settingsBox = HiveBoxes.getSettingsBox();
    _isDarkMode = _settingsBox.get('is_dark_mode', defaultValue: false);
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _settingsBox.put('is_dark_mode', _isDarkMode);
    notifyListeners();
  }
}
