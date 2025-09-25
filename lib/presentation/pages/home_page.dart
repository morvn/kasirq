import 'package:flutter/material.dart';
import 'package:kasirq/presentation/pages/laporan.dart';
import 'package:kasirq/presentation/pages/pengaturan.dart';
import '../widgets/bottom_navbar.dart';
import 'kasir.dart';
import 'menu.dart';
import 'pesanan.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    Kasir(), // 0: Kasir
    OrderListPage(), // 1: Order
    MenuListPage(), // 2: Menu
    ReportPage(), // 3: Laporan
    SettingPage(), // 4: Pengaturan
  ];

  void _onNavBarTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // AppBar pada desain Anda memakai primary sebagai latar.
    // Maka warna logo harus onPrimary agar selalu kontras.
    final appBarBackground = cs.primary;
    final logoColor = cs.onPrimary;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 4,
        backgroundColor: appBarBackground,
        foregroundColor: logoColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        title: ColorFiltered(
          colorFilter: ColorFilter.mode(logoColor, BlendMode.srcIn),
          child: Image.asset(
            'assets/images/logo.png',
            width: 56, // dibesarkan dari 34
            height: 56,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavbar(
        currentIndex: _selectedIndex,
        onTap: _onNavBarTapped,
      ),
    );
  }
}
