import 'package:cloud_firestore/cloud_firestore.dart';

import '../database/db_helper.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'orders';

  Future<String> _createOrderDoc(Map<String, dynamic> data) async {
    final docRef = await _firestore.collection(_collectionName).add(data);
    return docRef.id;
  }

  Future<int> pullOrdersFromCloud({required String userId}) async {
    final db = DBHelper();
    final database = await db.database;

    final snapshot = await _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .get();

    int imported = 0;

    for (final doc in snapshot.docs) {
      final alreadyHave = await database.query(
        'orders',
        columns: ['id'],
        where: 'cloudId = ?',
        whereArgs: [doc.id],
        limit: 1,
      );
      if (alreadyHave.isNotEmpty) continue;

      final data = doc.data();
      final menuName = (data['menuName'] as String?) ?? '-';
      final menuPriceRaw = data['menuPrice'];
      final menuPrice = menuPriceRaw is num
          ? menuPriceRaw.toInt()
          : int.tryParse('$menuPriceRaw') ?? 0;
      final menuCloudId = data['menuCloudId'] as String?;
      final menuId = await _ensureMenu(
        database,
        cloudId: menuCloudId,
        name: menuName,
        price: menuPrice,
      );

      final qtyRaw = data['quantity'];
      final quantity =
          qtyRaw is num ? qtyRaw.toInt() : int.tryParse('$qtyRaw') ?? 0;
      final status = (data['status'] as String?) ?? 'pending';
      final createdAtRaw = data['createdAt'];
      final createdAt = createdAtRaw is Timestamp
          ? createdAtRaw.toDate()
          : DateTime.tryParse('$createdAtRaw') ?? DateTime.now();
      final customerName = (data['customerName'] as String?) ?? '-';
      final tableNumber = (data['tableNumber'] as String?) ?? '-';

      await database.insert('orders', {
        'menu_id': menuId,
        'quantity': quantity,
        'userId': userId,
        'customer_name': customerName,
        'table_no': tableNumber,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'cloudId': doc.id,
      });
      imported++;
    }

    return imported;
  }

  Future<void> syncUnsyncedOrders({required String userId}) async {
    final db = DBHelper();
    final unsynced = await db.getUnsyncedOrdersWithMenu(userId: userId);

    for (final row in unsynced) {
      final createdAtRaw = row['created_at'] as String?;
      final createdAt = DateTime.tryParse(createdAtRaw ?? '') ?? DateTime.now();
      final priceRaw = row['menu_price'];
      final price =
          priceRaw is num ? priceRaw.toInt() : int.tryParse('$priceRaw') ?? 0;
      final qtyRaw = row['quantity'];
      final quantity =
          qtyRaw is num ? qtyRaw.toInt() : int.tryParse('$qtyRaw') ?? 0;
      final menuName = (row['menu_name'] as String?) ?? '';
      final orderData = {
        'userId': userId,
        'menuCloudId': row['menu_cloudId'],
        'menuId': row['menu_id'],
        'menuName': menuName,
        'menuPrice': price,
        'quantity': quantity,
        'customerName': row['customer_name'],
        'tableNumber': row['table_no'],
        'status': row['status'],
        'createdAt': Timestamp.fromDate(createdAt),
        'syncedAt': Timestamp.now(),
      };

      final cloudId = await _createOrderDoc(orderData);
      await db.markOrderSynced(row['id'] as int, cloudId);
    }
  }

  Future<int> deleteDummyOrders({required String userId}) async {
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .get();
    int deleted = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final customer = (data['customerName'] as String?) ?? '';
      if (customer.startsWith('Dummy ')) {
        await doc.reference.delete();
        deleted++;
      }
    }
    return deleted;
  }

  Future<int> _ensureMenu(
    dynamic database, {
    String? cloudId,
    required String name,
    required int price,
  }) async {
    Map<String, Object?>? existing;

    if (cloudId != null) {
      final rows = await database.query(
        'menus',
        where: 'cloudId = ?',
        whereArgs: [cloudId],
        limit: 1,
      );
      if (rows.isNotEmpty) existing = rows.first;
    }

    if (existing == null) {
      final rows = await database.query(
        'menus',
        where: 'name = ?',
        whereArgs: [name],
        limit: 1,
      );
      if (rows.isNotEmpty) existing = rows.first;
    }

    if (existing != null) {
      final id = existing['id'] as int;
      await database.update(
        'menus',
        {
          'price': price,
          'cloudId': cloudId ?? existing['cloudId'],
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return id;
    }

    return await database.insert('menus', {
      'name': name,
      'price': price,
      'cloudId': cloudId,
    });
  }
}
