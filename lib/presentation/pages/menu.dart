// lib/presentation/pages/menu.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/database/db_helper.dart';
import '../../data/models/menu_model.dart';
import '../../core/services/menu_service.dart';
import '../widgets/category_manager_sheet.dart';
import 'tambah_menu.dart';

class MenuListPage extends StatefulWidget {
  const MenuListPage({super.key});

  @override
  State<MenuListPage> createState() => _MenuListPageState();
}

class _MenuListPageState extends State<MenuListPage> {
  List<MenuModel> _menus = [];

  @override
  void initState() {
    super.initState();
    _loadMenus();
  }

  Future<void> _loadMenus() async {
    final user = FirebaseAuth.instance.currentUser;
    try {
      final data = user != null
          ? await MenuService().syncMenus(userId: user.uid)
          : await DBHelper().getMenus();
      if (!mounted) return;
      setState(() => _menus = data);
    } catch (e) {
      if (!mounted) return;
      final data = await DBHelper().getMenus();
      setState(() => _menus = data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat menu: $e')),
      );
    }
  }

  Future<void> _goToAddMenu() async {
    // Simpan handle berbasis context SEBELUM async gap
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final result = await nav.push<bool>(
      MaterialPageRoute(builder: (_) => const AddMenuPage()),
    );

    if (!mounted) return;

    if (result == true) {
      await _loadMenus();
      messenger.showSnackBar(
        const SnackBar(content: Text('Menu ditambahkan')),
      );
    }
  }

  Future<void> _openCategoryManager() async {
    final user = FirebaseAuth.instance.currentUser;
    await CategoryManagerSheet.show(context, userId: user?.uid);
    if (!mounted) return;
    await _loadMenus();
  }

  void _confirmDelete(MenuModel menu) {
    final parentCtx = context;

    showDialog(
      context: parentCtx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hapus Menu'),
        content: const Text('Yakin ingin menghapus menu ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(parentCtx);
              final nav = Navigator.of(dialogCtx);

              // Tutup dialog sebelum async gap
              nav.pop();

              try {
                if (menu.cloudId != null) {
                  await MenuService().deleteMenu(menu.cloudId!);
                }
                await DBHelper().deleteMenu(menu.id!);

                if (!mounted) return;
                await _loadMenus();

                messenger.showSnackBar(
                  const SnackBar(content: Text('Menu dihapus')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Gagal menghapus: $e')),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _editMenu(MenuModel menu) {
    // Tidak ada await, jadi aman menggunakan context langsung
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddMenuPage(menu: menu)),
    ).then((value) {
      if (value == true) _loadMenus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Menu"),
        actions: [
          IconButton(
            tooltip: 'Kelola kategori',
            onPressed: _openCategoryManager,
            icon: const Icon(Icons.category),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _goToAddMenu,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Menu'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                minimumSize: const Size(0, 36),
              ),
            ),
          ),
        ],
      ),
      body: _menus.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Belum ada menu"),
                  SizedBox(height: 8),
                ],
              ),
            )
          : ListView(
              children: _buildGroupedMenus(),
            ),
      // FAB dipindahkan ke AppBar actions sebagai CTA 'Tambah'
    );
  }

  List<Widget> _buildGroupedMenus() {
    final Map<String, List<MenuModel>> grouped = {};
    for (final menu in _menus) {
      final key = (menu.category ?? '').trim().isNotEmpty
          ? menu.category!.trim()
          : 'Tanpa kategori';
      grouped.putIfAbsent(key, () => []).add(menu);
    }

    final categories = grouped.keys.toList()..sort();
    return [
      for (int i = 0; i < categories.length; i++) ...[
        Padding(
          padding: EdgeInsets.fromLTRB(16, i == 0 ? 8 : 20, 16, 8),
          child: Text(
            categories[i],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        ...grouped[categories[i]]!
            .map(
              (menu) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  onTap: () => _editMenu(menu),
                  leading: menu.imagePath != null && menu.imagePath!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(menu.imagePath!),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.fastfood),
                          ),
                        )
                      : const Icon(Icons.fastfood),
                  title: Text(menu.name),
                  subtitle: Text("Rp${menu.price}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(menu),
                  ),
                ),
              ),
            )
            .toList(),
      ]
    ];
  }
}
