import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'package:zyvionix_pos/constants/api_constants.dart';
import 'package:zyvionix_pos/main.dart';
import 'package:zyvionix_pos/views/maintenance/maintenance_screen.dart';

class MaintenanceService {
  static final MaintenanceService _instance = MaintenanceService._internal();
  factory MaintenanceService() => _instance;
  MaintenanceService._internal();

  IO.Socket? _socket;
  bool _isMaintenanceMode = false;
  bool _isScreenVisible = false;

  bool get isMaintenanceMode => _isMaintenanceMode;

  Future<void> checkInitialMaintenanceStatus() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/admin/maintenance'),
      );

      print('Response status code for maintenance ${response.statusCode}');
      print('Response bodyyyyyyyyyyyyy code for maintenance ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        bool status = false;
        if (data is Map && data.containsKey('status')) {
          status = data['status'] == true;
        } else if (data is bool) {
          status = data;
        }
        _handleMaintenanceUpdate(status);
      }
    } catch (e) {
      debugPrint('Failed to check maintenance status: $e');
    }
  }

  void initSocket() {
    final uri = Uri.parse(ApiConstants.baseUrl);
    final socketUrl = '${uri.scheme}://${uri.host}:${uri.port}';

    _socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket?.onConnect((_) {
      debugPrint('Connected to Socket.io for maintenance');
    });

    _socket?.on('maintenance_mode', (data) {
      debugPrint('Maintenance mode updated: $data');
      bool status = false;
      if (data is Map && data.containsKey('status')) {
        status = data['status'] == true;
      } else if (data is bool) {
        status = data;
      }
      _handleMaintenanceUpdate(status);
    });

    _socket?.onDisconnect((_) {
      debugPrint('Disconnected from Socket.io');
    });
  }

  void _handleMaintenanceUpdate(bool isMaintenance) {
    if (_isMaintenanceMode == isMaintenance) return;

    _isMaintenanceMode = isMaintenance;

    final context = navigatorKey.currentContext;
    if (context == null) return;

    if (isMaintenance && !_isScreenVisible) {
      _isScreenVisible = true;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MaintenanceScreen()),
      ).then((_) {
        _isScreenVisible = false;
      });
    } else if (!isMaintenance && _isScreenVisible) {
      Navigator.pop(context);
      _isScreenVisible = false;
    }
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
