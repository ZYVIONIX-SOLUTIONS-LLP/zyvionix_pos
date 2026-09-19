import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:zyvionix_pos/database/hive_boxes.dart';
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
  late Razorpay _razorpay;
  int _currentPage = 0;

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
      // Fetch Profile to get current plan
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

        // Filter out Base/Silver plan (isDefaultTrial == true), the user's current plan, and Inactive plans
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
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      // Create Order in Backend
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
          'name': 'POS Billing App',
          'order_id': orderId,
          'description': 'Subscription Plan Purchase',
          'timeout': 180,
          'prefill': {'contact': '', 'email': ''},
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
        title: Text('Verifying Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please wait while we verify your transaction...'),
            SizedBox(height: 16),
            CircularProgressIndicator(),
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

      if (mounted) Navigator.pop(context); // Pop verifying dialog

      if (verifyRes.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment Successful! Plan Upgraded.'),
            backgroundColor: Colors.green,
          ),
        );
        if (mounted) {
          Navigator.pop(
            context,
            true,
          ); // Pop lock screen returning true (success)
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
      if (mounted) Navigator.pop(context); // Pop dialog
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
    return WillPopScope(
      onWillPop: () async => !widget.isExpired, // Lock if expired
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FC),
        appBar: AppBar(
          title: Text(
            widget.isExpired ? 'Active Plan Required' : 'Upgrade Plan',
          ),
          automaticallyImplyLeading: !widget.isExpired,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black87,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (widget.isExpired) ...[
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.lock_clock_outlined,
                            size: 48,
                            color: Colors.orange,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Access Restricted',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Your subscription plan has expired. Please upgrade your plan to continue using the application.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (!widget.isExpired) ...[
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Unlock unlimited features by upgrading your plan!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                  Expanded(
                    child: plans.isEmpty
                        ? const Center(child: Text("No plans available."))
                        : PageView.builder(
                            itemCount: plans.length,
                            controller: PageController(viewportFraction: 0.85),
                            onPageChanged: (index) {
                              setState(() {
                                _currentPage = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              final plan = plans[index];
                              final isGold = plan['planName']
                                  .toString()
                                  .toLowerCase()
                                  .contains('gold');
                              return _buildPlanCard(plan, isGold);
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  if (plans.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        plans.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 12 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? const Color(0xFF1EA1F2)
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan, bool isHighlighted) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFFFFF9E6) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isHighlighted ? Colors.amber.shade400 : Colors.grey.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlighted
                ? Colors.amber.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isHighlighted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'RECOMMENDED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          if (isHighlighted) const SizedBox(height: 12),
          Text(
            plan['planName'] ?? 'Plan',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            plan['description'] ?? '',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${plan['price']}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  '/ ${plan['durationType']}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Features list
          _buildFeatureRow(
            Icons.storefront,
            plan['maxShops'] == 0
                ? 'Unlimited Shops'
                : '${plan['maxShops']} Shop(s)',
          ),
          const SizedBox(height: 12),
          _buildFeatureRow(
            Icons.people_outline,
            plan['maxEmployees'] == 0
                ? 'Unlimited Employees'
                : '${plan['maxEmployees']} Employee(s)',
          ),
          const SizedBox(height: 12),
          // _buildFeatureRow(Icons.cloud_done_outlined, 'Cloud Auto-Backup'),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => _initiatePurchase(plan),
              style: ElevatedButton.styleFrom(
                backgroundColor: isHighlighted
                    ? Colors.amber.shade600
                    : const Color(0xFF1EA1F2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                widget.isExpired ? 'Subscribe Now' : 'Upgrade Now',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1EA1F2)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
