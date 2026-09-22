import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zyvionix_pos/database/hive_boxes.dart';
import 'package:zyvionix_pos/l10n/app_translations.dart';
import 'package:zyvionix_pos/widgets/language_transition_overlay.dart';

class LanguageController extends ChangeNotifier {
  String _currentLanguageCode = 'en';

  LanguageController() {
    _loadSavedLanguage();
  }

  String get currentLanguageCode => _currentLanguageCode;

  String get currentLanguageName =>
      AppTranslations.languageNames[_currentLanguageCode] ?? 'English';

  String get currentLanguageNativeName =>
      AppTranslations.languageNativeNames[_currentLanguageCode] ?? 'English';

  String get currentLanguageFlag =>
      AppTranslations.languageFlags[_currentLanguageCode] ?? '🇬🇧';

  static LanguageController of(BuildContext context, {bool listen = true}) {
    return Provider.of<LanguageController>(context, listen: listen);
  }

  void _loadSavedLanguage() {
    final box = HiveBoxes.getSettingsBox();
    _currentLanguageCode = box.get('app_language', defaultValue: 'en');
  }

  String tr(String key) {
    return AppTranslations.get(key, _currentLanguageCode);
  }

  Future<void> setLanguage(BuildContext context, String newLangCode) async {
    if (_currentLanguageCode == newLangCode) return;

    // Show smooth animated language switch overlay
    LanguageTransitionOverlay.show(context, targetLangCode: newLangCode);

    // Brief delay to allow the beautiful animation to present
    await Future.delayed(const Duration(milliseconds: 600));

    _currentLanguageCode = newLangCode;
    final box = HiveBoxes.getSettingsBox();
    await box.put('app_language', newLangCode);

    notifyListeners();
  }
}

extension LanguageExtension on BuildContext {
  String tr(String key) {
    return LanguageController.of(this).tr(key);
  }
}
