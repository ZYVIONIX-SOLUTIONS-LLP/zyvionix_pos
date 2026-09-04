import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';
import '../database/hive_boxes.dart';
import '../services/api_service.dart';
import '../services/backup_service.dart';

class BillController extends ChangeNotifier {
  Box<Bill>? _billsBox;
  bool _isCloud = false;

  List<Bill> _bills = [];
  bool _isLoading = false;

  List<Bill> get bills => _bills;
  bool get isLoading => _isLoading;

  // Cart state
  Bill? _editingBill;
  List<BillItem> _cart = [];
  double _tax = 0.0;
  String _paymentMethod = 'Cash';
  String? _companyName;
  String? _customerPhone;

  Bill? get editingBill => _editingBill;

  List<BillItem> get cart => _cart;
  double get tax => _tax;
  String get paymentMethod => _paymentMethod;
  String? get companyName => _companyName;
  String? get customerPhone => _customerPhone;

  double get subTotal => _cart.fold(0, (sum, item) => sum + item.total);
  double get grandTotal => subTotal + _tax;

  BillController() {
    init();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    final settingsBox = HiveBoxes.getSettingsBox();
    final storageType = settingsBox.get('storageType', defaultValue: 'Device Storage');
    _isCloud = storageType == 'Cloud Storage' || storageType == 'cloud';
    
    if (!_isCloud) {
      _billsBox = HiveBoxes.getBillsBox();
      if (_billsBox != null) {
        _bills = _billsBox!.values.toList();
      }
    } else {
      try {
        _bills = await ApiService.getBills();
      } catch (e) {
        _bills = [];
      }
    }

    _bills.sort((a, b) => b.date.compareTo(a.date));
    _isLoading = false;
    notifyListeners();
  }

  void clear() {
    _billsBox = null;
    _isCloud = false;
    _bills = [];
    _isLoading = false;
    clearCart();
    notifyListeners();
  }

  void addToCart(Product product) {
    final existingIndex = _cart.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (existingIndex >= 0) {
      _cart[existingIndex].quantity += 1;
      _cart[existingIndex].total =
          _cart[existingIndex].quantity * _cart[existingIndex].price;
    } else {
      _cart.add(BillItem.create(product: product, quantity: 1));
    }
    notifyListeners();
  }

  void updateQuantity(BillItem item, int delta) {
    final index = _cart.indexWhere((i) => i.product.id == item.product.id);
    if (index >= 0) {
      final newQuantity = _cart[index].quantity + delta;
      if (newQuantity <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index].quantity = newQuantity;
        _cart[index].total = newQuantity * _cart[index].price;
      }
      notifyListeners();
    }
  }

  void removeFromCart(BillItem item) {
    _cart.removeWhere((i) => i.product.id == item.product.id);
    notifyListeners();
  }

  void setTax(double amount) {
    _tax = amount;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setCustomerDetails(String? company, String? phone) {
    _companyName = company?.isEmpty ?? true ? null : company;
    _customerPhone = phone?.isEmpty ?? true ? null : phone;
    notifyListeners();
  }

  void clearCart() {
    _editingBill = null;
    _cart.clear();
    _tax = 0.0;
    _paymentMethod = 'Cash';
    _companyName = null;
    _customerPhone = null;
    notifyListeners();
  }

  void loadBillForEditing(Bill bill) {
    _editingBill = bill;
    _cart = List.from(bill.items.map((e) => BillItem(
          product: e.product,
          quantity: e.quantity,
          price: e.price,
          total: e.total,
        )));
    _tax = bill.tax;
    _paymentMethod = bill.paymentMethod;
    _companyName = bill.companyName;
    _customerPhone = bill.customerPhone;
    notifyListeners();
  }

  Future<bool> deleteBill(Bill bill) async {
    bool success = true;
    if (_isCloud) {
      success = await ApiService.deleteBill(bill.id);
    } else {
      if (_billsBox != null) {
        await _billsBox!.delete(bill.id);
        final userId = HiveBoxes.getSettingsBox().get('user_id') ?? '';
        await BackupService.backupData(userId);
      }
    }
    if (success) {
      _bills.removeWhere((b) => b.id == bill.id);
      notifyListeners();
    }
    return success;
  }

  Future<Bill> saveBill() async {
    int billNumber = _editingBill?.billNumber ?? 1;
    if (_editingBill == null) {
      if (!_isCloud && _billsBox != null) {
        billNumber = _billsBox!.length + 1;
      } else {
        billNumber = DateTime.now().millisecondsSinceEpoch % 100000;
      }
    }

    final now = DateTime.now();

    final newBill = Bill(
      id: _editingBill?.id ?? now.millisecondsSinceEpoch.toString(),
      billNumber: billNumber,
      date: _editingBill?.date ?? now,
      items: List.from(_cart),
      subTotal: subTotal,
      tax: _tax,
      grandTotal: grandTotal,
      paymentMethod: _paymentMethod,
      companyName: _companyName,
      customerPhone: _customerPhone,
      timestamp: _editingBill?.timestamp ?? now,
      shopId: _editingBill?.shopId,
      billedBy: _editingBill?.billedBy,
      billedByType: _editingBill?.billedByType,
    );

    if (_isCloud) {
      if (_editingBill != null) {
        await ApiService.updateBill(newBill);
      } else {
        await ApiService.addBill(newBill);
      }
    } else {
      if (_billsBox != null) {
        await _billsBox!.put(newBill.id, newBill);
        final userId = HiveBoxes.getSettingsBox().get('user_id') ?? '';
        await BackupService.backupData(userId);
      }
    }

    if (_editingBill != null) {
      final index = _bills.indexWhere((b) => b.id == newBill.id);
      if (index != -1) {
        _bills[index] = newBill;
      }
    } else {
      _bills.insert(0, newBill);
    }

    clearCart();
    return newBill;
  }
}
