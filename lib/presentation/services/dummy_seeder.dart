import '../../core/database/db_helper.dart';
import '../../data/models/menu_model.dart';
import '../../data/models/cart_item.dart';

class DummySeeder {
  final DBHelper db;

  DummySeeder(this.db);

  static const List<Map<String, dynamic>> baseMenuData = [
    // Coffee
    {'name': 'Espresso', 'price': 15000, 'category': 'Kopi'},
    {'name': 'Americano', 'price': 18000, 'category': 'Kopi'},
    {'name': 'Cappuccino', 'price': 23000, 'category': 'Kopi'},
    {'name': 'Caffe Latte', 'price': 25000, 'category': 'Kopi'},
    {'name': 'Caramel Latte', 'price': 28000, 'category': 'Kopi'},
    {'name': 'Mocha', 'price': 28000, 'category': 'Kopi'},
    {'name': 'Vanilla Latte', 'price': 27000, 'category': 'Kopi'},
    // Non-Coffee
    {'name': 'Chocolate', 'price': 22000, 'category': 'Non Kopi'},
    {'name': 'Matcha Latte', 'price': 26000, 'category': 'Non Kopi'},
    {'name': 'Taro Latte', 'price': 24000, 'category': 'Non Kopi'},
    {'name': 'Red Velvet', 'price': 25000, 'category': 'Non Kopi'},
    {'name': 'Lemon Tea', 'price': 15000, 'category': 'Non Kopi'},
    {'name': 'Lychee Tea', 'price': 18000, 'category': 'Non Kopi'},
    // Pastry & Food
    {'name': 'Croissant Butter', 'price': 17000, 'category': 'Makanan Ringan'},
    {'name': 'Chocolate Croissant', 'price': 20000, 'category': 'Makanan Ringan'},
    {'name': 'Classic Donut', 'price': 8000, 'category': 'Makanan Ringan'},
    {'name': 'Tuna Sandwich', 'price': 22000, 'category': 'Makanan Ringan'},
    {'name': 'Chicken Sandwich', 'price': 23000, 'category': 'Makanan Ringan'},
    {'name': 'French Fries', 'price': 15000, 'category': 'Makanan Ringan'},
    {'name': 'Mini Churros', 'price': 18000, 'category': 'Makanan Ringan'},
  ];

  static List<String> get baseMenuNames =>
      baseMenuData.map((e) => e['name'] as String).toList();

  Future<void> seed({int days = 7}) async {
    final database = await db.database;

    final menusReady = <MenuModel>[];
    await db.upsertCategories(
      baseMenuData
          .map((e) => e['category'] as String? ?? '')
          .where((c) => c.isNotEmpty),
    );
    await database.transaction((txn) async {
      final baseMenus = baseMenuData
          .map(
            (e) => MenuModel(
              name: e['name'] as String,
              price: (e['price'] as num).toInt(),
              imagePath: '',
              category: e['category'] as String?,
            ),
          )
          .toList();

      final existingRows = await txn.query(
        'menus',
        columns: ['id', 'name', 'price', 'category'],
      );

      final existingByName = {
        for (final r in existingRows) (r['name'] as String).trim(): r,
      };

      for (final m in baseMenus) {
        final key = m.name.trim();
        if (existingByName.containsKey(key)) {
          final row = existingByName[key]!;
          menusReady.add(
            MenuModel(
              id: row['id'] as int?,
              name: row['name'] as String,
              price: (row['price'] as num).toInt(),
              imagePath: '',
              category: (row['category'] as String? ?? m.category)?.trim(),
            ),
          );
          final currentCat = (row['category'] as String? ?? '').trim();
          if (currentCat.isEmpty && m.category != null) {
            await txn.update(
              'menus',
              {'category': m.category},
              where: 'id = ?',
              whereArgs: [row['id']],
            );
          }
        } else {
          final id = await txn.insert('menus', {
            'name': m.name,
            'price': m.price,
            'category': m.category,
          });
          menusReady.add(
            MenuModel(
              id: id,
              name: m.name,
              price: m.price,
              imagePath: '',
              category: m.category,
            ),
          );
        }
      }
    });

    final now = DateTime.now();
    for (int i = 0; i < days; i++) {
      final tanggal = now.subtract(Duration(days: i));
      final customer = 'Dummy $i';

      final items = <CartItem>[
        CartItem(
          menu: menusReady[i % menusReady.length],
          quantity: 1 + (i % 2),
        ),
        CartItem(menu: menusReady[(i + 3) % menusReady.length], quantity: 2),
      ];

      await db.insertOrderWithCustomer(
        customerName: customer,
        tableNumber: '${i + 1}',
        items: items,
        createdAt: tanggal,
      );
    }
  }
}
