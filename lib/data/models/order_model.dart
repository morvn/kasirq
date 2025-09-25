class OrderModel {
  final int? id;
  final int menuId;
  final int quantity;

  OrderModel({
    this.id,
    required this.menuId,
    required this.quantity,
  });

  factory OrderModel.fromMap(Map<String, dynamic> json) => OrderModel(
        id: json['id'],
        menuId: json['menu_id'],
        quantity: json['quantity'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'menu_id': menuId,
        'quantity': quantity,
      };
}
