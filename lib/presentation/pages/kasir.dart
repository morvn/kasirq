// lib/presentation/pages/kasir.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/database/db_helper.dart';
import '../../core/services/menu_service.dart';
import '../../core/services/order_service.dart';
import '../../data/models/menu_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/business_profile_provider.dart';
import '../widgets/category_manager_sheet.dart';
import 'checkout.dart';

class Kasir extends StatefulWidget {
  const Kasir({super.key});

  @override
  State<Kasir> createState() => _KasirState();
}

class _KasirState extends State<Kasir> {
  late Future<List<MenuModel>> _menuList;
  String? _selectedCategory;
  final PageController _pageController = PageController();
  // Hapus variable _namaUsaha dan _logoPath yang terkait SharedPreferences
  // String _namaUsaha = 'Nama Usaha';
  // String? _logoPath;

  // Konstanta layout
  static const double _cardRadius = 16.0;
  static const double _imgRadius = 12.0;

  @override
  void initState() {
    super.initState();
    _menuList = _loadMenus();
    // Hapus pemanggilan _loadTokoInfo();
  }

  Future<List<MenuModel>> _loadMenus() async {
    final user = FirebaseAuth.instance.currentUser;
    try {
      if (user != null) {
        final menus = await MenuService().syncMenus(userId: user.uid);
        try {
          await OrderService().syncUnsyncedOrders(userId: user.uid);
        } catch (_) {
          // Abaikan kegagalan sync transaksi di sini; akan dicoba lagi saat checkout berikutnya
        }
        return menus;
      }
      return await DBHelper().getMenus();
    } catch (e) {
      final fallback = await DBHelper().getMenus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal sinkron menu: $e')),
          );
        }
      });
      return fallback;
    }
  }

  Future<void> _openCategoryManager() async {
    final user = FirebaseAuth.instance.currentUser;
    await CategoryManagerSheet.show(context, userId: user?.uid);
    if (!mounted) return;
    setState(() {
      _menuList = _loadMenus();
      _selectedCategory = null;
    });
  }

  // Hapus method _loadTokoInfo karena sudah tidak diperlukan

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardTheme.color ??
        (isDark ? cs.surfaceContainerHigh : cs.surface);
    final brCard = BorderRadius.circular(_cardRadius);
    final brImg = BorderRadius.circular(_imgRadius);
    final boxShadows = _buildShadows(isDark);

    // Ambil profile dari BusinessProfileProvider
    final profileProvider = context.watch<BusinessProfileProvider>();
    final namaUsaha = profileProvider.profile?.namaUsaha ?? 'Nama Usaha';
    final logoPath = profileProvider.profile?.logoPath;
    final logoUrl =
        profileProvider.logoUrl; // Preferensi: path lokal > Google photoURL

    return Column(
      children: [
        // HEADER TOKO (fixed)
        Container(
          color: cs.surface, // pastikan latar header sama dengan grid
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              if (logoPath != null && logoPath.isNotEmpty)
                ClipRRect(
                  borderRadius: brImg,
                  child: Image.file(
                    File(logoPath),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.store, size: 40, color: cs.onSurfaceVariant),
                  ),
                )
              else if (logoUrl != null && logoUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: brImg,
                  child: Image.network(
                    logoUrl,
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
                namaUsaha,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Kelola kategori',
                onPressed: _openCategoryManager,
                icon: const Icon(Icons.category),
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
                  final categoryList =
                      (menus.map(_categoryLabel).toSet().toList()..sort());

                  String? selectedCategory = _selectedCategory;
                  if (categoryList.isNotEmpty &&
                      (selectedCategory == null ||
                          !categoryList.contains(selectedCategory))) {
                    selectedCategory = categoryList.first;
                    if (selectedCategory != _selectedCategory) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() => _selectedCategory = selectedCategory);
                        }
                      });
                    }
                  }

                  if (categoryList.isEmpty) {
                    return const Center(child: Text('Menu belum tersedia'));
                  }

                  final String currentCategory =
                      selectedCategory ?? categoryList.first;
                  final currentIndex = categoryList.indexOf(currentCategory);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted || !_pageController.hasClients) return;
                    final page = _pageController.page?.round();
                    if (page != currentIndex && currentIndex >= 0) {
                      _pageController.jumpToPage(currentIndex);
                    }
                  });

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (categoryList.length > 1)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: Row(
                            children: categoryList.map((cat) {
                              final selected = currentCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(cat),
                                  selected: selected,
                                  onSelected: (val) async {
                                    if (val) {
                                      final targetIndex =
                                          categoryList.indexOf(cat);
                                      setState(() => _selectedCategory = cat);
                                      if (_pageController.hasClients &&
                                          targetIndex >= 0) {
                                        await _pageController.animateToPage(
                                          targetIndex,
                                          duration:
                                              const Duration(milliseconds: 250),
                                          curve: Curves.easeOutCubic,
                                        );
                                      }
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            if (index >= 0 && index < categoryList.length) {
                              setState(() =>
                                  _selectedCategory = categoryList[index]);
                            }
                          },
                          itemCount: categoryList.length,
                          itemBuilder: (context, pageIndex) {
                            final cat = categoryList[pageIndex];
                            final pageMenus = menus
                                .where((m) => _categoryLabel(m) == cat)
                                .toList();

                            if (pageMenus.isEmpty) {
                              return const Center(
                                child: Text('Menu belum tersedia'),
                              );
                            }

                            return GridView.builder(
                              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                              itemCount: pageMenus.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.75,
                              ),
                              itemBuilder: (context, index) {
                                final menu = pageMenus[index];
                                return _MenuTile(
                                  menu: menu,
                                  cs: cs,
                                  cardColor: cardColor,
                                  brCard: brCard,
                                  brImg: brImg,
                                  boxShadows: boxShadows,
                                  onTap: () => context
                                      .read<CartProvider>()
                                      .addToCart(menu),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
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
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 6,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.05),
              blurRadius: 2,
              spreadRadius: 0,
              offset: const Offset(0, 1),
            ),
          ]
        : <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 6,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
          ];
  }

  static String _categoryLabel(MenuModel menu) {
    final cat = (menu.category ?? '').trim();
    return cat.isEmpty ? 'Tanpa kategori' : cat;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
