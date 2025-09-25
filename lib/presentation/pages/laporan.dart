// lib/presentation/pages/laporan.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/database/db_helper.dart';
import 'detail_harian.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late Future<List<Map<String, dynamic>>> _report;
  late Future<Map<String, dynamic>> _monthlySummary;
  late Future<List<Map<String, dynamic>>> _topMenus;

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadReport();
    final now = DateTime.now();
    _monthlySummary =
        DBHelper().getMonthlySummary(year: now.year, month: now.month);
    _topMenus = DBHelper().getTopMenus(year: now.year, month: now.month);
  }

  void _loadReport() {
    _report = DBHelper().getDailyReport();
  }

  bool _isWithinRange(String tanggal) {
    final date = DateTime.parse(tanggal);
    if (_startDate == null || _endDate == null) return true;
    return !date.isBefore(_startDate!) && !date.isAfter(_endDate!);
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      locale: const Locale('id', 'ID'),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _resetFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  String get _rangeLabel {
    if (_startDate == null || _endDate == null) return 'Laporan';
    final format = DateFormat('dd MMM', 'id_ID');
    return 'Laporan: ${format.format(_startDate!)} – ${format.format(_endDate!)}';
  }

  String formatCurrency(int amount) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return formatter.format(amount);
  }

  Widget buildMonthlySummaryCard(Map<String, dynamic> data, int avgOmzet) {
    final omzet = data['total_omzet'] ?? 0;
    final transaksi = data['total_transaksi'] ?? 0;
    final item = data['total_item'] ?? 0;

    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.primaryContainer,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Ringkasan Bulan Ini',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text('Omzet: ${formatCurrency(omzet)}'),
            Text('Rata-rata omzet harian: ${formatCurrency(avgOmzet)}'),
            Text('Pesanan: $transaksi transaksi'),
            Text('Item terjual: $item'),
          ],
        ),
      ),
    );
  }

  Widget buildTopMenus(List<Map<String, dynamic>> data) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      // DEPRECATED FIX: surfaceVariant -> surfaceContainerHighest
      color: scheme.surfaceContainerHighest,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔥 Menu Terlaris Bulan Ini',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            ...data.map((e) => Row(
                  children: [
                    const Icon(Icons.label, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child:
                          Text('${e['name']} — ${e['total_terjual']} terjual'),
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_rangeLabel),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Pilih Rentang Tanggal',
            onPressed: _pickDateRange,
          ),
          if (_startDate != null || _endDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Reset Filter',
              onPressed: _resetFilter,
            ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _report,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data ?? [];
          final filtered =
              data.where((row) => _isWithinRange(row['tanggal'])).toList();

          final dailyOmzets =
              filtered.map((e) => e['total_omzet'] as int).toList();
          final avgOmzet = dailyOmzets.isEmpty
              ? 0
              : dailyOmzets.reduce((a, b) => a + b) ~/ dailyOmzets.length;

          final barGroups = filtered.asMap().entries.map((e) {
            final omzet = (e.value['total_omzet'] as num).toDouble() / 1000;
            return BarChartGroupData(
              x: e.key,
              barRods: [BarChartRodData(toY: omzet, width: 16)],
            );
          }).toList();

          final labels = filtered
              .map((e) =>
                  DateFormat('dd/MM').format(DateTime.parse(e['tanggal'])))
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AspectRatio(
                aspectRatio: 1.7,
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: BarChart(
                      BarChartData(
                        barGroups: barGroups,
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, _) => Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                final index = value.toInt();
                                // LINT FIX: pakai blok {}
                                if (index < 0 || index >= labels.length) {
                                  return const SizedBox();
                                }
                                return Text(
                                  labels[index],
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DailyDetailPage(data: filtered),
                    ),
                  );
                },
                icon: const Icon(Icons.list_alt),
                label: const Text('Detail Laporan Harian'),
              ),
              const SizedBox(height: 16),
              FutureBuilder<Map<String, dynamic>>(
                future: _monthlySummary,
                builder: (context, summarySnap) {
                  if (summarySnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // LINT FIX: pakai blok {}
                  if (!summarySnap.hasData) {
                    return const SizedBox();
                  }
                  return buildMonthlySummaryCard(summarySnap.data!, avgOmzet);
                },
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _topMenus,
                builder: (context, menuSnap) {
                  // LINT FIX: pakai blok {}
                  if (menuSnap.connectionState == ConnectionState.waiting) {
                    return const SizedBox();
                  }
                  // LINT FIX: pakai blok {}
                  if (!menuSnap.hasData || menuSnap.data!.isEmpty) {
                    return const SizedBox();
                  }
                  return buildTopMenus(menuSnap.data!);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
