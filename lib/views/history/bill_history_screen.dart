import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:zyvionix_pos/views/billing/bill_preview_screen.dart';
import '../../models/bill.dart';
import '../../database/hive_boxes.dart';
import '../../constants/app_theme.dart';

class BillHistoryScreen extends StatefulWidget {
  const BillHistoryScreen({super.key});

  @override
  State<BillHistoryScreen> createState() => _BillHistoryScreenState();
}

class _BillHistoryScreenState extends State<BillHistoryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Bills')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by Bill No or Customer',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: HiveBoxes.getBillsBox().listenable(),
              builder: (context, Box<Bill> box, _) {
                if (box.values.isEmpty) {
                  return const Center(child: Text('No bills found.'));
                }

                var bills = box.values.toList();
                bills.sort((a, b) => b.date.compareTo(a.date));

                if (_searchQuery.isNotEmpty) {
                  bills = bills.where((b) {
                    final matchNo = b.billNumber.toString().contains(
                      _searchQuery,
                    );
                    final matchName =
                        b.customerName?.toLowerCase().contains(_searchQuery) ??
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
                          if (bill.customerName != null)
                            Text('Customer: ${bill.customerName}'),
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
