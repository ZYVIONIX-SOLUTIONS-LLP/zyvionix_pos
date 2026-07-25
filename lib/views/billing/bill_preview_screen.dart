// // ignore_for_file: unused_field

// import 'package:flutter/material.dart';
// import 'package:pdf/pdf.dart';
// import 'package:printing/printing.dart';
// import 'package:share_plus/share_plus.dart';
// import '../../models/bill.dart';
// import '../../services/pdf_service.dart';
// import '../../services/printer_service.dart';
// import 'package:blue_thermal_printer/blue_thermal_printer.dart';

// class BillPreviewScreen extends StatefulWidget {
//   final Bill bill;

//   const BillPreviewScreen({super.key, required this.bill});

//   @override
//   State<BillPreviewScreen> createState() => _BillPreviewScreenState();
// }

// class _BillPreviewScreenState extends State<BillPreviewScreen> {
//   final BluetoothPrinterService _printerService = BluetoothPrinterService();
//   List<BluetoothDevice> _devices = [];
//   BluetoothDevice? _selectedDevice;
//   bool _isConnected = false;

//   @override
//   void initState() {
//     super.initState();
//     _initBluetooth();
//   }

//   Future<void> _initBluetooth() async {
//     _devices = await _printerService.getPairedDevices();
//     _isConnected = await _printerService.isConnected();
//     if (mounted) setState(() {});
//   }

//   void _printViaBluetooth() async {
//     if (_devices.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'No Bluetooth printers found. Please pair one in settings.',
//           ),
//         ),
//       );
//       return;
//     }

//     if (!_isConnected) {
//       showDialog(
//         context: context,
//         builder: (context) {
//           return AlertDialog(
//             title: const Text('Select Printer'),
//             content: SizedBox(
//               width: double.maxFinite,
//               child: ListView.builder(
//                 shrinkWrap: true,
//                 itemCount: _devices.length,
//                 itemBuilder: (context, index) {
//                   return ListTile(
//                     title: Text(_devices[index].name ?? ''),
//                     subtitle: Text(_devices[index].address ?? ''),
//                     onTap: () async {
//                       Navigator.pop(context);
//                       bool connected = await _printerService.connect(
//                         _devices[index],
//                       );
//                       if (connected) {
//                         setState(() {
//                           _isConnected = true;
//                           _selectedDevice = _devices[index];
//                         });
//                         _printerService.printBill(widget.bill);
//                       } else {
//                         if (mounted) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                               content: Text('Failed to connect to printer.'),
//                             ),
//                           );
//                         }
//                       }
//                     },
//                   );
//                 },
//               ),
//             ),
//           );
//         },
//       );
//     } else {
//       _printerService.printBill(widget.bill);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Bill Preview'),

//         actions: [
//           IconButton(
//             icon: const Icon(Icons.share),

//             onPressed: () async {
//               final pdfBytes = await PdfService.generateReceipt(widget.bill);
//               final xFile = XFile.fromData(
//                 pdfBytes,
//                 mimeType: 'application/pdf',
//                 name: 'bill_${widget.bill.billNumber}.pdf',
//               );
//               await Share.shareXFiles([
//                 xFile,
//               ], text: 'Receipt for Bill #${widget.bill.billNumber}');
//             },
//           ),

//           IconButton(
//             onPressed: () {
//               _printViaBluetooth;
//             },
//             icon: Icon(Icons.print),
//           ),
//         ],
//       ),
//       body: PdfPreview(
//         build: (format) => PdfService.generateReceipt(widget.bill),
//         canChangeOrientation: false,
//         canChangePageFormat: false,
//         canDebug: false,
//         initialPageFormat: PdfPageFormat.roll80,
//       ),
//       // floatingActionButton: FloatingActionButton.extended(
//       //   onPressed: _printViaBluetooth,
//       //   icon: const Icon(Icons.print),
//       //   label: const Text('Thermal Print'),
//       //   backgroundColor: AppColors.primary,
//       // ),
//     );
//   }
// }

// ignore_for_file: unused_field

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/bill.dart';
import '../../services/pdf_service.dart';
import '../../services/printer_service.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class BillPreviewScreen extends StatefulWidget {
  final Bill bill;

  const BillPreviewScreen({super.key, required this.bill});

  @override
  State<BillPreviewScreen> createState() => _BillPreviewScreenState();
}

class _BillPreviewScreenState extends State<BillPreviewScreen> {
  final BluetoothPrinterService _printerService = BluetoothPrinterService();
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;
  bool _isSharing = false;
  bool _isPrinting = false;
  bool _showFullPdf = false;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    try {
      _devices = await _printerService.getPairedDevices();
      _isConnected = await _printerService.isConnected();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _shareReceipt() async {
    setState(() => _isSharing = true);
    try {
      final pdfBytes = await PdfService.generateReceipt(widget.bill);
      final xFile = XFile.fromData(
        pdfBytes,
        mimeType: 'application/pdf',
        name: 'bill_${widget.bill.billNumber}.pdf',
      );
      await Share.shareXFiles([
        xFile,
      ], text: 'Receipt for Bill #${widget.bill.billNumber}');
    } catch (e) {
      _showSnack('Could not share receipt: $e');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _printViaBluetooth() async {
    if (_devices.isEmpty) {
      _showSnack('No Bluetooth printers found. Please pair one in settings.');
      return;
    }

    if (!_isConnected) {
      final device = await showDialog<BluetoothDevice>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Printer'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final d = _devices[index];
                return ListTile(
                  leading: const Icon(Icons.print),
                  title: Text(d.name ?? 'Unknown device'),
                  subtitle: Text(d.address ?? ''),
                  onTap: () => Navigator.pop(context, d),
                );
              },
            ),
          ),
        ),
      );

