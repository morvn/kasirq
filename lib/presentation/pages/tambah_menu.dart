import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/database/db_helper.dart';
import '../../data/models/menu_model.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.menu != null) {
      _nameController.text = widget.menu!.name;
      _priceController.text = widget.menu!.price.toString();
      _imagePath = widget.menu!.imagePath;
    }
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
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final price = int.tryParse(_priceController.text.trim()) ?? 0;

    final menu = MenuModel(
      id: widget.menu?.id,
      name: name,
      price: price,
      imagePath: _imagePath,
    );

    final db = DBHelper();
    if (widget.menu == null) {
      await db.insertMenu(menu);
    } else {
      await db.updateMenu(menu);
    }

    if (mounted) Navigator.pop(context, true);
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
                onPressed: _saveMenu,
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
