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
      version: 8,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE
          )
        ''');

        await db.execute('''
          CREATE TABLE menus (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            price INTEGER,
            imagePath TEXT,
            cloudId TEXT,
            category TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            menu_id INTEGER,
            quantity INTEGER,
            userId TEXT,
            customer_name TEXT,
            table_no TEXT,
            status TEXT DEFAULT 'pending',
            created_at TEXT,
            cloudId TEXT,
            FOREIGN KEY (menu_id) REFERENCES menus(id)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 5) {
          await db.execute("ALTER TABLE menus ADD COLUMN imagePath TEXT");
        }
        if (oldVersion < 6) {
          await db.execute("ALTER TABLE menus ADD COLUMN cloudId TEXT");
        }
        if (oldVersion < 7) {
          await db.execute("ALTER TABLE orders ADD COLUMN userId TEXT");
          await db.execute("ALTER TABLE orders ADD COLUMN cloudId TEXT");
        }
        if (oldVersion < 8) {
          await db.execute("ALTER TABLE menus ADD COLUMN category TEXT");
          await db.execute('''
            CREATE TABLE IF NOT EXISTS categories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT UNIQUE
            )
          ''');
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

  // ================= CATEGORY =================
  Future<int> insertCategory(String name) async {
    final db = await database;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 0;
    return await db.insert(
      'categories',
      {'name': trimmed},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> upsertCategories(Iterable<String> categories) async {
    final db = await database;
    final batch = db.batch();
    for (final name in categories) {
      final trimmed = name.trim();
      if (trimmed.isEmpty) continue;
      batch.insert(
        'categories',
        {'name': trimmed},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<String>> getCategories() async {
    final db = await database;
    final rows = await db.query(
      'categories',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map((e) => e['name']).whereType<String>().toList();
  }

  Future<List<MenuModel>> getMenusByCategory(String category) async {
    final db = await database;
    final rows = await db.query(
      'menus',
      where: 'category = ?',
      whereArgs: [category],
    );
    return rows.map(MenuModel.fromMap).toList();
  }

  Future<void> renameCategory({
    required String oldName,
    required String newName,
  }) async {
    final db = await database;
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    await db.transaction((txn) async {
      await txn.insert(
        'categories',
        {'name': trimmed},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      await txn.update(
        'menus',
        {'category': trimmed},
        where: 'category = ?',
        whereArgs: [oldName],
      );
      await txn.delete(
        'categories',
        where: 'name = ?',
        whereArgs: [oldName],
      );
    });
  }

  Future<void> deleteCategory(String name) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'menus',
        {'category': null},
        where: 'category = ?',
        whereArgs: [name],
      );
      await txn.delete(
        'categories',
        where: 'name = ?',
        whereArgs: [name],
      );
    });
  }

  // ================= ORDER =================
  Future<List<int>> insertOrderWithCustomer({
    required String customerName,
    required String tableNumber,
    required List<CartItem> items,
    String? userId,
    DateTime? createdAt,
  }) async {
    final db = await database;
    final createdAtIso = (createdAt ?? DateTime.now()).toIso8601String();
    final insertedIds = <int>[];

    for (final item in items) {
      final id = await db.insert('orders', {
        'menu_id': item.menu.id,
        'quantity': item.quantity,
        'userId': userId,
        'customer_name': customerName,
        'table_no': tableNumber,
        'status': 'pending',
        'created_at': createdAtIso,
      });
      insertedIds.add(id);
    }
    return insertedIds;
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

  Future<List<Map<String, dynamic>>> getUnsyncedOrdersWithMenu(
      {required String userId}) async {
    final db = await database;
    return db.rawQuery('''
      SELECT o.id, o.menu_id, o.quantity, o.userId, o.customer_name, o.table_no,
             o.status, o.created_at, o.cloudId,
             m.name as menu_name, m.price as menu_price, m.cloudId as menu_cloudId
      FROM orders o
      LEFT JOIN menus m ON o.menu_id = m.id
      WHERE o.cloudId IS NULL AND (o.userId IS NULL OR o.userId = ?)
    ''', [userId]);
  }

  Future<void> markOrderSynced(int orderId, String cloudId) async {
    final db = await database;
    await db.update(
      'orders',
      {'cloudId': cloudId},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<bool> hasDummyOrders() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) AS total FROM orders WHERE customer_name LIKE 'Dummy %'",
    );
    final rawTotal = result.isNotEmpty ? result.first['total'] : 0;
    final total =
        rawTotal is int ? rawTotal : rawTotal is num ? rawTotal.toInt() : 0;
    return total > 0;
  }

  Future<int> deleteDummyOrders() async {
    final db = await database;
    return await db.delete(
      'orders',
      where: "customer_name LIKE ?",
      whereArgs: ['Dummy %'],
    );
  }

  Future<int> deleteMenusByNames(List<String> names) async {
    if (names.isEmpty) return 0;
    final db = await database;
    final placeholders = List.filled(names.length, '?').join(',');

    // Ambil id menu untuk delete relasi orders
    final rows = await db.query(
      'menus',
      columns: ['id'],
      where: 'name IN ($placeholders)',
      whereArgs: names,
    );
    final ids = rows
        .map((e) => e['id'])
        .whereType<int>()
        .toList();

    if (ids.isNotEmpty) {
      final idPlaceholders = List.filled(ids.length, '?').join(',');
      await db.delete(
        'orders',
        where: 'menu_id IN ($idPlaceholders)',
        whereArgs: ids,
      );
    }

    final deleted = await db.delete(
      'menus',
      where: 'name IN ($placeholders)',
      whereArgs: names,
    );
    await pruneEmptyCategories();
    return deleted;
  }

  Future<int> pruneEmptyCategories() async {
    final db = await database;
    return await db.rawDelete('''
      DELETE FROM categories
      WHERE name NOT IN (
        SELECT DISTINCT category FROM menus
        WHERE category IS NOT NULL AND TRIM(category) != ''
      )
    ''');
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
