import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import '../models/bill.dart';
import '../database/hive_boxes.dart';

class BluetoothPrinterService {
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      return await _bluetooth.getBondedDevices();
    } catch (e) {
      return [];
    }
  }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      await _bluetooth.connect(device);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> disconnect() async {
    await _bluetooth.disconnect();
  }

  Future<bool> isConnected() async {
    bool? isConnected = await _bluetooth.isConnected;
    return isConnected ?? false;
  }

  Future<void> printBill(Bill bill, {bool is80mm = false}) async {
    final bool connected = await isConnected();
    if (!connected) return;

    final profile = await CapabilityProfile.load();
    final generator = Generator(
      is80mm ? PaperSize.mm80 : PaperSize.mm58,
      profile,
    );
    List<int> bytes = [];

    final box = HiveBoxes.getSettingsBox();
    String companyName = box.get('shop_name', defaultValue: 'ZYVIONIX POS');
    String address = box.get('offline_company_address', defaultValue: '');
    String rawPhone = box.get('shop_mobile') ?? box.get('user_phone') ?? '';

    bytes += generator.text(
      companyName,
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );

    if (address.isNotEmpty) {
      bytes += generator.text(
        address,
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    
    if (rawPhone.isNotEmpty) {
      bytes += generator.text(
        'Ph: $rawPhone',
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    
    bytes += generator.feed(1);

    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(text: 'Bill No: ${bill.billNumber}', width: 6),
      PosColumn(
        text: DateFormat('dd MMM yyyy').format(bill.date),
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    if (bill.companyName != null) {
      bytes += generator.text('Company: ${bill.companyName}');
    }

    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(text: 'Item', width: 4, styles: const PosStyles(bold: true)),
      PosColumn(
        text: 'Qty',
        width: 2,
        styles: const PosStyles(bold: true, align: PosAlign.center),
      ),
      PosColumn(
        text: 'Price',
        width: 3,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
      PosColumn(
        text: 'Total',
        width: 3,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
    ]);
    bytes += generator.hr();

    for (var item in bill.items) {
      bytes += generator.row([
        PosColumn(text: item.product.name, width: 4),
        PosColumn(
          text: '${item.quantity}',
          width: 2,
          styles: const PosStyles(align: PosAlign.center),
        ),
        PosColumn(
          text: item.price.toStringAsFixed(2),
          width: 3,
          styles: const PosStyles(align: PosAlign.right),
        ),
        PosColumn(
          text: item.total.toStringAsFixed(2),
          width: 3,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(text: 'Subtotal', width: 6),
      PosColumn(
        text: bill.subTotal.toStringAsFixed(2),
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    if (bill.tax > 0) {
      bytes += generator.row([
        PosColumn(text: 'Tax', width: 6),
        PosColumn(
          text: bill.tax.toStringAsFixed(2),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(
        text: 'Grand Total',
        width: 6,
        styles: const PosStyles(bold: true, height: PosTextSize.size2),
      ),
      PosColumn(
        text: bill.grandTotal.toStringAsFixed(2),
        width: 6,
        styles: const PosStyles(
          bold: true,
          height: PosTextSize.size2,
          align: PosAlign.right,
        ),
      ),
    ]);

    bytes += generator.text('Payment Mode: ${bill.paymentMethod}');

    bytes += generator.feed(1);
    bytes += generator.hr();
    bytes += generator.text(
      'Thank You, Visit Again!',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.feed(2);
    bytes += generator.cut();

    _bluetooth.writeBytes(Uint8List.fromList(bytes));
  }
}
