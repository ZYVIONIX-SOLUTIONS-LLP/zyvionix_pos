import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:zyvionix_pos/constants/api_constants.dart';

class SubscriptionLockScreen extends StatefulWidget {
  final String userId;
  final String userToken;
  final String razorpayKeyId;
  final bool isExpired;

  const SubscriptionLockScreen({
    super.key,
    required this.userId,
    required this.userToken,
    this.razorpayKeyId = "rzp_test_Tamlee9RTRuHdu",
    this.isExpired = true,
  });

  @override
  State<SubscriptionLockScreen> createState() => _SubscriptionLockScreenState();
}

class _SubscriptionLockScreenState extends State<SubscriptionLockScreen> {
  List<dynamic> plans = [];
  bool isLoading = true;
  int _selectedIndex = 0;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _fetchPlans();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchPlans() async {
    try {
      String? currentPlanId;
      try {
        final profileRes = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/profile'),
          headers: {'Authorization': 'Bearer ${widget.userToken}'},
        );
        if (profileRes.statusCode == 200) {
          final profileData = jsonDecode(profileRes.body);
          if (profileData['data'] != null &&
              profileData['data']['currentPlan'] != null) {
            currentPlanId = profileData['data']['currentPlan']['_id'];
          }
        }
      } catch (e) {
        debugPrint('Error fetching profile: $e');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/plans'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final allPlans = data['data'] ?? [];

        setState(() {
          plans = allPlans
              .where(
                (p) =>
                    p['isDefaultTrial'] != true &&
                    p['_id'] != currentPlanId &&
                    p['status'] == 'Active',
              )
              .toList();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching plans: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _initiatePurchase(Map<String, dynamic> plan) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFF5C443)),
        ),
      );

