class MenuModel {
  final int? id;
  final String name;
  final int price;
  final String? imagePath;

  MenuModel({
    this.id,
    required this.name,
    required this.price,
    this.imagePath,
  });

  factory MenuModel.fromMap(Map<String, dynamic> map) => MenuModel(
        id: map['id'],
        name: map['name'],
        price: map['price'],
        imagePath: map['imagePath'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'price': price,
        'imagePath': imagePath,
      };
}
