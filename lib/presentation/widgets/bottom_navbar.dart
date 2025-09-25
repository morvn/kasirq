import 'package:flutter/material.dart';

class BottomNavbar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const BottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: cs.surface,
      indicatorColor: cs.primary.withOpacity(0.9),
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.point_of_sale, color: cs.onSurfaceVariant),
          selectedIcon: Icon(Icons.point_of_sale, color: cs.onPrimary),
          label: 'Kasir',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long, color: cs.onSurfaceVariant),
          selectedIcon: Icon(Icons.receipt_long, color: cs.onPrimary),
          label: 'Pesanan',
        ),
        NavigationDestination(
          icon: Icon(Icons.restaurant_menu, color: cs.onSurfaceVariant),
          selectedIcon: Icon(Icons.restaurant_menu, color: cs.onPrimary),
          label: 'Menu',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart, color: cs.onSurfaceVariant),
          selectedIcon: Icon(Icons.bar_chart, color: cs.onPrimary),
          label: 'Laporan',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings, color: cs.onSurfaceVariant),
          selectedIcon: Icon(Icons.settings, color: cs.onPrimary),
          label: 'Pengaturan',
        ),
      ],
    );
  }
}
