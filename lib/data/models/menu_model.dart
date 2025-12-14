class MenuModel {
  final int? id;
  final String? cloudId;
  final String name;
  final int price;
  final String? imagePath;
  final String? category;

  MenuModel({
    this.id,
    this.cloudId,
    required this.name,
    required this.price,
    this.imagePath,
    this.category,
  });

  MenuModel copyWith({
    int? id,
    String? cloudId,
    String? name,
    int? price,
    String? imagePath,
    String? category,
  }) {
    return MenuModel(
      id: id ?? this.id,
      cloudId: cloudId ?? this.cloudId,
      name: name ?? this.name,
      price: price ?? this.price,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
    );
  }

  factory MenuModel.fromMap(Map<String, dynamic> map) => MenuModel(
        id: map['id'],
        cloudId: map['cloudId'],
        name: map['name'],
        price: map['price'],
        imagePath: map['imagePath'],
        category: map['category'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'cloudId': cloudId,
        'name': name,
        'price': price,
        'imagePath': imagePath,
        'category': category,
      };
}
