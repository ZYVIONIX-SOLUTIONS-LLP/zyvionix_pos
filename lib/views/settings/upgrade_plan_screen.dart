import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zyvionix_pos/database/hive_boxes.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:zyvionix_pos/constants/api_constants.dart';
import 'package:zyvionix_pos/models/shop.dart';
import 'package:zyvionix_pos/models/product.dart';
import 'package:zyvionix_pos/models/bill.dart';

class UpgradePlanScreen extends StatefulWidget {
  final bool isSyncRequired;

  const UpgradePlanScreen({super.key, this.isSyncRequired = true});

  @override
  State<UpgradePlanScreen> createState() => _UpgradePlanScreenState();
}

class _UpgradePlanScreenState extends State<UpgradePlanScreen> {
  bool _isLoading = false;
  List<dynamic> _plans = [];
  bool _isFetchingPlans = true;
  String? _selectedPlanId;

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    try {
      final box = HiveBoxes.getSettingsBox();
      final token = box.get('auth_token');
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/plans'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _plans = data['data'];
          if (_plans.isNotEmpty) {
            _selectedPlanId = _plans[0]['_id'];
          }
          _isFetchingPlans = false;
        });
      } else {
        setState(() => _isFetchingPlans = false);
      }
    } catch (e) {
      setState(() => _isFetchingPlans = false);
    }
  }

  Future<void> _subscribeToCloud() async {
    setState(() {
      _isLoading = true;
    });

    final box = HiveBoxes.getSettingsBox();
    final token = box.get('auth_token');
    
    // Gather local data
    final shopName = box.get('shop_name');
    final shopId = box.get('shop_id');
    final shopMobile = box.get('shop_mobile', defaultValue: '');
    final shopAddress = box.get('offline_company_address', defaultValue: '');
    final shopEmail = box.get('shop_email', defaultValue: '');
    final shopGst = box.get('shop_gst', defaultValue: '');
    
    Map<String, dynamic>? shopData;
    if (shopName != null && shopId != null) {
      shopData = {
        'name': shopName,
        'id': shopId, // keeping local id just in case
        'mobile': shopMobile,
        'address': shopAddress,
        'email': shopEmail,
        'gst': shopGst,
      };
    }

    final productsBox = HiveBoxes.getProductsBox();
    final List<Map<String, dynamic>> products = productsBox?.values.map((p) => {
      'id': p.id,
      'name': p.name,
      'price': p.price,
      'category': p.category,
      'createdAt': p.createdAt.toIso8601String(),
      'shopId': shopId,
    }).toList() ?? [];

    final billsBox = HiveBoxes.getBillsBox();
    final List<Map<String, dynamic>> bills = billsBox?.values.map((b) => {
      'id': b.id,
      'billNumber': b.billNumber,
      'date': b.date.toIso8601String(),
      'subTotal': b.subTotal,
      'tax': b.tax,
      'grandTotal': b.grandTotal,
      'paymentMethod': b.paymentMethod,
      'timestamp': b.timestamp.toIso8601String(),
      'shopId': shopId,
      'items': b.items.map((i) => {
        'productId': i.product.id,
        'name': i.product.name,
        'price': i.price,
        'quantity': i.quantity,
        'total': i.total,
      }).toList(),
    }).toList() ?? [];

    try {
      if (_selectedPlanId == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      // 1. Purchase the plan
      final purchaseRes = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/plans/purchase'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'planId': _selectedPlanId}),
      );

      if (purchaseRes.statusCode != 200) {
        final data = jsonDecode(purchaseRes.body);
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to purchase plan'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      if (!widget.isSyncRequired) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plan purchased successfully!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
        return;
      }

      // 2. Sync to cloud
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/sync-to-cloud'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'shop': shopData,
          'products': products,
          'bills': bills,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final cloudShopId = responseData['cloudShopId'];

        // Clear local data boxes since we are moving to cloud
        if (productsBox != null) await productsBox.clear();
        if (billsBox != null) await billsBox.clear();
        
        // Update storage type
        await box.put('storageType', 'Cloud Storage');

        // Update local IDs to true ObjectIDs so subsequent API calls work
        if (cloudShopId != null) {
          await box.put('shop_id', cloudShopId);
          await box.put('current_shop_id', cloudShopId);
        }

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully upgraded to Cloud! Data synced.'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); // return true to indicate success
        }
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to sync data'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade Plan'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.cloud_upload_outlined, size: 80, color: Color(0xFF1EA1F2)),
              const SizedBox(height: 24),
              const Text(
                'Unlock Cloud Features',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Upgrade to Cloud Storage to safely backup your data, add multiple shops, and manage employees.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              if (_isFetchingPlans)
                const Center(child: CircularProgressIndicator())
              else if (_plans.isEmpty)
                const Center(child: Text('No plans available at the moment.'))
              else
                ..._plans.map((plan) {
                  final isSelected = _selectedPlanId == plan['_id'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPlanId = plan['_id'];
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF1EA1F2) : Colors.grey.shade300, 
                          width: 2
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            plan['planName'] ?? 'Plan',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '₹${plan['price']} / ${plan['durationType']}',
                            style: TextStyle(
                              fontSize: 32, 
                              fontWeight: FontWeight.bold, 
                              color: isSelected ? const Color(0xFF1EA1F2) : Colors.black87
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(plan['description'] ?? '', textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              const Spacer(),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _selectedPlanId == null ? null : _subscribeToCloud,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1EA1F2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Subscribe Now',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
