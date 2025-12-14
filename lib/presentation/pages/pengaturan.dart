import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../core/database/db_helper.dart';
import '../../core/services/menu_service.dart';
import '../../core/services/order_service.dart';
import '../../core/services/category_service.dart';
import '../../providers/theme_provider.dart';
import '../../providers/font_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_profile_provider.dart';
import '../services/dummy_seeder.dart';
import '../widgets/category_manager_sheet.dart';

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
  bool _isLoading = false;
  bool _isDemoLoading = false;
  bool _hasDummyData = false;
  bool _isCategoryLoading = false;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
      _refreshDummyFlag();
      _loadCategories();
    });
  }

  Future<void> _loadSettings() async {
    final profileProvider = context.read<BusinessProfileProvider>();

    // Refresh profile from Firestore
    await profileProvider.refreshProfile();

    if (!mounted) return;

    final profile = profileProvider.profile;
    if (profile != null) {
      setState(() {
        _namaController.text = profile.namaUsaha;
        _alamatController.text = profile.alamatUsaha;
        _kontakController.text = profile.kontakUsaha;
        _diskonController.text = profile.diskonPersen.toStringAsFixed(0);
        _ppnController.text = profile.ppnPersen.toStringAsFixed(0);
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final profileProvider = context.read<BusinessProfileProvider>();
      final diskon = double.tryParse(_diskonController.text) ?? 0.0;
      final ppn = double.tryParse(_ppnController.text) ?? 0.0;

      await profileProvider.updateProfile(
        namaUsaha: _namaController.text,
        alamatUsaha: _alamatController.text,
        kontakUsaha: _kontakController.text,
        diskonPersen: diskon,
        ppnPersen: ppn,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pengaturan disimpan')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickLogo() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isLoading = true);

    try {
      final profileProvider = context.read<BusinessProfileProvider>();
      await profileProvider.uploadLogo(File(picked.path));

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Logo disimpan')),
      );
      await _loadSettings(); // Reload to get updated URL
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal mengupload logo: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickQRIS() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isLoading = true);

    try {
      final profileProvider = context.read<BusinessProfileProvider>();
      await profileProvider.uploadQRIS(File(picked.path));

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(const SnackBar(content: Text('QRIS disimpan')));
      await _loadSettings(); // Reload to get updated URL
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal mengupload QRIS: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteQRIS() async {
    setState(() => _isLoading = true);

    try {
      final profileProvider = context.read<BusinessProfileProvider>();
      await profileProvider.deleteQRIS();

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(const SnackBar(content: Text('QRIS dihapus')));
      await _loadSettings(); // Reload to get updated state
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal menghapus QRIS: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profil Usaha'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _pickLogo,
                      icon: const Icon(Icons.image),
                      label: const Text('Pilih Logo'),
                    ),
                    Consumer<BusinessProfileProvider>(
                      builder: (context, profileProvider, _) {
                        final hasLocalLogo =
                            profileProvider.logoPath != null &&
                            profileProvider.logoPath!.isNotEmpty;
                        if (hasLocalLogo) {
                          return ElevatedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    try {
                                      final nav = Navigator.of(context);
                                      final messenger =
                                          ScaffoldMessenger.of(context);
                                      await profileProvider.removeLogo();
                                      if (!mounted) return;
                                      nav.pop();
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Logo dihapus, akan menggunakan foto Google',
                                          ),
                                        ),
                                      );
                                      await _loadSettings();
                                    } catch (e) {
                                      if (!mounted) return;
                                      final messenger =
                                          ScaffoldMessenger.of(context);
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Gagal menghapus logo: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onError,
                            ),
                            icon: const Icon(Icons.delete),
                            label: const Text('Hapus Logo'),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      _saveSettings();
                      Navigator.pop(context);
                    },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _insertDummyData() async {
    if (_isDemoLoading) return;
    setState(() => _isDemoLoading = true);

    final db = DBHelper();
    final seeder = DummySeeder(db);
    try {
      await seeder.seed(days: 7);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('7 Hari laporan dummy berhasil ditambahkan'),
        ),
      );
      await _refreshDummyFlag();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menambahkan dummy: $e')));
    } finally {
      if (mounted) setState(() => _isDemoLoading = false);
    }
  }

  Future<void> _deleteDummyData() async {
    if (_isDemoLoading) return;
    setState(() => _isDemoLoading = true);

    final messenger = ScaffoldMessenger.of(context);
    try {
      final db = DBHelper();
      final user = fb.FirebaseAuth.instance.currentUser;
      final deletedOrders = await db.deleteDummyOrders();
      final deletedMenus =
          await db.deleteMenusByNames(DummySeeder.baseMenuNames);
      await db.pruneEmptyCategories();

      int cloudOrders = 0;
      int cloudMenus = 0;
      if (user != null) {
        cloudOrders = await OrderService().deleteDummyOrders(
          userId: user.uid,
        );
        cloudMenus = await MenuService().deleteMenusByNames(
          userId: user.uid,
          names: DummySeeder.baseMenuNames,
        );
      }
      if (!mounted) return;
      await _refreshDummyFlag();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            (deletedOrders + deletedMenus + cloudOrders + cloudMenus) > 0
                ? 'Data dummy dihapus (lokal ${deletedOrders + deletedMenus}, cloud ${cloudOrders + cloudMenus})'
                : 'Tidak ada data dummy untuk dihapus',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menghapus dummy: $e')),
      );
    } finally {
      if (mounted) setState(() => _isDemoLoading = false);
    }
  }

  Future<void> _refreshDummyFlag() async {
    final hasDummy = await DBHelper().hasDummyOrders();
    if (!mounted) return;
    setState(() => _hasDummyData = hasDummy);
  }

  Future<void> _loadCategories() async {
    setState(() => _isCategoryLoading = true);
    final data = await CategoryService().getCategories();
    if (!mounted) return;
    setState(() {
      _categories = data;
      _isCategoryLoading = false;
    });
  }

  Future<void> _openCategoryManager() async {
    final userId = fb.FirebaseAuth.instance.currentUser?.uid;
    await CategoryManagerSheet.show(context, userId: userId);
    if (!mounted) return;
    await _loadCategories();
  }

  Future<void> _handleDemoAction() async {
    if (_isDemoLoading) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_hasDummyData ? 'Hapus Data Demo?' : 'Tambah Data Demo?'),
        content: Text(
          _hasDummyData
              ? 'Data demo sudah ada. Hapus seluruh data demo?'
              : 'Tambahkan 7 hari data dummy untuk uji coba?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_hasDummyData ? 'Hapus' : 'Tambah'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (_hasDummyData) {
      await _deleteDummyData();
    } else {
      await _insertDummyData();
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
      body: Consumer<BusinessProfileProvider>(
        builder: (context, profileProvider, _) {
          final profile = profileProvider.profile;
          final isLoading = profileProvider.isLoading || _isLoading;

          if (profileProvider.isLoading && profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                "Profil Usaha",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                color: container,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, _) {
                              final logoPath = profileProvider.logoPath;
                              final googlePhotoUrl = profileProvider.logoUrl;
                              // Prioritas: logo lokal > foto Google > default icon
                              if (logoPath != null && logoPath.isNotEmpty) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(logoPath),
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const CircleAvatar(
                                              radius: 30,
                                              backgroundColor: Colors.grey,
                                              child: Icon(
                                                Icons.store,
                                                size: 30,
                                              ),
                                            ),
                                  ),
                                );
                              } else if (googlePhotoUrl != null &&
                                  googlePhotoUrl.isNotEmpty) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    googlePhotoUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const CircleAvatar(
                                              radius: 30,
                                              backgroundColor: Colors.grey,
                                              child: Icon(
                                                Icons.store,
                                                size: 30,
                                              ),
                                            ),
                                  ),
                                );
                              } else {
                                return const CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.grey,
                                  child: Icon(Icons.store, size: 30),
                                );
                              }
                            },
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Consumer<AuthProvider>(
                              builder: (context, authProvider, _) {
                                final user = authProvider.currentUser;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _namaController.text.isEmpty
                                          ? "Nama Usaha"
                                          : _namaController.text,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _alamatController.text.isEmpty
                                          ? "Alamat belum diisi"
                                          : _alamatController.text,
                                    ),
                                    Text(
                                      _kontakController.text.isEmpty
                                          ? "Kontak belum diisi"
                                          : _kontakController.text,
                                    ),
                                    Text(
                                      (user?.email ?? '').isEmpty
                                          ? "Email belum diisi"
                                          : user!.email!,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.edit),
                        tooltip: 'Edit Profil',
                        onPressed: isLoading ? null : _showEditDialog,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Kategori Menu",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                color: surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Kelompokkan menu dengan kategori buatanmu.",
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      if (_isCategoryLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (_categories.isEmpty)
                        const Text('Belum ada kategori')
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _categories
                              .map((c) => Chip(
                                    label: Text(c),
                                    backgroundColor: container,
                                  ))
                              .toList(),
                        ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: _openCategoryManager,
                          icon: const Icon(Icons.edit),
                          label: const Text('Kelola kategori'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Pembayaran",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        "Gambar QRIS",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      if (profileProvider.qrisPath != null &&
                          profileProvider.qrisPath!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(profileProvider.qrisPath!),
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Text("Gagal memuat gambar QRIS"),
                          ),
                        )
                      else
                        const Text("Belum ada gambar QRIS"),
                      const SizedBox(height: 10),

                      // Tombol dinamis: Upload -> Hapus
                      if (profileProvider.qrisPath == null ||
                          profileProvider.qrisPath!.isEmpty)
                        ElevatedButton.icon(
                          onPressed: isLoading ? null : _pickQRIS,
                          icon: const Icon(Icons.qr_code),
                          label: const Text("Upload Gambar QRIS"),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: isLoading ? null : _deleteQRIS,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onError,
                          ),
                          icon: const Icon(Icons.delete),
                          label: const Text("Hapus Gambar QRIS"),
                        ),

                      const SizedBox(height: 16),
                      TextField(
                        controller: _diskonController,
                        keyboardType: TextInputType.number,
                        enabled: !isLoading,
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
                        enabled: !isLoading,
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
              const Text(
                "Tampilan",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                color: surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
              const Text(
                "Mode Demo",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                color: surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.bug_report),
                  title: const Text("Demo"),
                  subtitle: Text(
                    _hasDummyData
                        ? "Hapus data simulasi/dummy."
                        : "Masukkan data simulasi/dummy.",
                  ),
                  trailing: _isDemoLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: _handleDemoAction,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Tentang Aplikasi",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                color: surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text("KasirQ v1.0.0"),
                      subtitle: Text(
                        "Aplikasi kasir untuk memenuhi tugas kuliah dan praktik.",
                      ),
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
              const SizedBox(height: 24),
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  return ElevatedButton.icon(
                    icon: Icon(
                      Icons.logout,
                      color: Theme.of(context).colorScheme.onError,
                    ),
                    label: Text(
                      'Keluar Akun Google',
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onError,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Konfirmasi Keluar'),
                          content: const Text('Apakah Anda yakin ingin keluar?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onError,
                              ),
                              child: const Text('Keluar'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        try {
                          context.read<BusinessProfileProvider>().clearProfile();
                          await authProvider.signOut();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Berhasil keluar')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal keluar: $e')),
                            );
                          }
                        }
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}
