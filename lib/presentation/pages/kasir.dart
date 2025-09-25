// lib/presentation/pages/kasir.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/db_helper.dart';
import '../../data/models/menu_model.dart';
import '../../providers/cart_provider.dart';
import 'checkout.dart';

class Kasir extends StatefulWidget {
  const Kasir({super.key});

  @override
  State<Kasir> createState() => _KasirState();
}

class _KasirState extends State<Kasir> {
  late final Future<List<MenuModel>> _menuList;
  String _namaUsaha = 'Nama Usaha';
  String? _logoPath;

  // Konstanta layout
  static const double _cardRadius = 16.0;
  static const double _imgRadius = 12.0;

  @override
  void initState() {
    super.initState();
    _menuList = DBHelper().getMenus();
    _loadTokoInfo();
  }

  Future<void> _loadTokoInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _namaUsaha = prefs.getString('nama_usaha') ?? 'Nama Usaha';
      _logoPath = prefs.getString('logo_path');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = theme.cardTheme.color ??
        (isDark ? cs.surfaceContainerHigh : cs.surface);

    // Siapkan satu kali per build, dipakai semua tile
    final brCard = BorderRadius.circular(_cardRadius);
    final brImg = BorderRadius.circular(_imgRadius);
    final boxShadows = _buildShadows(isDark);

    return Column(
      children: [
        // HEADER TOKO (fixed)
        Container(
          color: cs.surface, // pastikan latar header sama dengan grid
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              if (_logoPath != null)
                ClipRRect(
                  borderRadius: brImg,
                  child: Image.file(
                    File(_logoPath!),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.store, size: 40, color: cs.onSurfaceVariant),
                  ),
                )
              else
                Icon(Icons.store, size: 40, color: cs.onSurfaceVariant),
              const SizedBox(width: 12),
              Text(
                _namaUsaha,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        // GRID MENU (scrollable)
        Expanded(
          child: Stack(
            children: [
              FutureBuilder<List<MenuModel>>(
                future: _menuList,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final menus = snapshot.data ?? const <MenuModel>[];
                  if (menus.isEmpty) {
                    return const Center(child: Text('Menu belum tersedia'));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                        8, 4, 8, 0), // ada jarak tipis atas
                    itemCount: menus.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (context, index) {
                      final menu = menus[index];
                      return _MenuTile(
                        menu: menu,
                        cs: cs,
                        cardColor: cardColor,
                        brCard: brCard,
                        brImg: brImg,
                        boxShadows: boxShadows,
                        onTap: () =>
                            context.read<CartProvider>().addToCart(menu),
                      );
                    },
                  );
                },
              ),

              // FAB Keranjang — hanya bagian ini yang mengikuti perubahan cart
              Positioned(
                right: 16,
                bottom: 16,
                child: Selector<CartProvider, int>(
                  selector: (_, p) => p.totalItems,
                  builder: (context, total, _) {
                    if (total <= 0) return const SizedBox.shrink();
                    return FloatingActionButton.extended(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      icon: const Icon(Icons.shopping_cart),
                      label: Text('Keranjang ($total)'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CheckoutPage()),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static List<BoxShadow> _buildShadows(bool isDark) {
    return isDark
        ? <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.55),
              blurRadius: 6,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.05),
              blurRadius: 2,
              spreadRadius: 0,
              offset: const Offset(0, 1),
            ),
          ]
        : <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 6,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
          ];
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.menu,
    required this.cs,
    required this.cardColor,
    required this.brCard,
    required this.brImg,
    required this.boxShadows,
    required this.onTap,
  });

  final MenuModel menu;
  final ColorScheme cs;
  final Color cardColor;
  final BorderRadius brCard;
  final BorderRadius brImg;
  final List<BoxShadow> boxShadows;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: brCard,
        boxShadow: boxShadows,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: brCard,
        child: InkWell(
          borderRadius: brCard,
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: (menu.imagePath != null && menu.imagePath!.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: brImg,
                          child: Image.file(
                            File(menu.imagePath!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => Icon(Icons.fastfood,
                                size: 40, color: cs.onSurfaceVariant),
                          ),
                        )
                      : Icon(Icons.fastfood,
                          size: 40, color: cs.onSurfaceVariant),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  menu.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Text(
                  'Rp${menu.price}',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
