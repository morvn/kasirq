import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/cart_item.dart';
import '../../providers/business_profile_provider.dart';
import '../../providers/auth_provider.dart';

class ReceiptPage extends StatefulWidget {
  final String customerName;
  final String tableNumber;
  final List<CartItem> items;

  const ReceiptPage({
    super.key,
    required this.customerName,
    required this.tableNumber,
    required this.items,
  });

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);

    return Consumer<BusinessProfileProvider>(
      builder: (context, profileProvider, _) {
        final profile = profileProvider.profile;

        final total = widget.items
            .fold(0.0, (sum, item) => sum + (item.menu.price * item.quantity));

        final diskonPersen = profile?.diskonPersen ?? 0.0;
        final ppnPersen = profile?.ppnPersen ?? 10.0;

        final diskon = total * (diskonPersen / 100);
        final ppn = (total - diskon) * (ppnPersen / 100);
        final service = total * 0.10;
        final totalBayar = total - diskon + ppn + service;

        return Scaffold(
          appBar: AppBar(title: const Text("Struk Pembayaran")),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Column(
                  children: [
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        final logoPath = profileProvider.logoPath;
                        final googlePhotoUrl = profileProvider.logoUrl;
                        
                        // Prioritas: logo lokal > foto Google
                        if (logoPath != null && logoPath.isNotEmpty) {
                          // Gunakan logo lokal
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Image.file(
                              File(logoPath),
                              height: 80,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image),
                            ),
                          );
                        } else if (googlePhotoUrl != null && googlePhotoUrl.isNotEmpty) {
                          // Gunakan foto Google
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Image.network(
                              googlePhotoUrl,
                              height: 80,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    Text(
                      profile?.namaUsaha ?? 'Usaha Saya',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      profile?.alamatUsaha ?? '-',
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Kontak: ${profile?.kontakUsaha ?? '-'}',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const Divider(height: 32),
                Text("Nama: ${widget.customerName}"),
                Text("Meja: ${widget.tableNumber}"),
                Text("Waktu: $formattedDate"),
                const SizedBox(height: 12),
                const Text(
                  "Detail Pesanan",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...widget.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child:
                                  Text('${item.menu.name} x ${item.quantity}')),
                          Text('Rp${item.menu.price * item.quantity}'),
                        ],
                      ),
                    )),
                const Divider(height: 32),
                _buildRow("Subtotal", total),
                if (diskonPersen > 0)
                  _buildRow(
                      "Diskon ${diskonPersen.toStringAsFixed(0)}%", -diskon),
                if (ppnPersen > 0)
                  _buildRow("PPN ${ppnPersen.toStringAsFixed(0)}%", ppn),
                _buildRow("Service 10%", service),
                const SizedBox(height: 8),
                _buildRow("Total Bayar", totalBayar, bold: true),
                const SizedBox(height: 24),
                const Text("Bayar via QRIS",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                profileProvider.qrisPath != null &&
                        profileProvider.qrisPath!.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              insetPadding: const EdgeInsets.all(16),
                              backgroundColor: Colors.black87,
                              child: InteractiveViewer(
                                child: Image.file(
                                  File(profileProvider.qrisPath!),
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image,
                                          color: Colors.white),
                                ),
                              ),
                            ),
                          );
                        },
                        child: Image.file(
                          File(profileProvider.qrisPath!),
                          height: 200,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image),
                        ),
                      )
                    : const Text("QRIS belum diatur"),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text("Cetak Struk"),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  bold ? const TextStyle(fontWeight: FontWeight.bold) : null),
          Text("Rp${value.toStringAsFixed(0)}",
              style:
                  bold ? const TextStyle(fontWeight: FontWeight.bold) : null),
        ],
      ),
    );
  }
}
