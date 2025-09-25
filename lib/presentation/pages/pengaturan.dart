import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/db_helper.dart';
import '../../providers/theme_provider.dart';
import '../../providers/font_provider.dart';
import '../services/dummy_seeder.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _kontakController = TextEditingController();
  final TextEditingController _diskonController = TextEditingController();
  final TextEditingController _ppnController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  String? _logoPath;
  String? _qrisPath;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _namaController.text = prefs.getString('nama_usaha') ?? '';
      _alamatController.text = prefs.getString('alamat_usaha') ?? '';
      _kontakController.text = prefs.getString('kontak_usaha') ?? '';
      _logoPath = prefs.getString('logo_path');
      _qrisPath = prefs.getString('qris_path');
      _diskonController.text =
          (prefs.getDouble('diskon_persen') ?? 0.0).toStringAsFixed(0);
      _ppnController.text =
          (prefs.getDouble('ppn_persen') ?? 10.0).toStringAsFixed(0);
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nama_usaha', _namaController.text);
    await prefs.setString('alamat_usaha', _alamatController.text);
    await prefs.setString('kontak_usaha', _kontakController.text);
    if (_logoPath != null) await prefs.setString('logo_path', _logoPath!);
    if (_qrisPath != null) await prefs.setString('qris_path', _qrisPath!);
    final diskon = double.tryParse(_diskonController.text) ?? 0.0;
    final ppn = double.tryParse(_ppnController.text) ?? 10.0;
    await prefs.setDouble('diskon_persen', diskon);
    await prefs.setDouble('ppn_persen', ppn);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengaturan disimpan')),
    );
    setState(() {});
  }

  Future<void> _pickLogo() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    _logoPath = picked.path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('logo_path', _logoPath!);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logo disimpan')),
    );
  }

  /// Pilih QRIS lalu simpan otomatis ke SharedPreferences.
  Future<void> _pickQRIS() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    _qrisPath = picked.path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('qris_path', _qrisPath!);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QRIS disimpan')),
    );
  }

  /// Hapus path QRIS dari state dan SharedPreferences.
  Future<void> _deleteQRIS() async {
    _qrisPath = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('qris_path');
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QRIS dihapus')),
    );
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profil Usaha'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _namaController,
                  decoration: const InputDecoration(labelText: 'Nama Usaha'),
                ),
                TextField(
                  controller: _alamatController,
                  decoration: const InputDecoration(labelText: 'Alamat'),
                ),
                TextField(
                  controller: _kontakController,
                  decoration: const InputDecoration(labelText: 'Kontak'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _pickLogo,
                  icon: const Icon(Icons.image),
                  label: const Text('Pilih Logo'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('Simpan'),
              onPressed: () {
                _saveSettings();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _insertDummyData() async {
    final db = DBHelper();
    final seeder = DummySeeder(db);
    try {
      await seeder.seed(days: 7);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('7 Hari laporan dummy berhasil ditambahkan')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan dummy: $e')),
      );
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    _kontakController.dispose();
    _diskonController.dispose();
    _ppnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final container = Theme.of(context).colorScheme.primaryContainer;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Profil Usaha",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
            color: container,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (_logoPath != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_logoPath!),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.store, size: 30),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _namaController.text.isEmpty
                                  ? "Nama Usaha"
                                  : _namaController.text,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(_alamatController.text.isEmpty
                                ? "Alamat belum diisi"
                                : _alamatController.text),
                            Text(_kontakController.text.isEmpty
                                ? "Kontak belum diisi"
                                : _kontakController.text),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit Profil',
                    onPressed: _showEditDialog,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text("Pembayaran",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text("Gambar QRIS",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (_qrisPath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_qrisPath!),
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    )
                  else
                    const Text("Belum ada gambar QRIS"),
                  const SizedBox(height: 10),

                  // Tombol dinamis: Upload -> Hapus
                  if (_qrisPath == null)
                    ElevatedButton.icon(
                      onPressed: _pickQRIS,
                      icon: const Icon(Icons.qr_code),
                      label: const Text("Upload Gambar QRIS"),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _deleteQRIS,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                      icon: const Icon(Icons.delete),
                      label: const Text("Hapus Gambar QRIS"),
                    ),

                  const SizedBox(height: 16),
                  TextField(
                    controller: _diskonController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Diskon (%)',
                      prefixIcon: Icon(Icons.discount),
                    ),
                    onChanged: (value) => _saveSettings(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ppnController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'PPN (%)',
                      prefixIcon: Icon(Icons.receipt_long),
                    ),
                    onChanged: (value) => _saveSettings(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text("Tampilan",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
            color: surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return SwitchListTile(
                      title: const Text("Tema Gelap"),
                      value: themeProvider.isDark,
                      onChanged: themeProvider.toggleTheme,
                      secondary: const Icon(Icons.dark_mode),
                    );
                  },
                ),
                Consumer<FontProvider>(
                  builder: (context, fontProvider, _) {
                    return SwitchListTile(
                      title: const Text("Ukuran Font Besar"),
                      value: fontProvider.isLargeFont,
                      onChanged: fontProvider.toggleFont,
                      secondary: const Icon(Icons.text_fields),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text("Mode Demo",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
            color: surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text("Demo"),
              subtitle: const Text("Masukkan data simulasi/dummy."),
              onTap: () async => await _insertDummyData(),
            ),
          ),
          const SizedBox(height: 24),
          const Text("Tentang Aplikasi",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
            color: surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text("KasirQ v1.0.0"),
                  subtitle: Text(
                      "Aplikasi kasir untuk memenuhi tugas kuliah dan praktik."),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text("Developer"),
                  subtitle: Text("Dikembangkan oleh Evan F P"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
