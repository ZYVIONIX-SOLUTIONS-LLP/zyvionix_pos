import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zyvionix_pos/controllers/language_controller.dart';
import 'package:zyvionix_pos/services/api_service.dart';
import 'package:zyvionix_pos/views/settings/upgrade_plan_screen.dart';
import 'package:zyvionix_pos/widgets/primary_button.dart';

class ActivePlanScreen extends StatefulWidget {
  const ActivePlanScreen({super.key});

  @override
  State<ActivePlanScreen> createState() => _ActivePlanScreenState();
}

class _ActivePlanScreenState extends State<ActivePlanScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final profile = await ApiService.getProfile();
    setState(() {
      _profile = profile;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: Text(context.tr('subscription_plan')),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: SpinKitFadingCircle(
                  color: Color(0xFF1EA1F2),
                  size: 50.0,
                ),
              )
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_profile == null || _profile!['currentPlan'] == null) {
      // User has no active plan
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 20),
              const Text(
                'No Active Plan',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'You do not have an active Cloud Plan. Upgrade to access all features.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 30),
              PrimaryButton(
                text: 'View Plans',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const UpgradePlanScreen(isSyncRequired: false),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    final plan = _profile!['currentPlan'];
    final expiryDateStr = _profile!['planExpiryDate'];
    DateTime? expiryDate;
    if (expiryDateStr != null) {
      expiryDate = DateTime.tryParse(expiryDateStr);
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1C64F2), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ACTIVE PLAN',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Cloud Sync Enabled',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  plan['planName'] ?? 'Pro Plan',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  plan['description'] ?? 'All features unlocked',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                const Divider(color: Colors.white24),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Expiry Date',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          expiryDate != null
                              ? DateFormat('MMM dd, yyyy').format(expiryDate)
                              : 'N/A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Status',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plan['status'] ?? 'Active',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'Need to renew or upgrade?',
            style: TextStyle(color: Colors.black54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF1C64F2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const UpgradePlanScreen(isSyncRequired: false),
                ),
              );
            },
            child: Text(
              context.tr('browse_other_plans'),
              style: const TextStyle(
                color: Color(0xFF1C64F2),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
