import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DailyDetailPage extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const DailyDetailPage({super.key, required this.data});

  String formatCurrency(int amount) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return formatter.format(amount);
  }

  String formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Laporan Harian'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final row = data[index];
          final tanggal = row['tanggal'];
          final totalPesanan = row['total_pesanan'];
          final totalItem = row['total_item'];
          final totalOmzet = row['total_omzet'];

          return Card(
            color: colorScheme.surface,
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(formatDate(tanggal)),
              subtitle: Text('$totalPesanan pesanan · $totalItem item'),
              trailing: Text(
                formatCurrency(totalOmzet),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }
}