      final orderRes = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/payments/create-order'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.userToken}',
        },
        body: jsonEncode({'planId': plan['_id']}),
      );

      if (mounted) Navigator.pop(context); // close loader

      if (orderRes.statusCode == 200) {
        final orderData = jsonDecode(orderRes.body);
        final String orderId = orderData['order_id'];
        final num amount = orderData['amount'];

        var options = {
          'key': widget.razorpayKeyId,
          'amount': (amount * 100).toInt(),
          'name': 'Zyvionix POS Billing',
          'order_id': orderId,
          'description': 'Subscription Plan Purchase',
          'timeout': 180,
          'prefill': {'contact': '', 'email': ''},
          'theme': {'color': '#F5C443'},
        };

        _razorpay.open(options);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initialize payment order')),
        );
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      debugPrint('Purchase error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        backgroundColor: Color(0xFF1E1E22),
        title: Text('Verifying Payment', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please wait while we verify your transaction...',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(color: Color(0xFFF5C443)),
          ],
        ),
      ),
    );

    try {
      final verifyRes = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/payments/verify-payment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.userToken}',
        },
        body: jsonEncode({
          'razorpay_order_id': response.orderId,
          'razorpay_payment_id': response.paymentId,
          'razorpay_signature': response.signature,
        }),
      );

      if (mounted) Navigator.pop(context);

      if (verifyRes.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment Successful! Plan Upgraded.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment verification failed on server.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Verification error: $e')));
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isExpired,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0E),
        body: SafeArea(
          child: Stack(
            children: [
              // Bottom decorative leaf icon watermark (matching screenshot aesthetic)
              Positioned(
                bottom: -50,
                right: -40,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.12,
                    child: Icon(
                      Icons.eco_rounded,
                      size: 290,
                      color: const Color(0xFF4ADE80),
                    ),
                  ),
                ),
              ),

              Column(
                children: [
                  // Top Bar (Close Icon & Restore Purchases)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (!widget.isExpired) {
                              Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please select a plan to unlock full POS features.',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            _fetchPlans();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Restoring plan list...'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.sync_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text(
                            'Restore Purchases',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main Scrollable Area
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          // Header Title & Subtitle
                          const Text(
                            'Choose a Plan',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'No commitment. Cancel anytime.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Bullet Features List
                          _buildFeatureItem(
                            icon: Icons.check_rounded,
                            iconColor: const Color(0xFF4ADE80),
                            text: 'Unlimited Invoices & Products',
                          ),
                          const SizedBox(height: 14),
                          _buildFeatureItem(
                            icon: Icons.location_on_rounded,
                            iconColor: const Color(0xFFF5C443),
                            text: 'Multi-Shop & Cloud Auto-Sync',
                          ),
                          const SizedBox(height: 14),
                          _buildFeatureItem(
                            icon: Icons.bar_chart_rounded,
                            iconColor: const Color(0xFF38BDF8),
                            text: 'Advanced Reports & Analytics',
                          ),
                          const SizedBox(height: 32),

                          // Dynamic Plans Cards
                          if (isLoading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: CircularProgressIndicator(
                                color: Color(0xFFF5C443),
                              ),
                            )
                          else if (plans.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 30),
                              child: Text(
                                'No subscription plans available at the moment.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          else
                            ...List.generate(plans.length, (index) {
                              final plan = plans[index];
                              final isSelected = _selectedIndex == index;
                              final isPopular =
                                  index == 0 ||
                                  plan['planName']
                                      .toString()
                                      .toLowerCase()
                                      .contains('gold') ||
                                  plan['planName']
                                      .toString()
                                      .toLowerCase()
                                      .contains('popular');

                              return _buildPlanCard(
                                plan: plan,
                                isSelected: isSelected,
                                isPopular: isPopular,
                                onTap: () {
                                  setState(() {
                                    _selectedIndex = index;
                                  });
                                },
                              );
                            }),

                          const SizedBox(height: 8),
                          if (plans.isNotEmpty)
                            Text(
                              '* Percentage off the regular monthly subscription cost',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action CTA Button & Terms Disclaimer
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: (isLoading || plans.isEmpty)
                                ? null
                                : () {
                                    if (_selectedIndex < plans.length) {
                                      final selectedPlan =
                                          plans[_selectedIndex];
                                      _initiatePurchase(selectedPlan);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF5C443),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              widget.isExpired
                                  ? 'Start Plan with Trial'
                                  : 'Upgrade Selected Plan',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Subscription renews automatically until you turn it off. You can cancel your subscription or trial anytime by managing your account settings.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF7C7C80),
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, size: 22, color: iconColor),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required Map<String, dynamic> plan,
    required bool isSelected,
    required bool isPopular,
    required VoidCallback onTap,
  }) {
    final planName = plan['planName'] ?? 'Popular Plan';
    final price = plan['price'] ?? 0;
    final duration = plan['durationType'] ?? 'month';
    final trialDays = plan['duration'] ?? 7;

    String priceSubtitle = '₹$price / $duration';
    if (isPopular) {
      priceSubtitle = '₹$price / $duration after $trialDays-day trial';
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: isPopular ? 10 : 0, bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: isPopular
                  ? const Color(0xFF1E1E22)
                  : const Color(0xFF26262A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFF5C443)
                    : const Color(0xFF3A3A3C),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFF5C443).withValues(alpha: 0.15),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planName,
                        style: TextStyle(
                          color: isPopular
                              ? const Color(0xFFF5C443)
                              : Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        priceSubtitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Circle Checkmark Selection Radio
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? const Color(0xFFF5C443)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFF5C443)
                          : const Color(0xFF636366),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: Colors.black,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
        // if (isPopular)
        //   Positioned(
        //     top: 0,
        //     left: 0,
        //     right: 0,
        //     child: Center(
        //       child: Container(
        //         padding: const EdgeInsets.symmetric(
        //           horizontal: 14,
        //           vertical: 3,
        //         ),
        //         decoration: BoxDecoration(
        //           color: const Color(0xFFF5C443),
        //           borderRadius: BorderRadius.circular(12),
        //         ),
        //         child: const Text(
        //           'Save 59%',
        //           style: TextStyle(
        //             color: Colors.black,
        //             fontSize: 11,
        //             fontWeight: FontWeight.bold,
        //           ),
        //         ),
        //       ),
        //     ),
        //   ),
      ],
    );
  }
}
