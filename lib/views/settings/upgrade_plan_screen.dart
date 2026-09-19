import 'package:flutter/material.dart';
import 'package:zyvionix_pos/database/hive_boxes.dart';
import 'package:zyvionix_pos/screens/subscription_lock_screen.dart';

class UpgradePlanScreen extends StatelessWidget {
  final bool isSyncRequired;

  const UpgradePlanScreen({super.key, this.isSyncRequired = true});

  @override
  Widget build(BuildContext context) {
    final box = HiveBoxes.getSettingsBox();
    final userId = box.get('user_id', defaultValue: '');
    final userToken = box.get('auth_token', defaultValue: '');

    return SubscriptionLockScreen(
      userId: userId,
      userToken: userToken,
      isExpired: false, // Triggers "Upgrade Now" text and allows closing the screen if they want
    );
  }
}
