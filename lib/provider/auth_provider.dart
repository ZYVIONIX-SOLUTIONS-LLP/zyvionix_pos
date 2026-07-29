import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zyvionix_pos/constants/api_constants.dart';
import 'package:zyvionix_pos/database/hive_boxes.dart';

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

  Future<bool> login(String identifier, String password) async {
    _setLoading(true);
    _setErrorMessage('');

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobileNumber': identifier,
          'email': identifier,
          'username': identifier,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      print('Response status code for login ${response.statusCode}');
      print('Response bodyyyyyyyyyyyyyyyyyy for login ${response.body}');

      if (response.statusCode == 200) {
        // Save token to Hive
        final box = HiveBoxes.getSettingsBox();
        await box.put('auth_token', data['token']);

        // Save user info
        final userId = data['user']['id'];
        await box.put('user_id', userId);
        await box.put('user_mobile', data['user']['mobileNumber']);
        await box.put(
          'storageType',
          data['user']['storagePreference'] ?? 'Device Storage',
        );
        if (data['user']['companyName'] != null) {
          await box.put('shop_name', data['user']['companyName']);
        }

        await HiveBoxes.openUserBoxes(userId);

        _setLoading(false);
        return true;
      } else {
        _setErrorMessage(data['message'] ?? 'Login failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setErrorMessage(
        'Connection error: Please check your server or network.',
      );
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register({
    required String companyName,
    required String companyAddress,
    required String businessType,
    required String mobileNumber,
    String? gstNumber,
    String? email,
    required String password,
    required String storagePreference,
  }) async {
    _setLoading(true);
    _setErrorMessage('');

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'companyName': companyName,
          'companyAddress': companyAddress,
          'businessType': businessType,
          'mobileNumber': mobileNumber,
          'gstNumber': gstNumber ?? '',
          'email': email ?? '',
          'password': password,
          'storagePreference': storagePreference,
        }),
      );

      final data = jsonDecode(response.body);

      print('Response status code for Registration ${response.statusCode}');
      print('Response bodyyyyyyyyyyyyyyyyyy for Registration ${response.body}');

      if (response.statusCode == 201) {
        _setLoading(false);
        return true;
      } else {
        _setErrorMessage(data['message'] ?? 'Registration failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
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
    notifyListeners();
  }
}
