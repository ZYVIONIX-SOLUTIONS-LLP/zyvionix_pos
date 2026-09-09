import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:zyvionix_pos/views/billing/bill_preview_screen.dart';
import '../../controllers/bill_controller.dart';
import '../../constants/app_theme.dart';

class BillHistoryScreen extends StatefulWidget {
  const BillHistoryScreen({super.key});

  @override
  State<BillHistoryScreen> createState() => _BillHistoryScreenState();
}

class _BillHistoryScreenState extends State<BillHistoryScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All Time';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Bills')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by Bill No or Customer',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      icon: const Icon(Icons.filter_list, size: 20),
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      items: ['All Time', 'This Month', 'Last Month', 'This Year']
                          .map((String value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              ))
                          .toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedFilter = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<BillController>(
              builder: (context, controller, child) {
                if (controller.isLoading) {
                  return const Center(child: SpinKitFadingCircle(color: Color(0xFF1EA1F2), size: 50.0));
                }

                if (controller.bills.isEmpty) {
                  return const Center(child: Text('No bills found.'));
                }

                var bills = List.from(controller.bills);

                final now = DateTime.now();
                if (_selectedFilter == 'This Month') {
                  bills = bills.where((b) => b.date.month == now.month && b.date.year == now.year).toList();
                } else if (_selectedFilter == 'Last Month') {
                  final lastMonth = DateTime(now.year, now.month - 1);
                  bills = bills.where((b) => b.date.month == lastMonth.month && b.date.year == lastMonth.year).toList();
                } else if (_selectedFilter == 'This Year') {
                  bills = bills.where((b) => b.date.year == now.year).toList();
                }

                if (_searchQuery.isNotEmpty) {
                  bills = bills.where((b) {
                    final matchNo = b.billNumber.toString().contains(
                      _searchQuery,
                    );
                    final matchName =
                        b.companyName?.toLowerCase().contains(_searchQuery) ??
                        false;
                    return matchNo || matchName;
                  }).toList();
                }

                return ListView.separated(
                  itemCount: bills.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final bill = bills[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(
                        'Bill #${bill.billNumber}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat(
                              'dd MMM yyyy, hh:mm a',
                            ).format(bill.date),
                          ),
                          if (bill.companyName != null)
                            Text('Company: ${bill.companyName}'),
                        ],
                      ),
                      trailing: Text(
                        '₹${bill.grandTotal.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppColors.primary),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BillPreviewScreen(bill: bill),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
