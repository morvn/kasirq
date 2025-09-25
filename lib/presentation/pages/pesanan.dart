import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/db_helper.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  late Future<Map<String, List<Map<String, dynamic>>>> _groupedOrders;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    _groupedOrders = DBHelper().getOrdersGroupedByCustomer();
  }

  Future<void> _markAllDone(String customerName, String tableNo) async {
    final grouped = await DBHelper().getOrdersGroupedByCustomer();
    final items = grouped["$customerName (Meja $tableNo)"] ?? [];
    for (var order in items) {
      await DBHelper().markOrderAsDone(order['id']);
    }
    setState(() {
      _loadOrders();
    });
  }

  Widget _buildStatusBadge(String status) {
    final color = status == 'done' ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status == 'done' ? 'Selesai' : 'Pending',
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  String formatDateTime(String isoString) {
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return '';
    final formatter = DateFormat("dd MMMM yyyy • HH:mm", "id_ID");
    return formatter.format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: _groupedOrders,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final groupedOrders = snapshot.data ?? {};

        if (groupedOrders.isEmpty) {
          return const Center(child: Text("Belum ada pesanan"));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: groupedOrders.entries.map((entry) {
            final groupName = entry.key;
            final items = entry.value;
            final total =
                items.fold(0, (sum, item) => sum + (item['total'] as int));
            final allDone = items.every((item) => item['status'] == 'done');
            final createdAt = items.first['created_at'];

            final nameMatch =
                RegExp(r'^(.*) \(Meja (\d+)\)$').firstMatch(groupName);
            final customerName = nameMatch?.group(1) ?? '';
            final tableNo = nameMatch?.group(2) ?? '';

            final statusBadge = _buildStatusBadge(allDone ? 'done' : 'pending');

            return Stack(
              children: [
                Card(
                  margin: const EdgeInsets.only(bottom: 24),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(groupName,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              formatDateTime(createdAt),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...items.map((order) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(order['menu_name']),
                              subtitle: Text(
                                'Jumlah: ${order['quantity']} x Rp${order['price']}',
                              ),
                            )),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total Pesanan:",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("Rp$total",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (!allDone)
                          Align(
                            alignment: Alignment.bottomRight,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _markAllDone(customerName, tableNo),
                              icon: const Icon(Icons.check),
                              label: const Text("Selesaikan Pesanan"),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 10,
                  child: statusBadge,
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}
