import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/services/category_service.dart';

class CategoryManagerSheet extends StatefulWidget {
  const CategoryManagerSheet({super.key, this.userId});

  final String? userId;

  static Future<void> show(
    BuildContext context, {
    String? userId,
  }) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CategoryManagerSheet(userId: userId),
    );
  }

  @override
  State<CategoryManagerSheet> createState() => _CategoryManagerSheetState();
}

class _CategoryManagerSheetState extends State<CategoryManagerSheet> {
  final _service = CategoryService();
  final _auth = FirebaseAuth.instance;
  bool _changed = false;
  bool _isLoading = true;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await _service.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = data;
      _isLoading = false;
    });
  }

  Future<void> _addCategory() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Kategori'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nama kategori'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      await _service.addCategory(result.trim());
      _changed = true;
      await _load();
    }
  }

  Future<void> _rename(String name) async {
    final controller = TextEditingController(text: name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ganti Nama Kategori'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nama baru'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (newName != null &&
        newName.trim().isNotEmpty &&
        newName.trim() != name) {
      final userId = widget.userId ?? _auth.currentUser?.uid;
      await _service.renameCategory(
        oldName: name,
        newName: newName.trim(),
        userId: userId,
      );
      _changed = true;
      await _load();
    }
  }

  Future<void> _delete(String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori?'),
        content: Text(
          'Menu yang memakai "$name" akan dipindah ke tanpa kategori.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final userId = widget.userId ?? _auth.currentUser?.uid;
      await _service.deleteCategory(name: name, userId: userId);
      _changed = true;
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: bottom > 0 ? bottom : 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kelola Kategori Menu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context, _changed),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tambah, ubah nama, atau hapus kategori.',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 12),
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  )
                : _categories.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Belum ada kategori'),
                      )
                    : ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 320),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _categories.length,
                          separatorBuilder: (_, __) =>
                              Divider(color: cs.outlineVariant),
                          itemBuilder: (context, index) {
                            final item = _categories[index];
                            return ListTile(
                              title: Text(item),
                              trailing: Wrap(
                                spacing: 4,
                                children: [
                                  IconButton(
                                    tooltip: 'Ganti nama',
                                    icon: const Icon(Icons.drive_file_rename_outline),
                                    onPressed: () => _rename(item),
                                  ),
                                  IconButton(
                                    tooltip: 'Hapus',
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _delete(item),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addCategory,
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah kategori'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, _changed),
              icon: const Icon(Icons.check),
              label: const Text('Selesai'),
            ),
          ],
        ),
      ),
    );
  }
}
