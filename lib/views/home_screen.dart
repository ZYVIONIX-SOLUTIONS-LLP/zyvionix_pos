import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zyvionix_pos/constants/api_constants.dart';
import 'package:zyvionix_pos/models/bill.dart';
import 'package:zyvionix_pos/provider/navbar/navbar_provider.dart';
import 'package:zyvionix_pos/views/history/bill_history_screen.dart';
import '../database/hive_boxes.dart';
import '../services/api_service.dart';
import 'billing/bill_preview_screen.dart';
import '../controllers/bill_controller.dart';
import '../controllers/product_controller.dart';
import 'package:zyvionix_pos/views/shops/create_shop_screen.dart';
import 'onboarding/onboarding_showcase_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;
  List<dynamic> _adminBanners = [];

  String _selectedReportFilter = 'Today';
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Good Morning,';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon,';
    } else {
      return 'Good Evening,';
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchBanners();
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      final maxPages = _adminBanners.isNotEmpty ? _adminBanners.length : 5;
      if (_currentPage < maxPages - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkShop();
    });
  }

  Future<void> _fetchBanners() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.bannersUrl}?status=Active'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _adminBanners = data;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _refreshData() async {
    try {
      final billController = context.read<BillController>();
      await billController.fetchBills();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data refreshed successfully'),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to refresh data'),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _checkShop() async {
    final box = HiveBoxes.getSettingsBox();
    final shopId = box.get('shop_id');
    final userRole = box.get('user_role', defaultValue: 'Owner');

    if (shopId == null && userRole == 'Owner') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const CreateShopScreen(isForced: true),
        ),
      );
    }

    final isNewUser = box.get('is_new_user', defaultValue: false);
    if (isNewUser == true && mounted) {
      await OnboardingShowcaseDialog.show(context);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C64F2).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFF1C64F2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Exit App",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                ],
              ),
              content: const Text(
                "Are you sure you want to exit the APP?",
                style: TextStyle(color: Colors.black54, fontSize: 15),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1C64F2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Color(0xFF1C64F2)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C64F2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Exit"),
                ),
              ],
            );
          },
        );

        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FC),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color: const Color(0xFF1C64F2),
            backgroundColor: Colors.white,
            strokeWidth: 2.5,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 15),
                  _buildBanner(context),
                  const SizedBox(height: 24),
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildRecentBillsSection(),
                  const SizedBox(height: 24),

                  _buildReportAnalyticsHeader(context),
                  const SizedBox(height: 16),
                  _buildReportAnalyticsChart(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: ApiService.getProfile(),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final shopName =
            profile?['companyName'] ??
            HiveBoxes.getSettingsBox().get(
              'shop_name',
              defaultValue: 'Zyvionix Solutions',
            );

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getGreeting(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  shopName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                context.read<BottomNavbarProvider>().setIndex(2);
              },
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ZYVIONIX',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E3A8A),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'SOLUTIONS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBanner(BuildContext context) {
    final count = _adminBanners.isNotEmpty ? _adminBanners.length : 5;
    return SizedBox(
      height: 170,
      child: PageView.builder(
        controller: _pageController,
        itemCount: count,
        onPageChanged: (index) {
          _currentPage = index;
        },
        itemBuilder: (context, index) {
          if (_adminBanners.isNotEmpty && index < _adminBanners.length) {
            return _buildAdminBanner(context, _adminBanners[index]);
          }
          return _buildSingleBanner(context);
        },
      ),
    );
  }

  Widget _buildAdminBanner(BuildContext context, dynamic banner) {
    final String imageUrl = (banner['imageUrl'] ?? '').toString();
    final String title = (banner['title'] ?? '').toString();
    final String description = (banner['description'] ?? '').toString();

    return GestureDetector(
      onTap: () {
        context.read<BottomNavbarProvider>().setIndex(1);
      },
      child: Container(
        height: 170,
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF1E293B),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Banner Image
              if (imageUrl.startsWith('data:image/'))
                (() {
                  try {
                    final base64Str = imageUrl.split(',').last;
                    final bytes = base64Decode(base64Str);
                    return Image.memory(bytes, fit: BoxFit.cover);
                  } catch (_) {
                    return Container(color: const Color(0xFF1C64F2));
                  }
                })()
              else if (imageUrl.isNotEmpty)
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: const Color(0xFF1C64F2)),
                )
              else
                Container(color: const Color(0xFF1C64F2)),

              // Overlay Gradient for readable text
              if (title.isNotEmpty || description.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.75),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),

              if (title.isNotEmpty || description.isNotEmpty)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title.isNotEmpty)
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<BottomNavbarProvider>().setIndex(1);
      },
      child: Container(
        height: 170,
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF1C64F2), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background decorative curves
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              right: 80,
              bottom: -50,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),

            // Receipt Graphic on the right
            Positioned(right: 20, bottom: 0, child: _buildReceiptGraphic()),

            // Text and Button on the left
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create New Bill',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap once to start billing\nquick and easy',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.post_add_rounded,
                          color: Colors.blue.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'START BILLING',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.blue.shade700,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptGraphic() {
    return SizedBox(
      width: 100,
      height: 135,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Main paper
          Container(
            width: 85,
            height: 130,
            margin: const EdgeInsets.only(bottom: 5),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                _buildReceiptLine(width: 55),
                const SizedBox(height: 8),
                _buildReceiptLine(width: 35),
                const SizedBox(height: 16),
                _buildReceiptLine(width: 65),
                const SizedBox(height: 8),
                _buildReceiptLine(width: 50),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildReceiptLine(width: 25),
                    const SizedBox(width: 10),
                    _buildReceiptLine(width: 25),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildReceiptLine(width: 25),
                    const SizedBox(width: 10),
                    _buildReceiptLine(width: 25),
                  ],
                ),
              ],
            ),
          ),
          // Curled bottom effect
          Container(
            width: 95,
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey.shade300],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptLine({required double width}) {
    return Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Consumer<BillController>(
      builder: (context, controller, _) {
        if (controller.isLoading) {
          return const Center(
            child: SpinKitFadingCircle(color: Color(0xFF1EA1F2), size: 50.0),
          );
        }

        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);

        double todaysSale = 0.0;
        int billsToday = 0;

        for (var bill in controller.bills) {
          if (bill.date.isAfter(startOfDay)) {
            todaysSale += bill.grandTotal;
            billsToday++;
          }
        }

        return Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.currency_rupee,
                iconColor: Colors.blue.shade700,
                iconBgColor: Colors.blue.shade50,
                title: "Today's Sale",
                value: '₹${todaysSale.toStringAsFixed(0)}',
                trend: '12% vs yesterday', // Hardcoded trend for now
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.receipt_long,
                iconColor: Colors.green.shade700,
                iconBgColor: Colors.green.shade50,
                title: "Bills Today",
                value: billsToday.toString(),
                trend: '8% vs yesterday', // Hardcoded trend for now
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String value,
    required String trend,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.arrow_outward, color: Colors.green, size: 12),
              const SizedBox(width: 4),
              Text(
                trend,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBillsSection() {
    return Consumer<BillController>(
      builder: (context, controller, _) {
        if (controller.isLoading || controller.bills.isEmpty) {
          return const SizedBox.shrink();
        }

        var bills = List.from(controller.bills);
        bills.sort((a, b) => b.date.compareTo(a.date));
        final recentBills = bills.take(2).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Bills',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BillHistoryScreen(),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.blue.shade700,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentBills.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: Colors.grey.shade100,
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) {
                  final bill = recentBills[index];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BillPreviewScreen(bill: bill),
                        ),
                      );
                    },
                    borderRadius: index == 0
                        ? const BorderRadius.vertical(top: Radius.circular(16))
                        : index == recentBills.length - 1
                        ? const BorderRadius.vertical(
                            bottom: Radius.circular(16),
                          )
                        : BorderRadius.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.receipt_long,
                              color: Colors.blue.shade700,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bill #${bill.billNumber}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat(
                                    'dd MMM, hh:mm a',
                                  ).format(bill.date),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${bill.grandTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Paid',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.black26,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickCustomDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _customStartDate = picked;
        _customEndDate = picked;
      });
    } else {
      setState(() {
        _selectedReportFilter = 'Today';
      });
    }
  }

  Widget _buildReportAnalyticsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Report & Analytics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1E1E),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedReportFilter,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              items: ['Today', 'This Week', 'This Month', 'Custom'].map((
                String value,
              ) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedReportFilter = newValue;
                  });
                  if (newValue == 'Custom') {
                    _pickCustomDate(context);
                  }
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportAnalyticsChart() {
    return Consumer<BillController>(
      builder: (context, controller, _) {
        final now = DateTime.now();
        List<Bill> filteredBills = [];

        if (_selectedReportFilter == 'Today') {
          filteredBills = controller.bills
              .where(
                (b) =>
                    b.date.year == now.year &&
                    b.date.month == now.month &&
                    b.date.day == now.day,
              )
              .toList();
        } else if (_selectedReportFilter == 'This Week') {
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          filteredBills = controller.bills
              .where(
                (b) =>
                    b.date.isAfter(weekStart.subtract(const Duration(days: 1))),
              )
              .toList();
        } else if (_selectedReportFilter == 'This Month') {
          filteredBills = controller.bills
              .where(
                (b) => b.date.year == now.year && b.date.month == now.month,
              )
              .toList();
        } else if (_selectedReportFilter == 'Custom' &&
            _customStartDate != null) {
          filteredBills = controller.bills
              .where(
                (b) =>
                    b.date.year == _customStartDate!.year &&
                    b.date.month == _customStartDate!.month &&
                    b.date.day == _customStartDate!.day,
              )
              .toList();
        }

        Map<String, int> productSales = {};
        for (var bill in filteredBills) {
          for (var item in bill.items) {
            productSales[item.product.name] =
                (productSales[item.product.name] ?? 0) + item.quantity;
          }
        }

        if (productSales.isEmpty) {
          productSales = {'No Sales': 0};
        }

        var sortedSales = productSales.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topProducts = sortedSales.take(5).toList();
        final double maxY = topProducts.first.value.toDouble() * 1.2;

        List<BarChartGroupData> barGroups = [];
        for (int i = 0; i < topProducts.length; i++) {
          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: topProducts[i].value.toDouble(),
                  color: Colors.blue.shade400,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Top Selling Products',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY == 0 ? 10 : maxY,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 &&
                                value.toInt() < topProducts.length) {
                              String text = topProducts[value.toInt()].key;
                              if (text.length > 6)
                                text = '${text.substring(0, 6)}..';
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  text,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black54,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                          reservedSize: 28,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const SizedBox();
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: (maxY / 5) > 0
                          ? (maxY / 5).ceilToDouble()
                          : 1,
                      getDrawingHorizontalLine: (value) =>
                          FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: barGroups,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
