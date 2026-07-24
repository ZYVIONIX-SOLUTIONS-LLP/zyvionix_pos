// ignore_for_file: unused_field

import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    _devices = await _printerService.getPairedDevices();
    _isConnected = await _printerService.isConnected();
    if (mounted) setState(() {});
  }

  void _printViaBluetooth() async {
    if (_devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No Bluetooth printers found. Please pair one in settings.',
          ),
        ),
      );
      return;
    }

    if (!_isConnected) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Select Printer'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_devices[index].name ?? ''),
                    subtitle: Text(_devices[index].address ?? ''),
                    onTap: () async {
                      Navigator.pop(context);
                      bool connected = await _printerService.connect(
                        _devices[index],
                      );
                      if (connected) {
                        setState(() {
                          _isConnected = true;
                          _selectedDevice = _devices[index];
                        });
                        _printerService.printBill(widget.bill);
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to connect to printer.'),
                            ),
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ),
          );
        },
      );
    } else {
      _printerService.printBill(widget.bill);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Preview'),

        actions: [
          IconButton(
            icon: const Icon(Icons.share),

            onPressed: () async {
              final pdfBytes = await PdfService.generateReceipt(widget.bill);
              final xFile = XFile.fromData(
                pdfBytes,
                mimeType: 'application/pdf',
                name: 'bill_${widget.bill.billNumber}.pdf',
              );
              await Share.shareXFiles([
                xFile,
              ], text: 'Receipt for Bill #${widget.bill.billNumber}');
            },
          ),

          IconButton(
            onPressed: () {
              _printViaBluetooth;
            },
            icon: Icon(Icons.print),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => PdfService.generateReceipt(widget.bill),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        initialPageFormat: PdfPageFormat.roll80,
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _printViaBluetooth,
      //   icon: const Icon(Icons.print),
      //   label: const Text('Thermal Print'),
      //   backgroundColor: AppColors.primary,
      // ),
    );
  }
}
