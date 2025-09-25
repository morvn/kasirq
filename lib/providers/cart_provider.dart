import 'package:flutter/material.dart';
import '../data/models/cart_item.dart';
import '../data/models/menu_model.dart';

class CartProvider with ChangeNotifier {
  final Map<int, CartItem> _items = {}; // key = menu.id

  String? customerName;
  String? tableNo;

  Map<int, CartItem> get items => _items;

  int get totalItems =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  int get totalPrice => _items.values
      .fold(0, (sum, item) => sum + (item.quantity * item.menu.price));

  void setCustomerInfo(String name, String table) {
    customerName = name;
    tableNo = table;
    notifyListeners();
  }

  void addToCart(MenuModel menu) {
    if (_items.containsKey(menu.id)) {
      final current = _items[menu.id]!;
      _items[menu.id!] = current.copyWith(quantity: current.quantity + 1);
    } else {
      _items[menu.id!] = CartItem(menu: menu, quantity: 1);
    }
    notifyListeners();
  }

  void increaseQuantity(int menuId) {
    if (_items.containsKey(menuId)) {
      final item = _items[menuId]!;
      _items[menuId] = item.copyWith(quantity: item.quantity + 1);
      notifyListeners();
    }
  }

  void decreaseQuantity(int menuId) {
    if (_items.containsKey(menuId)) {
      final item = _items[menuId]!;
      if (item.quantity > 1) {
        _items[menuId] = item.copyWith(quantity: item.quantity - 1);
      } else {
        _items.remove(menuId);
      }
      notifyListeners();
    }
  }

  void removeItem(int menuId) {
    _items.remove(menuId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    customerName = null;
    tableNo = null;
    notifyListeners();
  }
}
