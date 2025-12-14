import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/models/menu_model.dart';
import '../database/db_helper.dart';

class MenuService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'menus';

  Future<String> createMenu({
    required String userId,
    required String name,
    required int price,
    String? category,
  }) async {
    final now = DateTime.now();
    final docRef = await _firestore.collection(_collectionName).add({
      'userId': userId,
      'name': name,
      'price': price,
      'category': category,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });
    return docRef.id;
  }

  Future<void> updateMenu({
    required String cloudId,
    required String name,
    required int price,
    String? category,
  }) async {
    final now = DateTime.now();
    await _firestore.collection(_collectionName).doc(cloudId).update({
      'name': name,
      'price': price,
      'category': category,
      'updatedAt': now.toIso8601String(),
    });
  }

  Future<void> deleteMenu(String cloudId) async {
    await _firestore.collection(_collectionName).doc(cloudId).delete();
  }

  Future<void> renameCategoryRemote({
    required String userId,
    required String oldName,
    required String newName,
  }) async {
    final now = DateTime.now().toIso8601String();
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: oldName)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.update({'category': newName, 'updatedAt': now});
    }
  }

  Future<void> clearCategoryRemote({
    required String userId,
    required String name,
  }) async {
    final now = DateTime.now().toIso8601String();
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: name)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.update({'category': null, 'updatedAt': now});
    }
  }

  Future<int> deleteMenusByNames({
    required String userId,
    required List<String> names,
  }) async {
    if (names.isEmpty) return 0;
    final nameSet = names.toSet();
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .get();

    int deleted = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final name = data['name'] as String? ?? '';
      if (nameSet.contains(name)) {
        await doc.reference.delete();
        deleted++;
      }
    }
    return deleted;
  }

  Future<List<MenuModel>> fetchMenus(String userId) async {
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final priceRaw = data['price'];
      final price = priceRaw is num ? priceRaw.toInt() : int.tryParse('$priceRaw') ?? 0;

      return MenuModel(
        cloudId: doc.id,
        name: data['name'] ?? '',
        price: price,
        category: data['category'] as String?,
      );
    }).toList();
  }

  Future<List<MenuModel>> syncMenus({
    required String userId,
  }) async {
    final db = DBHelper();
    final localMenus = await db.getMenus();

    // Push local menus that haven't been stored in Firestore yet
    for (final menu in localMenus.where((m) => m.cloudId == null)) {
      final cloudId = await createMenu(
        userId: userId,
        name: menu.name,
        price: menu.price,
        category: menu.category,
      );
      await db.updateMenu(menu.copyWith(cloudId: cloudId));
    }

    // Pull latest menus from Firestore and merge into local DB
    final remoteMenus = await fetchMenus(userId);
    await db.upsertCategories(
      remoteMenus
          .map((e) => (e.category ?? '').trim())
          .where((name) => name.trim().isNotEmpty),
    );
    final updatedLocal = await db.getMenus();

    for (final remote in remoteMenus) {
      final match = _findMatchingLocal(updatedLocal, remote);
      final merged = remote.copyWith(
        id: match?.id,
        imagePath: match?.imagePath,
        category: remote.category ?? match?.category,
      );

      if (remote.category == null &&
          match?.category != null &&
          match?.cloudId != null) {
        await updateMenu(
          cloudId: match!.cloudId!,
          name: merged.name,
          price: merged.price,
          category: match.category,
        );
      }

      if (match == null) {
        await db.insertMenu(merged);
      } else {
        await db.updateMenu(merged);
      }
    }

    return db.getMenus();
  }

  MenuModel? _findMatchingLocal(List<MenuModel> locals, MenuModel remote) {
    for (final local in locals) {
      if (local.cloudId != null && local.cloudId == remote.cloudId) {
        return local;
      }
    }
    for (final local in locals) {
      if (local.cloudId == null && local.name == remote.name) {
        return local;
      }
    }
    return null;
  }
}
