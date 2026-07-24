import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';
import '../database/hive_boxes.dart';

class BillController extends ChangeNotifier {
  late Box<Bill> _billsBox;

  // Cart state
  List<BillItem> _cart = [];
  double _discount = 0.0;
  double _tax = 0.0;
  String _paymentMethod = 'Cash';
  String? _customerName;
  String? _customerPhone;

  List<BillItem> get cart => _cart;
  double get discount => _discount;
  double get tax => _tax;
  String get paymentMethod => _paymentMethod;
  String? get customerName => _customerName;
  String? get customerPhone => _customerPhone;

  double get subTotal => _cart.fold(0, (sum, item) => sum + item.total);
  double get grandTotal => subTotal - _discount + _tax;

  BillController() {
    _billsBox = HiveBoxes.getBillsBox();
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

  void setDiscount(double amount) {
    _discount = amount;
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

  void setCustomerDetails(String name, String phone) {
    _customerName = name.isEmpty ? null : name;
    _customerPhone = phone.isEmpty ? null : phone;
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _discount = 0.0;
    _tax = 0.0;
    _paymentMethod = 'Cash';
    _customerName = null;
    _customerPhone = null;
    notifyListeners();
  }

  Future<Bill> saveBill() async {
    final billNumber = _billsBox.length + 1;
    final now = DateTime.now();

    final newBill = Bill(
      id: now.millisecondsSinceEpoch.toString(),
      billNumber: billNumber,
      date: now,
      items: List.from(_cart),
      subTotal: subTotal,
      discount: _discount,
      tax: _tax,
      grandTotal: grandTotal,
      paymentMethod: _paymentMethod,
      customerName: _customerName,
      customerPhone: _customerPhone,
    );

    await _billsBox.put(newBill.id, newBill);
    clearCart();
    return newBill;
  }
}
