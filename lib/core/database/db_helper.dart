import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../data/models/menu_model.dart';
import '../../data/models/cart_item.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'kasir.db');
    return openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE menus (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            price INTEGER,
            imagePath TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            menu_id INTEGER,
            quantity INTEGER,
            customer_name TEXT,
            table_no TEXT,
            status TEXT DEFAULT 'pending',
            created_at TEXT,
            FOREIGN KEY (menu_id) REFERENCES menus(id)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 5) {
          await db.execute("ALTER TABLE menus ADD COLUMN imagePath TEXT");
        }
      },
    );
  }

  // ================= MENU =================
  Future<int> insertMenu(MenuModel menu) async {
    final db = await database;
    return await db.insert('menus', menu.toMap());
  }

  Future<List<MenuModel>> getMenus() async {
    final db = await database;
    final maps = await db.query('menus');
    return maps.map((e) => MenuModel.fromMap(e)).toList();
  }

  Future<int> updateMenu(MenuModel menu) async {
    final db = await database;
    return await db.update(
      'menus',
      menu.toMap(),
      where: 'id = ?',
      whereArgs: [menu.id],
    );
  }

  Future<int> deleteMenu(int id) async {
    final db = await database;
    return await db.delete('menus', where: 'id = ?', whereArgs: [id]);
  }

  // ================= ORDER =================
  Future<void> insertOrderWithCustomer({
    required String customerName,
    required String tableNumber,
    required List<CartItem> items,
  }) async {
    final db = await database;
    final createdAt = DateTime.now().toIso8601String();

    for (final item in items) {
      await db.insert('orders', {
        'menu_id': item.menu.id,
        'quantity': item.quantity,
        'customer_name': customerName,
        'table_no': tableNumber,
        'status': 'pending',
        'created_at': createdAt,
      });
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>>
      getOrdersGroupedByCustomer() async {
    final db = await database;

    final raw = await db.rawQuery('''
      SELECT o.id, m.name as menu_name, o.quantity, m.price,
             o.customer_name, o.table_no, o.status, o.created_at,
             (o.quantity * m.price) as total
      FROM orders o
      JOIN menus m ON o.menu_id = m.id
      ORDER BY o.created_at DESC
    ''');

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var row in raw) {
      final key = "${row['customer_name']} (Meja ${row['table_no']})";
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(row);
    }
    return grouped;
  }

  Future<void> markOrderAsDone(int orderId) async {
    final db = await database;
    await db.update(
      'orders',
      {'status': 'done'},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<int> deleteOrder(int id) async {
    final db = await database;
    return await db.delete('orders', where: 'id = ?', whereArgs: [id]);
  }

  // ================= REPORT =================
  Future<List<Map<String, dynamic>>> getDailyReport() async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT 
        DATE(created_at) as tanggal,
        COUNT(DISTINCT customer_name || table_no || DATE(created_at)) as total_pesanan,
        SUM(quantity) as total_item,
        SUM(quantity * m.price) as total_omzet
      FROM orders o
      JOIN menus m ON o.menu_id = m.id
      GROUP BY DATE(created_at)
      ORDER BY DATE(created_at) DESC
    ''');

    return result;
  }

  Future<Map<String, dynamic>> getMonthlySummary(
      {required int year, required int month}) async {
    final db = await database;
    final monthStr = month.toString().padLeft(2, '0');
    final datePrefix = "$year-$monthStr";

    final result = await db.rawQuery('''
      SELECT 
        COUNT(DISTINCT customer_name || table_no || DATE(created_at)) as total_transaksi,
        SUM(quantity) as total_item,
        SUM(quantity * m.price) as total_omzet,
        COUNT(DISTINCT DATE(created_at)) as hari_aktif
      FROM orders o
      JOIN menus m ON o.menu_id = m.id
      WHERE strftime('%Y-%m', created_at) = ?
    ''', [datePrefix]);

    return result.first;
  }

  Future<List<Map<String, dynamic>>> getTopMenus(
      {required int year, required int month, int limit = 3}) async {
    final db = await database;
    final monthStr = month.toString().padLeft(2, '0');
    final datePrefix = "$year-$monthStr";

    final result = await db.rawQuery('''
      SELECT m.name, SUM(o.quantity) as total_terjual
      FROM orders o
      JOIN menus m ON o.menu_id = m.id
      WHERE strftime('%Y-%m', o.created_at) = ?
      GROUP BY o.menu_id
      ORDER BY total_terjual DESC
      LIMIT ?
    ''', [datePrefix, limit]);

    return result;
  }

  // ================= CLOSE =================
  Future close() async {
    final db = await database;
    db.close();
  }
}
