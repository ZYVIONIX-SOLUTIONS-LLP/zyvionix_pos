import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:zyvionix_pos/constants/api_constants.dart';
import 'package:zyvionix_pos/database/hive_boxes.dart';
import 'package:zyvionix_pos/controllers/bill_controller.dart';
import 'package:zyvionix_pos/controllers/product_controller.dart';
import 'package:floating_snackbar/floating_snackbar.dart';
import 'package:zyvionix_pos/views/navbar/navbar_screen.dart';

class DeviceOverrideOtpScreen extends StatefulWidget {
  final String mobileNumber;

  const DeviceOverrideOtpScreen({super.key, required this.mobileNumber});

  @override
  State<DeviceOverrideOtpScreen> createState() => _DeviceOverrideOtpScreenState();
}

class _DeviceOverrideOtpScreenState extends State<DeviceOverrideOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/send-override-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobileNumber': widget.mobileNumber}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (mounted) {
          floatingSnackBar(
            message: data['message'] ?? 'OTP sent successfully',
            context: context,
            textColor: Colors.white,
            backgroundColor: Colors.green,
          );
        }
      } else {
        if (mounted) {
          floatingSnackBar(
            message: data['message'] ?? 'Failed to send OTP',
            context: context,
            textColor: Colors.white,
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        floatingSnackBar(
          message: 'Network error',
          context: context,
          textColor: Colors.white,
          backgroundColor: Colors.red,
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, String>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceId = '';
    String deviceName = '';
    try {
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        deviceId = info.id;
        deviceName = info.model;
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        deviceId = info.identifierForVendor ?? '';
        deviceName = info.name;
      } else if (Platform.isWindows) {
        final info = await deviceInfo.windowsInfo;
        deviceId = info.deviceId;
        deviceName = info.computerName;
      }
    } catch (e) {
      print('Error getting device info: $e');
    }

    return {'deviceId': deviceId, 'deviceName': deviceName};
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().isEmpty) {
      floatingSnackBar(
        message: 'Please enter the OTP',
        context: context,
        textColor: Colors.white,
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final deviceData = await _getDeviceInfo();

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/verify-override-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobileNumber': widget.mobileNumber,
          'otp': _otpController.text.trim(),
          'deviceId': deviceData['deviceId'],
          'deviceName': deviceData['deviceName'],
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final box = HiveBoxes.getSettingsBox();
        await box.put('auth_token', data['token']);
        
        final userId = data['user']['id'];
        await box.put('user_id', userId);
        await box.put('user_mobile', data['user']['mobileNumber']);
        await box.put('storageType', data['user']['storagePreference'] ?? 'Device Storage');
        if (data['user']['companyName'] != null) {
          await box.put('shop_name', data['user']['companyName']);
        }
        await box.put('user_role', data['user']['role'] ?? 'Owner');

        await HiveBoxes.openUserBoxes(userId);

        if (mounted) {
          context.read<ProductController>().init();
          context.read<BillController>().init();
          
          floatingSnackBar(
            message: 'Device overridden and logged in successfully',
            context: context,
            textColor: Colors.white,
            backgroundColor: Colors.green,
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const NavbarScreen()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          floatingSnackBar(
            message: data['message'] ?? 'Invalid OTP',
            context: context,
            textColor: Colors.white,
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        floatingSnackBar(
          message: 'Network error',
          context: context,
          textColor: Colors.white,
          backgroundColor: Colors.red,
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Device Override')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'A verification code has been sent to your registered mobile number.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter OTP (Mock: 1234)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF1EA1F2),
                    ),
                    child: const Text('Verify & Login', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _isLoading ? null : _sendOtp,
              child: const Text('Resend OTP'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}
