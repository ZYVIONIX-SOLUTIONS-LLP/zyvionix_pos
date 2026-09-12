import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class SubscriptionLockScreen extends StatefulWidget {
  final String userId;
  final String userToken;
  final String razorpayKeyId;

  const SubscriptionLockScreen({
    super.key,
    required this.userId,
    required this.userToken,
    this.razorpayKeyId = "rzp_test_YourKeyHere"
  });

  @override
  State<SubscriptionLockScreen> createState() => _SubscriptionLockScreenState();
}

class _SubscriptionLockScreenState extends State<SubscriptionLockScreen> {
  final String baseUrl = "http://10.0.2.2:5000/api";
  List<dynamic> plans = [];
  bool isLoading = true;
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
      final response = await http.get(Uri.parse('$baseUrl/plans'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          plans = data['data'] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching plans: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _initiatePurchase(Map<String, dynamic> plan) async {
    try {
      // 1. Get Preview / Proration
      final previewRes = await http.post(
        Uri.parse('$baseUrl/plans/preview-upgrade'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.userToken}'
        },
        body: jsonEncode({'newPlanId': plan['_id']}),
      );

      double finalAmount = (plan['price'] as num).toDouble();
      if (previewRes.statusCode == 200) {
        final previewData = jsonDecode(previewRes.body);
        finalAmount = (previewData['data']['finalAmountToPay'] as num).toDouble();
      }

      // 2. Create Order in Backend
      final orderRes = await http.post(
        Uri.parse('$baseUrl/payments/create-order'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.userToken}'
        },
        body: jsonEncode({'planId': plan['_id']}),
      );

      if (orderRes.statusCode == 200) {
        final orderData = jsonDecode(orderRes.body);
        final String orderId = orderData['order_id'];

        // 3. Open Razorpay Gateway
        var options = {
          'key': widget.razorpayKeyId,
          'amount': (finalAmount * 100).toInt(),
          'name': 'POS Billing App',
          'order_id': orderId,
          'description': 'Subscription Plan Purchase',
          'timeout': 180, // in seconds
          'prefill': {
            'contact': '',
            'email': ''
          }
        };

        _razorpay.open(options);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initialize payment order'))
        );
      }
    } catch (e) {
      print('Purchase error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'))
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Payment Processing'),
        content: const Text('Your payment was captured! Webhook is updating your subscription. Please restart the app or click Continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue'),
          )
        ],
      )
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}'))
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Disable back button to enforce lock
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Active Plan Required'),
          automaticallyImplyLeading: false,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_clock_outlined, size: 48, color: Colors.orange),
                    const SizedBox(height: 12),
                    const Text(
                      'Access Restricted',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your subscription plan has expired or you do not have an active plan. Please choose a plan below to continue using the application.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: plans.length,
                        itemBuilder: (context, index) {
                          final plan = plans[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        plan['planName'] ?? '',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '₹${plan['price']}',
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.extrabold, color: Colors.green),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(plan['description'] ?? '', style: const TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 44),
                                    ),
                                    onPressed: () => _initiatePurchase(plan),
                                    child: Text('Subscribe (${plan['duration']} ${plan['durationType']})'),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
