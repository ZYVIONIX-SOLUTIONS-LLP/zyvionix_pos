// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:package_info_plus/package_info_plus.dart';
// import 'package:zyvionix_pos/constants/api_constants.dart';
// import 'dart:io';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:zyvionix_pos/database/hive_boxes.dart';
// import 'package:zyvionix_pos/views/firebase/firebase_service.dart';

// class AuthProvider extends ChangeNotifier {
//   bool _isLoading = false;
//   String _errorMessage = '';

//   bool get isLoading => _isLoading;
//   String get errorMessage => _errorMessage;

//   void _setLoading(bool value) {
//     _isLoading = value;
//     notifyListeners();
//   }

//   void _setErrorMessage(String message) {
//     _errorMessage = message;
//     notifyListeners();
//   }

//   Future<Map<String, String>> _getDeviceInfo() async {
//     final deviceInfo = DeviceInfoPlugin();
//     String deviceId = '';
//     String deviceName = '';
//     String androidVersion = '';
//     String iosVersion = '';
//     String deviceVersion = '';
//     String androidAppVersion = '';
//     String iosAppVersion = '';

//     try {
//       print('Fetching device info...');

//       final packageInfo = await PackageInfo.fromPlatform();

//       final appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

//       print('App Version: $appVersion');
//       if (Platform.isAndroid) {
//         print("Platform is Android");
//         final info = await deviceInfo.androidInfo;
//         deviceId = info.id;
//         deviceName = info.model;
//         deviceVersion = info.version.release;
//         androidAppVersion = appVersion;
//       } else if (Platform.isIOS) {
//         print("Platform is iOS");
//         final info = await deviceInfo.iosInfo;
//         deviceId = info.identifierForVendor ?? '';
//         deviceName = info.name;
//         deviceVersion = info.systemVersion;
//         iosAppVersion = appVersion;
//       } else if (Platform.isWindows) {
//         final info = await deviceInfo.windowsInfo;
//         deviceId = info.deviceId;
//         deviceName = info.computerName;
//       }

//       print('Device ID: $deviceId');
//       print('Device Name: $deviceName');
//       print('Android Version: $androidVersion');
//       print('iOS Version: $iosVersion');
//       print('Device version $deviceVersion');
//       print('Android App Version: $androidAppVersion');
//       print('iOS App Version: $iosAppVersion');
//       // print('Device Info: deviceId=$deviceId, deviceName=$deviceName');
//     } catch (e) {
//       print('Error getting device info: $e');
//     }

//     print('Fetched Device Info: deviceId=$deviceId, deviceName=$deviceName');
//     // return {'deviceId': deviceId, 'deviceName': deviceName};

//     return {
//       'deviceId': deviceId,
//       'deviceName': deviceName,
//       'androidVersion': androidVersion,
//       'iosVersion': iosVersion,
//       'androidAppVersion': androidAppVersion,
//       'iosAppVersion': iosAppVersion,
//     };
//   }

//   Future<Map<String, dynamic>> login(String identifier, String password) async {
//     _setLoading(true);
//     _setErrorMessage('');

//     try {
//       print(
//         'Attempting login with identifier: $identifier and password: $password',
//       );
//       final deviceData = await _getDeviceInfo();
//       final fcmToken = await FCMService().getFCMTokenSafe();

//       final payload = {
//         'mobileNumber': identifier,
//         'email': identifier,
//         'username': identifier,
//         'password': password,
//         'deviceId': deviceData['deviceId'],
//         'deviceName': deviceData['deviceName'],
//         'fcmToken': fcmToken ?? '',
//         'androidappversion': deviceData['androidVersion'],
//         'iosappversion': deviceData['iosVersion'],
//         'deviceVersion': deviceData['deviceVersion'],
//         'androidappversion': deviceData['androidAppVersion'],
//         'iosappversion': deviceData['iosAppVersion'],
//       };

//       print('Sending Login Payload: $payload');

//       final response = await http.post(
//         Uri.parse(ApiConstants.loginUrl),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode(payload),
//       );

//       final data = jsonDecode(response.body);

//       print('Response status code for login ${response.statusCode}');
//       print('Response bodyyyyyyyyyyyyyyyyyy for login ${response.body}');

//       if (response.statusCode == 200) {
//         // Save token to Hive
//         final box = HiveBoxes.getSettingsBox();
//         await box.put('auth_token', data['token']);

