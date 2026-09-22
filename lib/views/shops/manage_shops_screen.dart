import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:zyvionix_pos/controllers/language_controller.dart';
import 'package:zyvionix_pos/database/hive_boxes.dart';
import 'package:zyvionix_pos/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:zyvionix_pos/views/shops/create_shop_screen.dart';
import 'package:zyvionix_pos/views/shops/shop_dashboard_screen.dart';
import 'package:floating_snackbar/floating_snackbar.dart';
import 'package:zyvionix_pos/services/api_service.dart';

class ManageShopsScreen extends StatefulWidget {
  const ManageShopsScreen({super.key});

  @override
  State<ManageShopsScreen> createState() => _ManageShopsScreenState();
}

class _ManageShopsScreenState extends State<ManageShopsScreen> {
  bool _isLoading = true;
  List<dynamic> _shops = [];
  String _currentShopId = '';
  bool _hasSubscription = false;
  bool _isBasePlan = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final profile = await ApiService.getProfile();
    if (profile != null && profile['currentPlan'] != null) {
      _hasSubscription = true;
      _isBasePlan =
          profile['currentPlan']['planName'] == 'Base Plan' ||
          profile['currentPlan']['isDefaultTrial'] == true;
    } else {
      _hasSubscription = false;
      _isBasePlan = false;
    }
    await _fetchShops();
  }

  Future<void> _fetchShops() async {
    final box = HiveBoxes.getSettingsBox();
    final token = box.get('auth_token');
    _currentShopId = box.get('current_shop_id', defaultValue: '');

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/shops'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _shops = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
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
        title: Text(context.tr('manage_shops')),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
      floatingActionButton: _hasSubscription && (!_isBasePlan || _shops.isEmpty)
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const CreateShopScreen(isForced: false),
                  ),
                );
                if (result == true) {
                  setState(() => _isLoading = true);
                  _fetchShops();
                }
              },
              backgroundColor: const Color(0xFF1EA1F2),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(context.tr('new_shop')),
            )
          : null,
    );
  }

  Widget _buildContent() {
    if (_shops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Shops Found',
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _shops.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final shop = _shops[index];
        final isActive = shop['_id'] == _currentShopId;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShopDashboardScreen(
                  shop: shop,
                  isActive: isActive,
                  onStatusChanged: () {
                    setState(() => _isLoading = true);
                    _fetchShops();
                  },
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isActive
                  ? Border.all(color: const Color(0xFF1EA1F2), width: 2)
                  : null,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF1EA1F2).withOpacity(0.1)
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    color: isActive
                        ? const Color(0xFF1EA1F2)
                        : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop['name'] ?? 'Unknown Shop',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      if (shop['address'] != null &&
                          shop['address'].isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          shop['address'],
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1EA1F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (!isActive)
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
