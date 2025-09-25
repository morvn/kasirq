import '../../core/database/db_helper.dart';
import '../../data/models/menu_model.dart';
import '../../data/models/cart_item.dart';

class DummySeeder {
  final DBHelper db;

  DummySeeder(this.db);

  Future<void> seed({int days = 7}) async {
    final database = await db.database;

    // ── Fase 1: pastikan menu tersedia (transaksional, cepat, tanpa panggil helper lain)
    final menusReady = <MenuModel>[];
    await database.transaction((txn) async {
      final baseMenus = <MenuModel>[
        MenuModel(name: 'Mie Ayam', price: 10000, imagePath: ''),
        MenuModel(name: 'Mie Ayam Pangsit', price: 12000, imagePath: ''),
        MenuModel(name: 'Mie Ayam Bakso', price: 15000, imagePath: ''),
        MenuModel(name: 'Mie Ayam Ceker', price: 15000, imagePath: ''),
        MenuModel(name: 'Bakso', price: 11000, imagePath: ''),
        MenuModel(name: 'Bakso Ceker', price: 15000, imagePath: ''),
        MenuModel(name: 'Bakso Goreng', price: 13000, imagePath: ''),
        MenuModel(name: 'Es Teh', price: 5000, imagePath: ''),
        MenuModel(name: 'Es Jeruk', price: 5000, imagePath: ''),
        MenuModel(name: 'Kerupuk', price: 1000, imagePath: ''),
      ];

      final existingRows = await txn.query(
        'menus',
        columns: ['id', 'name', 'price'],
      );
      final existingByName = {
        for (final r in existingRows) (r['name'] as String).trim(): r
      };

      for (final m in baseMenus) {
        final key = m.name.trim();
        if (existingByName.containsKey(key)) {
          final row = existingByName[key]!;
          menusReady.add(MenuModel(
            id: row['id'] as int?,
            name: row['name'] as String,
            price: (row['price'] as num).toInt(),
            imagePath: '',
          ));
        } else {
          final id = await txn.insert('menus', {
            'name': m.name,
            'price': m.price,
          });
          menusReady.add(MenuModel(
            id: id,
            name: m.name,
            price: m.price,
            imagePath: '',
          ));
        }
      }
    }); // transaksi selesai → kunci rilis

    // ── Fase 2: insert orders (di luar transaksi agar tidak konflik dengan helper)
    final now = DateTime.now();
    for (int i = 0; i < days; i++) {
      final tanggal = now.subtract(Duration(days: i));
      final createdAtIso = tanggal.toIso8601String();
      final customer = 'Dummy $i';

      final items = <CartItem>[
        CartItem(
            menu: menusReady[i % menusReady.length], quantity: 1 + (i % 2)),
        CartItem(menu: menusReady[(i + 2) % menusReady.length], quantity: 2),
      ];

      // gunakan helper (boleh buka transaksi internalnya sendiri)
      await db.insertOrderWithCustomer(
        customerName: customer,
        tableNumber: '${i + 1}',
        items: items,
      );

      // backdate created_at bila kolom ada
      try {
        await database.rawUpdate(
          'UPDATE orders SET created_at = ? WHERE customer_name = ?',
          [createdAtIso, customer],
        );
      } catch (_) {
        // abaikan jika schema belum punya kolom created_at
      }
    }
  }
}
