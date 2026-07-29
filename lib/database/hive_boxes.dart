import 'package:hive/hive.dart';
import '../models/product.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';

class HiveBoxes {
  static const String settingsBox = 'settings_box';

  static String? _currentUserId;

  static Future<void> initHiveAndOpenBoxes() async {
    Hive.registerAdapter(ProductAdapter());
    Hive.registerAdapter(BillAdapter());
    Hive.registerAdapter(BillItemAdapter());

    await Hive.openBox(settingsBox);
  }

  static Future<void> openUserBoxes(String userId) async {
    _currentUserId = userId;
    await Hive.openBox<Product>('products_$userId');
    await Hive.openBox<Bill>('bills_$userId');
  }

  static Future<void> closeUserBoxes() async {
    if (_currentUserId != null) {
      if (Hive.isBoxOpen('products_$_currentUserId')) {
        await Hive.box<Product>('products_$_currentUserId').close();
      }
      if (Hive.isBoxOpen('bills_$_currentUserId')) {
        await Hive.box<Bill>('bills_$_currentUserId').close();
      }
      _currentUserId = null;
    }
  }

  static Box<Product>? getProductsBox() {
    if (_currentUserId == null || !Hive.isBoxOpen('products_$_currentUserId')) return null;
    return Hive.box<Product>('products_$_currentUserId');
  }

  static Box<Bill>? getBillsBox() {
    if (_currentUserId == null || !Hive.isBoxOpen('bills_$_currentUserId')) return null;
    return Hive.box<Bill>('bills_$_currentUserId');
  }

  static Box getSettingsBox() => Hive.box(settingsBox);
}
