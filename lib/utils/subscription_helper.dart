import 'package:flutter/material.dart';
import 'package:zyvionix_pos/database/hive_boxes.dart';
import 'package:zyvionix_pos/screens/subscription_lock_screen.dart';

class SubscriptionHelper {
  /// Checks if the user has an active plan. If not, pushes the lock screen.
  /// Returns true if the user can proceed, false if blocked.
  static Future<bool> checkAndEnforcePlan(BuildContext context) async {
    final box = HiveBoxes.getSettingsBox();
    final bool hasActivePlan = box.get('hasActivePlan', defaultValue: false);

    if (hasActivePlan) {
      return true;
    }

    final String userId = box.get('user_id', defaultValue: '');
    final String userToken = box.get('auth_token', defaultValue: '');

    // Push the lock screen and wait for result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubscriptionLockScreen(
          userId: userId,
          userToken: userToken,
          isExpired: true,
        ),
      ),
    );

    // If result is true, payment was successful and plan is active now.
    if (result == true) {
      // Update local storage
      await box.put('hasActivePlan', true);
      return true;
    }

    return false;
  }
}
