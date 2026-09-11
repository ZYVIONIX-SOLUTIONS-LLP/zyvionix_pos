import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:zyvionix_pos/constants/api_constants.dart';
import 'package:zyvionix_pos/database/hive_boxes.dart';
import 'package:zyvionix_pos/main.dart';
import 'package:zyvionix_pos/views/auth/login_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;

  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceId = '';
    try {
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        deviceId = info.id;
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        deviceId = info.identifierForVendor ?? '';
      } else if (Platform.isWindows) {
        final info = await deviceInfo.windowsInfo;
        deviceId = info.deviceId;
      }
    } catch (e) {
      debugPrint('Error getting device info in socket service: $e');
    }
    return deviceId;
  }

  Future<void> initSocket() async {
    if (_socket != null && _socket!.connected) return;

    final uri = Uri.parse(ApiConstants.baseUrl);
    final socketUrl = uri.origin;

    _socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket?.onConnect((_) async {
      debugPrint('Connected to User Socket.io');
      final deviceId = await _getDeviceId();
      if (deviceId.isNotEmpty) {
        _socket?.emit('register_device', deviceId);
      }
    });

    _socket?.on('force_logout', (_) async {
      debugPrint('Received force_logout event. Logging out...');
      await _handleForceLogout();
    });

    _socket?.onDisconnect((_) {
      debugPrint('Disconnected from User Socket.io');
    });
  }

  Future<void> _handleForceLogout() async {
    // Clear local data
    await HiveBoxes.getSettingsBox().clear();
    await HiveBoxes.closeUserBoxes();
    
    // Disconnect socket
    dispose();

    // Navigate to Login Screen
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );

      // Show alert
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Session Expired'),
          content: const Text(
            'You have been logged out because another device signed in with your account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            )
          ],
        ),
      );
    }
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
