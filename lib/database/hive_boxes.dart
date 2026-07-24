import 'package:hive/hive.dart';
import '../models/product.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';

class HiveBoxes {
  static const String productsBox = 'products_box';
  static const String billsBox = 'bills_box';
  static const String settingsBox = 'settings_box';

  static Future<void> initHiveAndOpenBoxes() async {
    Hive.registerAdapter(ProductAdapter());
    Hive.registerAdapter(BillAdapter());
    Hive.registerAdapter(BillItemAdapter());

    await Hive.openBox<Product>(productsBox);
    await Hive.openBox<Bill>(billsBox);
    await Hive.openBox(settingsBox);
  }

  static Box<Product> getProductsBox() => Hive.box<Product>(productsBox);
  static Box<Bill> getBillsBox() => Hive.box<Bill>(billsBox);
  static Box getSettingsBox() => Hive.box(settingsBox);
}
