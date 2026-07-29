import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';
import '../database/hive_boxes.dart';
import '../services/api_service.dart';

class BillController extends ChangeNotifier {
  Box<Bill>? _billsBox;
  bool _isCloud = false;

  List<Bill> _bills = [];
  bool _isLoading = false;

  List<Bill> get bills => _bills;
  bool get isLoading => _isLoading;

  // Cart state
  List<BillItem> _cart = [];
  double _tax = 0.0;
  String _paymentMethod = 'Cash';
  String? _companyName;
  String? _customerPhone;

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
    _cart.clear();
    _tax = 0.0;
    _paymentMethod = 'Cash';
    _companyName = null;
    _customerPhone = null;
    notifyListeners();
  }

  Future<Bill> saveBill() async {
    int billNumber = 1;
    if (!_isCloud && _billsBox != null) {
      billNumber = _billsBox!.length + 1;
    } else {
      billNumber = DateTime.now().millisecondsSinceEpoch % 100000;
    }

    final now = DateTime.now();

    final newBill = Bill(
      id: now.millisecondsSinceEpoch.toString(),
      billNumber: billNumber,
      date: now,
      items: List.from(_cart),
      subTotal: subTotal,
      tax: _tax,
      grandTotal: grandTotal,
      paymentMethod: _paymentMethod,
      companyName: _companyName,
      customerPhone: _customerPhone,
      timestamp: now,
    );

    if (_isCloud) {
      await ApiService.addBill(newBill);
    } else {
      if (_billsBox != null) {
        await _billsBox!.put(newBill.id, newBill);
      }
    }

    _bills.insert(0, newBill);

    clearCart();
    return newBill;
  }
}
