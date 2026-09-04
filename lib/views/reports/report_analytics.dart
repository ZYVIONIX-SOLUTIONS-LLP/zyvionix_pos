import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../database/hive_boxes.dart';
import '../../models/bill.dart';
import 'dart:math';

class ReportAnalytics extends StatefulWidget {
  const ReportAnalytics({super.key});

  @override
  State<ReportAnalytics> createState() => _ReportAnalyticsState();
}

class _ReportAnalyticsState extends State<ReportAnalytics> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _analyticsData;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final settingsBox = HiveBoxes.getSettingsBox();
    final storageType = settingsBox.get('storageType', defaultValue: 'Device Storage');
    final isCloud = storageType == 'Cloud Storage' || storageType == 'cloud';

    if (isCloud) {
      final data = await ApiService.getAnalytics();
      if (data != null) {
        _analyticsData = data;
      }
    } else {
      _analyticsData = _calculateLocalAnalytics();
    }

    setState(() => _isLoading = false);
    if (_analyticsData != null) {
      _animController.forward();
    }
  }

  Map<String, dynamic> _calculateLocalAnalytics() {
    final billsBox = HiveBoxes.getBillsBox();
    if (billsBox == null) return {};

    final allBills = billsBox.values.toList();
    
    // 1. Overview
    double totalRevenue = 0;
    for (var b in allBills) {
      totalRevenue += b.grandTotal;
    }
    final totalBills = allBills.length;
    final avgOrderValue = totalBills > 0 ? totalRevenue / totalBills : 0;

    // 2. Sales Trend (Last 30 Days)
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentBills = allBills.where((b) => b.date.isAfter(thirtyDaysAgo)).toList();
    
    Map<String, double> salesTrendMap = {};
    for (int i = 29; i >= 0; i--) {
      final d = DateTime.now().subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(d);
      salesTrendMap[dateStr] = 0;
    }

    for (var b in recentBills) {
      final dateStr = DateFormat('yyyy-MM-dd').format(b.date);
      if (salesTrendMap.containsKey(dateStr)) {
        salesTrendMap[dateStr] = salesTrendMap[dateStr]! + b.grandTotal;
      }
    }

    final salesTrend = salesTrendMap.entries.map((e) => {
      'date': e.key,
      'revenue': e.value
    }).toList();

    // 3. Top Products
    Map<String, Map<String, dynamic>> productSales = {};
    for (var b in allBills) {
      for (var item in b.items) {
        if (!productSales.containsKey(item.product.name)) {
          productSales[item.product.name] = {
            'name': item.product.name,
            'quantity': 0,
            'revenue': 0.0,
          };
        }
        productSales[item.product.name]!['quantity'] += item.quantity;
        productSales[item.product.name]!['revenue'] += item.total;
      }
    }

    final topProducts = productSales.values.toList();
    topProducts.sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

    return {
      'overview': {
        'totalRevenue': totalRevenue,
        'totalBills': totalBills,
        'avgOrderValue': avgOrderValue,
      },
      'salesTrend': salesTrend,
      'topProducts': topProducts.take(10).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Reports & Analytics', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analyticsData == null || _analyticsData!.isEmpty
              ? _buildEmptyState()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildOverviewCards(),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Sales Trend (Last 30 Days)'),
                        const SizedBox(height: 12),
                        _buildSalesChart(),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Top Selling Products'),
                        const SizedBox(height: 12),
                        _buildTopProducts(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Analytics Data',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'Create some bills to see insights here.',
            style: TextStyle(color: Colors.grey.shade500),
          )
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final formatter = DateFormat('MMMM yyyy');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Business Insights',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 4),
            Text(
              'Overview for ${formatter.format(now)}',
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.insights, color: Colors.blue),
        ),
      ],
    );
  }

  Widget _buildOverviewCards() {
    final overview = _analyticsData!['overview'] ?? {};
    final totalRevenue = (overview['totalRevenue'] ?? 0).toDouble();
    final totalBills = (overview['totalBills'] ?? 0).toInt();
    final avgOrderValue = (overview['avgOrderValue'] ?? 0).toDouble();

    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Column(
      children: [
        _buildStatCard(
          title: 'Total Revenue',
          value: currency.format(totalRevenue),
          icon: Icons.account_balance_wallet,
          color: const Color(0xFF10B981),
          gradient: const LinearGradient(colors: [Color(0xFF34D399), Color(0xFF10B981)]),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Bills',
                value: totalBills.toString(),
                icon: Icons.receipt_long,
                color: const Color(0xFF3B82F6),
                gradient: const LinearGradient(colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)]),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Avg Order Value',
                value: currency.format(avgOrderValue),
                icon: Icons.shopping_cart,
                color: const Color(0xFF8B5CF6),
                gradient: const LinearGradient(colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6)]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required LinearGradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF111827),
      ),
    );
  }

  Widget _buildSalesChart() {
    final salesTrend = _analyticsData!['salesTrend'] as List<dynamic>? ?? [];
    if (salesTrend.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: Text('Not enough data')));
    }

    double maxRevenue = 0;
    for (var item in salesTrend) {
      final rev = (item['revenue'] ?? 0).toDouble();
      if (rev > maxRevenue) maxRevenue = rev;
    }

    if (maxRevenue == 0) maxRevenue = 100; // avoid division by zero

    return Container(
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: salesTrend.map((item) {
                final rev = (item['revenue'] ?? 0).toDouble();
                final percentage = rev / maxRevenue;
                final date = item['date'].toString();
                final parsedDate = DateTime.tryParse(date) ?? DateTime.now();
                final isToday = parsedDate.day == DateTime.now().day && parsedDate.month == DateTime.now().month;
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Tooltip(
                      message: '₹${rev.toStringAsFixed(0)} on ${DateFormat('MMM dd').format(parsedDate)}',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOut,
                                width: double.infinity,
                                height: percentage == 0 ? 4 : percentage * 180,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isToday
                                        ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                                        : [const Color(0xFF60A5FA), const Color(0xFF3B82F6)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('30 Days Ago', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text('Today', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    final topProducts = _analyticsData!['topProducts'] as List<dynamic>? ?? [];
    if (topProducts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No product data yet.', style: TextStyle(color: Colors.grey)),
      );
    }

    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: topProducts.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          final p = topProducts[index];
          final name = p['name'] ?? 'Unknown';
          final qty = (p['quantity'] ?? 0).toInt();
          final rev = (p['revenue'] ?? 0).toDouble();

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: Text(
                '${index + 1}',
                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: Text('Sold: $qty items', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            trailing: Text(
              currency.format(rev),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF10B981),
                fontSize: 15,
              ),
            ),
          );
        },
      ),
    );
  }
}
