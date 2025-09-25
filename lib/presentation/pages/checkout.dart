// lib/presentation/pages/checkout.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../core/database/db_helper.dart';
import 'struk.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _nameController = TextEditingController();
  final _tableController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _tableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: cart.items.isEmpty
          ? const Center(child: Text('Keranjang kosong'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Input Nama & Meja
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Pelanggan',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _tableController,
                          decoration: const InputDecoration(
                            labelText: 'Nomor Meja',
                            prefixIcon: Icon(Icons.event_seat),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ),

                // List Item (tanpa Card)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Pesanan:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...cart.items.values.map((item) {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    title: Text(item.menu.name),
                    subtitle: Text(
                      'Rp${item.menu.price} x ${item.quantity}',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () => cart.decreaseQuantity(item.menu.id!),
                        ),
                        Text(item.quantity.toString()),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => cart.increaseQuantity(item.menu.id!),
                        ),
                      ],
                    ),
                  );
                }),

                // Total
                const SizedBox(height: 16),
                Card(
                  color: colorScheme.primaryContainer,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rp${cart.totalPrice}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tombol Aksi
                Row(
                  children: [
                    // Batalkan
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.error,
                          side: BorderSide(color: colorScheme.error),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.close),
                        label: const Text('Batalkan'),
                        onPressed: () {
                          // Simpan navigator parent sebelum membuka dialog
                          final parentNav = Navigator.of(context);

                          showDialog(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              title: const Text('Konfirmasi'),
                              content: const Text(
                                'Batalkan semua pesanan di keranjang?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogCtx).pop(),
                                  child: const Text('Batal'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.error,
                                    foregroundColor: colorScheme.onError,
                                  ),
                                  onPressed: () {
                                    // Tidak ada await di sini, aman menggunakan context/dialogCtx
                                    cart.clearCart();
                                    // Tutup dialog
                                    Navigator.of(dialogCtx).pop();
                                    // Kembali ke halaman sebelumnya
                                    parentNav.pop();
                                  },
                                  child: const Text('Ya, Batalkan'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Bayar
                    // Tombol Bayar
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text('Bayar'),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(context);

                          final name = _nameController.text.trim();
                          final table = _tableController.text.trim();

                          // Jika ingin hanya nomor meja yang wajib:
                          if (table.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Isi nomor meja terlebih dahulu'),
                              ),
                            );
                            return;
                          }

                          // Jika ingin keduanya opsional, cukup hapus seluruh if di atas.

                          cart.setCustomerInfo(name, table);
                          final items = cart.items.values.toList();

                          try {
                            await DBHelper().insertOrderWithCustomer(
                              customerName: name.isEmpty
                                  ? '-'
                                  : name, // default "-" jika kosong
                              tableNumber: table.isEmpty ? '-' : table,
                              items: items,
                            );

                            if (!mounted) return;
                            cart.clearCart();

                            nav.pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => ReceiptPage(
                                  customerName: name,
                                  tableNumber: table,
                                  items: items,
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(content: Text('Gagal menyimpan: $e')),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
