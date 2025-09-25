import 'menu_model.dart';

class CartItem {
  final MenuModel menu;
  final int quantity;

  CartItem({required this.menu, this.quantity = 1});

  CartItem copyWith({MenuModel? menu, int? quantity}) {
    return CartItem(
      menu: menu ?? this.menu,
      quantity: quantity ?? this.quantity,
    );
  }
}
