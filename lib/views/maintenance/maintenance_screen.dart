import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.network(
                    'https://lottie.host/8a72cde3-8c46-4e00-84c6-e91b29a28f80/4fUvL21tK7.json',
                    height: 250,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.engineering,
                        size: 100,
                        color: Colors.orange,
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Under Maintenance',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'We are currently performing scheduled maintenance to improve your experience. We will be back online shortly!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
