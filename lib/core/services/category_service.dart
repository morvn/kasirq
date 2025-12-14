import '../../data/models/menu_model.dart';
import '../database/db_helper.dart';
import 'menu_service.dart';

class CategoryService {
  final DBHelper _db = DBHelper();
  final MenuService _menuService = MenuService();

  Future<List<String>> getCategories() => _db.getCategories();

  Future<void> addCategory(String name) async {
    await _db.insertCategory(name);
  }

  Future<void> renameCategory({
    required String oldName,
    required String newName,
    String? userId,
  }) async {
    await _db.renameCategory(oldName: oldName, newName: newName);
    if (userId != null && userId.isNotEmpty) {
      await _menuService.renameCategoryRemote(
        userId: userId,
        oldName: oldName,
        newName: newName,
      );
    }
  }

  Future<void> deleteCategory({
    required String name,
    String? userId,
  }) async {
    await _db.deleteCategory(name);
    if (userId != null && userId.isNotEmpty) {
      await _menuService.clearCategoryRemote(userId: userId, name: name);
    }
  }

  Future<void> upsertFromMenus(List<MenuModel> menus) async {
    await _db.upsertCategories(
      menus
          .map((m) => m.category ?? '')
          .where((c) => c.trim().isNotEmpty),
    );
  }
}