//         // Save user info
//         final userId = data['user']['id'];
//         await box.put('user_id', userId);
//         await box.put('user_mobile', data['user']['mobileNumber']);
//         await box.put(
//           'storageType',
//           data['user']['storagePreference'] ?? 'Device Storage',
//         );
//         if (data['user']['companyName'] != null) {
//           await box.put('shop_name', data['user']['companyName']);
//         }
//         await box.put('user_email', data['user']['email'] ?? '');
//         await box.put('user_role', data['user']['role'] ?? 'Owner');
//         if (data['user']['hasPlan'] == true) {
//           await box.put('subscriptionModalShown', true);
//         }

//         if (data['user']['role'] == 'Employee') {
//           await box.put('employee_name', data['user']['name']);
//           final assignedShops = data['user']['assignedShops'] as List<dynamic>?;
//           if (assignedShops != null && assignedShops.isNotEmpty) {
//             final firstShop = assignedShops[0];
//             final shopId = firstShop is Map ? firstShop['_id'] : firstShop;
//             await box.put('shop_id', shopId);
//             await box.put('current_shop_id', shopId);
//             if (firstShop is Map) {
//               await box.put('shop_name', firstShop['name']);
//               if (firstShop['address'] != null) {
//                 await box.put('offline_company_address', firstShop['address']);
//               }
//               if (firstShop['mobile'] != null) {
//                 await box.put('shop_mobile', firstShop['mobile']);
//               }
//             }
//           }
//         } else {
//           // Owner
//           final shops = data['user']['shops'] as List<dynamic>?;
//           if (shops != null && shops.isNotEmpty) {
//             final firstShop = shops[0];
//             await box.put('shop_id', firstShop['_id']);
//             await box.put('current_shop_id', firstShop['_id']);
//             await box.put('shop_name', firstShop['name']);
//             if (firstShop['address'] != null) {
//               await box.put('offline_company_address', firstShop['address']);
//             }
//             if (firstShop['mobile'] != null) {
//               await box.put('shop_mobile', firstShop['mobile']);
//             }
//           }
//         }

//         await HiveBoxes.openUserBoxes(userId);

//         _setLoading(false);
//         return {
//           'success': true,
//           'role': data['user']['role'] ?? 'Owner',
//           'assignedShops': data['user']['assignedShops'],
//         };
//       } else if (response.statusCode == 403 &&
//           data['code'] == 'DEVICE_MISMATCH') {
//         _setLoading(false);
//         return {
//           'success': false,
//           'isDeviceMismatch': true,
//           'message': data['message'],
//           'deviceName': data['deviceName'],
//           'mobileNumber': data['mobileNumber'],
//         };
//       } else {
//         _setErrorMessage(data['message'] ?? 'Login failed');
//         _setLoading(false);
//         return {'success': false, 'message': data['message'] ?? 'Login failed'};
//       }
//     } catch (e) {
//       _setErrorMessage(
//         'Connection error: Please check your server or network.',
//       );
//       _setLoading(false);
//       return {'success': false};
//     }
//   }

//   Future<bool> register({
//     required String ownerName,
//     required String mobileNumber,
//     String? email,
//     required String password,
//     required String storagePreference,
//   }) async {
//     _setLoading(true);
//     _setErrorMessage('');

//     try {
//       final fcmToken = await FCMService().getFCMTokenSafe();

//       final response = await http.post(
//         Uri.parse(ApiConstants.registerUrl),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'username': ownerName,
//           'mobileNumber': mobileNumber,
//           'email': email ?? '',
//           'password': password,
//           'storagePreference': storagePreference,
//           'fcmToken': fcmToken ?? '',
//         }),
//       );

//       final data = jsonDecode(response.body);

//       print('Dattttttttttttttttttt $data');

//       print('Response status code for Registration ${response.statusCode}');
//       print('Response bodyyyyyyyyyyyyyyyyyy for Registration ${response.body}');

//       if (response.statusCode == 201) {
//         _setLoading(false);
//         return true;
//       } else {
//         _setErrorMessage(data['message'] ?? 'Registration failed');
//         _setLoading(false);
//         return false;
//       }
//     } catch (e) {
//       _setErrorMessage(
//         'Connection error: Please check your server or network.',
//       );
//       _setLoading(false);
//       return false;
//     }
//   }