      if (device == null) return;

      setState(() => _isPrinting = true);
      try {
        final connected = await _printerService.connect(device);
        if (!connected) {
          _showSnack('Failed to connect to printer.');
          return;
        }
        setState(() {
          _isConnected = true;
          _selectedDevice = device;
        });
        await _printerService.printBill(widget.bill);
        _showSnack('Sent to printer.');
      } catch (e) {
        _showSnack('Printing failed: $e');
      } finally {
        if (mounted) setState(() => _isPrinting = false);
      }
    } else {
      setState(() => _isPrinting = true);
      try {
        await _printerService.printBill(widget.bill);
        _showSnack('Sent to printer.');
      } catch (e) {
        _showSnack('Printing failed: $e');
      } finally {
        if (mounted) setState(() => _isPrinting = false);
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9EBEE),
      appBar: AppBar(
        title: const Text('Bill Preview'),
        actions: [
          IconButton(
            tooltip: _showFullPdf ? 'Styled preview' : 'Full PDF preview',
            icon: Icon(
              _showFullPdf ? Icons.receipt_long : Icons.picture_as_pdf_outlined,
            ),
            onPressed: () => setState(() => _showFullPdf = !_showFullPdf),
          ),
          IconButton(
            tooltip: 'Share',
            icon: _isSharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.share),
            onPressed: _isSharing ? null : _shareReceipt,
          ),
          IconButton(
            tooltip: 'Print',
            icon: _isPrinting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    Icons.print,
                    color: _isConnected ? Colors.greenAccent : Colors.white,
                  ),
            onPressed: _isPrinting ? null : _printViaBluetooth,
          ),
        ],
      ),
      body: _showFullPdf
          ? PdfPreview(
              build: (format) => PdfService.generateReceipt(widget.bill),
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              initialPageFormat: PdfPageFormat.roll80,
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: ThermalReceiptCard(bill: widget.bill)),
            ),
    );
  }
}

class ThermalReceiptCard extends StatelessWidget {
  final Bill bill;
  const ThermalReceiptCard({super.key, required this.bill});

  static const _mono = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12.5,
    height: 1.4,
    color: Color(0xFF2B2B2B),
  );

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFDFDF9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Text(
                    'ZYVIONIX POS',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      letterSpacing: 1.2,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                const Center(child: Text('Ernakulam, Kochi', style: _mono)),
                const Center(child: Text('Ph: 6282714883', style: _mono)),
                const SizedBox(height: 10),
                _DashedDivider(),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Bill No: ${bill.billNumber}', style: _mono),
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(bill.date),
                      style: _mono,
                    ),
                  ],
                ),
                if (bill.customerName != null) ...[
                  const SizedBox(height: 2),
                  Text('Customer: ${bill.customerName}', style: _mono),
                ],
                const SizedBox(height: 8),
                _DashedDivider(),
                const SizedBox(height: 6),
                Row(
                  children: const [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Item',
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Qty',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Price',
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Total',
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _DashedDivider(),
                const SizedBox(height: 4),
                ...bill.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            item.product.name,
                            style: _mono,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: _SingleLineCell(
                            text: '${item.quantity}',
                            align: Alignment.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _SingleLineCell(
                            text: item.price.toStringAsFixed(2),
                            align: Alignment.centerRight,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _SingleLineCell(
                            text: item.total.toStringAsFixed(2),
                            align: Alignment.centerRight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _DashedDivider(),
                const SizedBox(height: 6),
                _totalRow('Subtotal', bill.subTotal, currency),
                if (bill.discount > 0)
                  _totalRow('Discount', -bill.discount, currency),
                if (bill.tax > 0) _totalRow('Tax', bill.tax, currency),
                const SizedBox(height: 6),
                _DashedDivider(),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'GRAND TOTAL',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Rs. ${bill.grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Payment Mode', style: _mono),
                    Text(bill.paymentMethod, style: _mono),
                  ],
                ),
                const SizedBox(height: 14),
                _DashedDivider(),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'THANK YOU, VISIT AGAIN!',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    '* * * * * * * * * * * * * * * *',
                    style: _mono.copyWith(color: Colors.grey.shade400),
                  ),
                ),
              ],
            ),
          ),
          // Torn / perforated bottom edge.
          ClipPath(
            clipper: _ZigzagClipper(),
            child: Container(height: 14, color: const Color(0xFFFDFDF9)),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double value, NumberFormat currency) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: _mono),
          Text(value.toStringAsFixed(2), style: _mono),
        ],
      ),
    );
  }
}

/// A table cell that guarantees its text stays on one line — if the
/// available width is ever too tight (e.g. large system font scaling),
/// it shrinks to fit rather than wrapping onto a second line.
class _SingleLineCell extends StatelessWidget {
  final String text;
  final Alignment align;

  const _SingleLineCell({required this.text, required this.align});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: align,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: align,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: ThermalReceiptCard._mono,
        ),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 5.0;
        const dashSpace = 3.0;
        final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          children: List.generate(
            count,
            (_) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: dashSpace / 2),
              child: Container(
                width: dashWidth,
                height: 1,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ZigzagClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const toothWidth = 10.0;
    final path = Path()..moveTo(0, 0);
    var x = 0.0;
    var up = true;
    while (x < size.width) {
      x += toothWidth;
      path.lineTo(x, up ? size.height : 0);
      up = !up;
    }
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
