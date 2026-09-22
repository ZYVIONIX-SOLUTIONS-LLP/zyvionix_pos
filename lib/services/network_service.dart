import 'dart:async';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class NetworkController extends ChangeNotifier {
  static final NetworkController _instance = NetworkController._internal();
  factory NetworkController() => _instance;

  NetworkController._internal() {
    _initNetworkMonitoring();
  }

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  bool _isChecking = false;
  bool get isChecking => _isChecking;

  StreamSubscription<InternetStatus>? _subscription;

  /// Global static helper to check internet connection anywhere on demand.
  static Future<bool> checkInternet() async {
    try {
      return await InternetConnection().hasInternetAccess;
    } catch (_) {
      return false;
    }
  }

  void _initNetworkMonitoring() async {
    // Initial check
    _isConnected = await checkInternet();
    notifyListeners();

    // Listen to continuous network changes
    _subscription = InternetConnection().onStatusChange.listen((status) {
      final connected = (status == InternetStatus.connected);
      if (_isConnected != connected) {
        _isConnected = connected;
        notifyListeners();
      }
    });
  }

  /// Explicit manual re-check trigger (e.g. from Retry button)
  Future<bool> manualCheck() async {
    _isChecking = true;
    notifyListeners();

    final status = await checkInternet();
    _isConnected = status;
    _isChecking = false;
    notifyListeners();

    return status;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