//   Future<void> logout() async {
//     final box = HiveBoxes.getSettingsBox();
//     await HiveBoxes.closeUserBoxes();
//     await box.delete('auth_token');
//     await box.delete('user_id');
//     await box.delete('user_mobile');
//     await box.delete('storageType');
//     await box.delete('shop_name');
//     await box.delete('user_name');
//     await box.delete('user_email');
//     await box.delete('user_phone');
//     await box.delete('profile_image');
//     await box.delete('user_role');
//     await box.delete('shop_id');
//     await box.delete('employee_name');
//     notifyListeners();
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:zyvionix_pos/constants/api_constants.dart';
import 'package:zyvionix_pos/database/hive_boxes.dart';
import 'package:zyvionix_pos/views/firebase/firebase_service.dart';
import 'package:zyvionix_pos/services/socket_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setErrorMessage(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<Map<String, String>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();

    String deviceId = '';
    String deviceName = '';
    String deviceVersion = '';

    String androidAppVersion = '';
    String iosAppVersion = '';

    try {
      print('========================================');
      print('Fetching device and app info...');
      print('========================================');

      final packageInfo = await PackageInfo.fromPlatform();

      final String appVersion =
          '${packageInfo.version}+${packageInfo.buildNumber}';

      print('App Version: $appVersion');

      if (Platform.isAndroid) {
        print('Platform: Android');
        final info = await deviceInfo.androidInfo;
        deviceId = info.id;
        deviceName = info.model;
        deviceVersion = info.version.release;
        androidAppVersion = appVersion;

        print('Android Device ID: $deviceId');
        print('Android Device Name: $deviceName');
        print('Android OS Version: $deviceVersion');
        print('Android App Version: $androidAppVersion');
      } else if (Platform.isIOS) {
        print('Platform: iOS');
        final info = await deviceInfo.iosInfo;
        deviceId = info.identifierForVendor ?? '';
        deviceName = info.name;
        deviceVersion = info.systemVersion;
        iosAppVersion = appVersion;

        print('iOS Device ID: $deviceId');
        print('iOS Device Name: $deviceName');
        print('iOS OS Version: $deviceVersion');
        print('iOS App Version: $iosAppVersion');
      } else if (Platform.isWindows) {
        print('Platform: Windows');

        final info = await deviceInfo.windowsInfo;

        deviceId = info.deviceId;
        deviceName = info.computerName;

        print('Windows Device ID: $deviceId');
        print('Windows Device Name: $deviceName');
      } else {
        print('Unsupported platform');
      }

      print('========================================');
      print('FINAL DEVICE INFORMATION');
      print('========================================');
      print('Device ID: $deviceId');
      print('Device Name: $deviceName');
      print('Device OS Version: $deviceVersion');
      print('Android App Version: $androidAppVersion');
      print('iOS App Version: $iosAppVersion');
      print('========================================');
    } catch (e) {
      print('Error getting device info: $e');
    }

    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'deviceVersion': deviceVersion,
      'androidAppVersion': androidAppVersion,
      'iosAppVersion': iosAppVersion,
    };
  }

  Future<Map<String, dynamic>> login(String identifier, String password) async {
    _setLoading(true);
    _setErrorMessage('');
    try {
      print('Attempting login with identifier: $identifier');

      final deviceData = await _getDeviceInfo();

      final fcmToken = await FCMService().getFCMTokenSafe();

      final payload = {
        'mobileNumber': identifier,
        'email': identifier,
        'username': identifier,
        'password': password,
        'deviceId': deviceData['deviceId'],
        'deviceName': deviceData['deviceName'],
        'deviceversion': deviceData['deviceVersion'],
        'androidappversion': deviceData['androidAppVersion'] ?? '',
        'iosappversion': deviceData['iosAppVersion'] ?? '',
        'fcmToken': fcmToken ?? '',
      };

      print('$payload PAYLOADdddddddddddddddddddddddddddddddddddddddddd');

      final response = await http.post(
        Uri.parse(ApiConstants.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final data = jsonDecode(response.body);

      print('Response status code for login: ${response.statusCode}');

      print('Response body for login: ${response.body}');

      if (response.statusCode == 200) {
        final box = HiveBoxes.getSettingsBox();

        await box.put('auth_token', data['token']);

        final userId = data['user']['id'];

        await box.put('user_id', userId);

        await box.put('user_mobile', data['user']['mobileNumber']);

        await box.put(
          'storageType',
          'Cloud Storage',
        );

        if (data['user']['companyName'] != null) {
          await box.put('shop_name', data['user']['companyName']);
        }

        await box.put('user_email', data['user']['email'] ?? '');

        await box.put('user_role', data['user']['role'] ?? 'Owner');

        if (data['user']['hasPlan'] == true) {
          await box.put('subscriptionModalShown', true);
        }
        await box.put('hasActivePlan', data['user']['hasActivePlan'] ?? false);
        await box.put('is_new_user', data['user']['isNewUser'] ?? true);

        if (data['user']['role'] == 'Employee') {
          await box.put('employee_name', data['user']['name']);

          final assignedShops = data['user']['assignedShops'] as List<dynamic>?;

          if (assignedShops != null && assignedShops.isNotEmpty) {
            final firstShop = assignedShops[0];

            final shopId = firstShop is Map ? firstShop['_id'] : firstShop;

            await box.put('shop_id', shopId);

            await box.put('current_shop_id', shopId);

            if (firstShop is Map) {
              await box.put('shop_name', firstShop['name']);

              if (firstShop['address'] != null) {
                await box.put('offline_company_address', firstShop['address']);
              }

              if (firstShop['mobile'] != null) {
                await box.put('shop_mobile', firstShop['mobile']);
              }
            }
          }
        } else {
          final shops = data['user']['shops'] as List<dynamic>?;

          if (shops != null && shops.isNotEmpty) {
            final firstShop = shops[0];

            await box.put('shop_id', firstShop['_id']);

            await box.put('current_shop_id', firstShop['_id']);

            await box.put('shop_name', firstShop['name']);

            if (firstShop['address'] != null) {
              await box.put('offline_company_address', firstShop['address']);
            }

            if (firstShop['mobile'] != null) {
              await box.put('shop_mobile', firstShop['mobile']);
            }
          }
        }


        
        SocketService().initSocket();

        _setLoading(false);

        return {
          'success': true,
          'role': data['user']['role'] ?? 'Owner',
          'assignedShops': data['user']['assignedShops'],
        };
      } else if (response.statusCode == 403 &&
          data['code'] == 'DEVICE_MISMATCH') {
        _setLoading(false);

        return {
          'success': false,
          'isDeviceMismatch': true,
          'message': data['message'],
          'deviceName': data['deviceName'],
          'mobileNumber': data['mobileNumber'],
        };
      } else {
        _setErrorMessage(data['message'] ?? 'Login failed');

        _setLoading(false);

        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      print('Login error: $e');

      _setErrorMessage(
        'Connection error: Please check your server or network.',
      );

      _setLoading(false);

      return {'success': false};
    }
  }

  Future<bool> register({
    required String ownerName,
    required String mobileNumber,
    String? email,
    required String password,
  }) async {
    _setLoading(true);
    _setErrorMessage('');

    try {
      final fcmToken = await FCMService().getFCMTokenSafe();

      final response = await http.post(
        Uri.parse(ApiConstants.registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': ownerName,
          'mobileNumber': mobileNumber,
          'email': email ?? '',
          'password': password,
          'fcmToken': fcmToken ?? '',
        }),
      );

      final data = jsonDecode(response.body);

      print('Registration Data: $data');

      print(
        'Response status code for Registration: '
        '${response.statusCode}',
      );

      print(
        'Response body for Registration: '
        '${response.body}',
      );

      if (response.statusCode == 201) {
        _setLoading(false);
        return true;
      } else {
        _setErrorMessage(data['message'] ?? 'Registration failed');

        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('Registration error: $e');

      _setErrorMessage(
        'Connection error: Please check your server or network.',
      );

      _setLoading(false);

      return false;
    }
  }

  Future<void> logout() async {
    final box = HiveBoxes.getSettingsBox();

    await HiveBoxes.closeUserBoxes();

    await box.delete('auth_token');
    await box.delete('user_id');
    await box.delete('user_mobile');
    await box.delete('storageType');
    await box.delete('shop_name');
    await box.delete('user_name');
    await box.delete('user_email');
    await box.delete('user_phone');
    await box.delete('profile_image');
    await box.delete('user_role');
    await box.delete('shop_id');
    await box.delete('employee_name');

    notifyListeners();
  }
}
