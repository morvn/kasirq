import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // tambahkan ini
import '../../data/models/cart_item.dart';

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
  String? _qrisPath;
  String? _logoPath;
  String? _namaUsaha;
  String? _alamatUsaha;
  String? _kontakUsaha;

  double _diskonPersen = 0.0;
  double _ppnPersen = 0.0;

  @override
  void initState() {
    super.initState();
    _loadBusinessInfo();
  }

  Future<void> _loadBusinessInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _logoPath = prefs.getString('logo_path');
      _qrisPath = prefs.getString('qris_path');
      _namaUsaha = prefs.getString('nama_usaha') ?? 'Usaha Saya';
      _alamatUsaha = prefs.getString('alamat_usaha') ?? '-';
      _kontakUsaha = prefs.getString('kontak_usaha') ?? '-';
      _diskonPersen = prefs.getDouble('diskon_persen') ?? 0.0;
      _ppnPersen = prefs.getDouble('ppn_persen') ?? 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);

    final total = widget.items
        .fold(0.0, (sum, item) => sum + (item.menu.price * item.quantity));

    final diskon = total * (_diskonPersen / 100);
    final ppn = (total - diskon) * (_ppnPersen / 100);
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
                if (_logoPath != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Image.file(
                      File(_logoPath!),
                      height: 80,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image),
                    ),
                  ),
                Text(
                  _namaUsaha ?? '',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Text(_alamatUsaha ?? '', textAlign: TextAlign.center),
                Text('Kontak: ${_kontakUsaha ?? ''}',
                    textAlign: TextAlign.center),
              ],
            ),
            const Divider(height: 32),
            Text("Nama: ${widget.customerName}"),
            Text("Meja: ${widget.tableNumber}"),
            Text("Waktu: $formattedDate"), // sudah jadi dd/MM/yyyy
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
                          child: Text('${item.menu.name} x ${item.quantity}')),
                      Text('Rp${item.menu.price * item.quantity}'),
                    ],
                  ),
                )),
            const Divider(height: 32),
            _buildRow("Subtotal", total),
            if (_diskonPersen > 0)
              _buildRow("Diskon ${_diskonPersen.toStringAsFixed(0)}%", -diskon),
            if (_ppnPersen > 0)
              _buildRow("PPN ${_ppnPersen.toStringAsFixed(0)}%", ppn),
            _buildRow("Service 10%", service),
            const SizedBox(height: 8),
            _buildRow("Total Bayar", totalBayar, bold: true),
            const SizedBox(height: 24),
            const Text("Bayar via QRIS",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _qrisPath != null
                ? GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          insetPadding: const EdgeInsets.all(16),
                          backgroundColor: Colors.black87,
                          child: InteractiveViewer(
                            child: Image.file(
                              File(_qrisPath!),
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
                      File(_qrisPath!),
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
