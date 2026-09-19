import 'package:hive/hive.dart';
import '../models/product.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';

class HiveBoxes {
  static const String settingsBox = 'settings_box';

  static Future<void> initHiveAndOpenBoxes() async {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ProductAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(BillAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(BillItemAdapter());

    await Hive.openBox(settingsBox);
  }

  static Future<void> openUserBoxes(String userId) async {}

  static Future<void> closeUserBoxes() async {}

  static Box getSettingsBox() => Hive.box(settingsBox);
}
