import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/database/db_helper.dart';
import '../../core/services/category_service.dart';
import '../../data/models/menu_model.dart';
import '../../core/services/menu_service.dart';
import '../widgets/category_manager_sheet.dart';

class AddMenuPage extends StatefulWidget {
  final MenuModel? menu;

  const AddMenuPage({super.key, this.menu});

  @override
  State<AddMenuPage> createState() => _AddMenuPageState();
}

class _AddMenuPageState extends State<AddMenuPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String? _imagePath;
  String? _selectedCategory;
  List<String> _categories = [];
  bool _isCategoryLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.menu != null) {
      _nameController.text = widget.menu!.name;
      _priceController.text = widget.menu!.price.toString();
      _imagePath = widget.menu!.imagePath;
      _selectedCategory = widget.menu!.category;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isCategoryLoading = true);
    final data = await CategoryService().getCategories();
    if (!mounted) return;
    setState(() {
      _categories = data;
      _isCategoryLoading = false;
      _selectedCategory ??= widget.menu?.category;
      if (_selectedCategory != null &&
          _selectedCategory!.isNotEmpty &&
          !_categories.contains(_selectedCategory)) {
        _selectedCategory = null;
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imagePath = picked.path;
      });
    }
  }

  Future<void> _saveMenu() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final price = int.tryParse(_priceController.text.trim()) ?? 0;
    final user = FirebaseAuth.instance.currentUser;
    final category =
        (_selectedCategory ?? '').trim().isEmpty ? null : _selectedCategory;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harus login untuk menyimpan menu')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final menuService = MenuService();
      String? cloudId = widget.menu?.cloudId;

      if (cloudId == null) {
        cloudId = await menuService.createMenu(
          userId: user.uid,
          name: name,
          price: price,
          category: category,
        );
      } else {
        await menuService.updateMenu(
          cloudId: cloudId,
          name: name,
          price: price,
          category: category,
        );
      }

      final menu = MenuModel(
        id: widget.menu?.id,
        cloudId: cloudId,
        name: name,
        price: price,
        imagePath: _imagePath,
        category: category,
      );

      final db = DBHelper();
      if (widget.menu == null) {
        await db.insertMenu(menu);
      } else {
        await db.updateMenu(menu);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan menu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.menu != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Menu' : 'Tambah Menu')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Menu'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Harga'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || int.tryParse(value) == null
                        ? 'Masukkan angka valid'
                        : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey('${_selectedCategory ?? ''}-${_categories.length}'),
                initialValue: (_selectedCategory ?? '').isEmpty
                    ? ''
                    : _selectedCategory,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  helperText: 'Kelompokkan menu agar mudah ditemukan',
                ),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Tanpa kategori'),
                  ),
                  ..._categories.map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c),
                    ),
                  ),
                ],
                onChanged: _isCategoryLoading
                    ? null
                    : (value) => setState(() {
                          _selectedCategory =
                              (value ?? '').isEmpty ? null : value;
                        }),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () async {
                            final controller = TextEditingController();
                            final name = await showDialog<String>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Tambah Kategori'),
                                content: TextField(
                                  controller: controller,
                                  decoration: const InputDecoration(
                                    labelText: 'Nama kategori',
                                  ),
                                  autofocus: true,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(null),
                                    child: const Text('Batal'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(ctx)
                                          .pop(controller.text.trim());
                                    },
                                    child: const Text('Simpan'),
                                  ),
                                ],
                              ),
                            );
                            if (name != null && name.trim().isNotEmpty) {
                              await CategoryService().addCategory(name.trim());
                              await _loadCategories();
                              setState(() => _selectedCategory = name.trim());
                            }
                          },
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah kategori'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () async {
                            final user = FirebaseAuth.instance.currentUser;
                            await CategoryManagerSheet.show(
                              context,
                              userId: user?.uid,
                            );
                            await _loadCategories();
                          },
                    icon: const Icon(Icons.edit),
                    label: const Text('Kelola kategori'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_imagePath!),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 80),
                          ),
                        )
                      : const Icon(Icons.image, size: 80),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text("Pilih Gambar"),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveMenu,
                icon: const Icon(Icons.save),
                label: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Menu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
