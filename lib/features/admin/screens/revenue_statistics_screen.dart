import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RevenueStatisticsScreen extends StatefulWidget {
  const RevenueStatisticsScreen({super.key});

  @override
  State<RevenueStatisticsScreen> createState() =>
      _RevenueStatisticsScreenState();
}

class _RevenueStatisticsScreenState extends State<RevenueStatisticsScreen> {
  DateTime selectedDate = DateTime.now();

  // Hàm build truy vấn cho ngày/tháng
  Query<Map<String, dynamic>> _buildDayQuery(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return FirebaseFirestore.instance
        .collectionGroup('bookings')
        .where(
          'bookingDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('bookingDate', isLessThan: Timestamp.fromDate(endOfDay));
  }

  Query<Map<String, dynamic>> _buildMonthQuery(DateTime date) {
    final startOfMonth = DateTime(date.year, date.month, 1);
    final endOfMonth = DateTime(date.year, date.month + 1, 1);
    return FirebaseFirestore.instance
        .collectionGroup('bookings')
        .where(
          'bookingDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
        )
        .where('bookingDate', isLessThan: Timestamp.fromDate(endOfMonth));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê doanh thu'),
        backgroundColor: const Color(0xFF4A90E2),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Chọn ngày:',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4A90E2),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(selectedDate),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _buildDayQuery(selectedDate).snapshots(),
                  builder: (context, daySnapshot) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: _buildMonthQuery(selectedDate).snapshots(),
                      builder: (context, monthSnapshot) {
                        if (daySnapshot.connectionState ==
                                ConnectionState.waiting ||
                            monthSnapshot.connectionState ==
                                ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          );
                        }
                        if (daySnapshot.hasError || monthSnapshot.hasError) {
                          return Center(
                            child: Text(
                              'Lỗi: ${daySnapshot.error ?? monthSnapshot.error}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }
                        // Thống kê trong ngày
                        final dayDocs = daySnapshot.data?.docs ?? [];
                        final dayFieldIds =
                            dayDocs.map((doc) => doc['fieldId']).toSet();
                        final dayTotal = dayDocs.fold<double>(
                          0,
                          (sum, doc) => sum + (doc['amount'] as num).toDouble(),
                        );
                        // Thống kê trong tháng
                        final monthDocs = monthSnapshot.data?.docs ?? [];
                        final monthFieldIds =
                            monthDocs.map((doc) => doc['fieldId']).toSet();
                        final monthTotal = monthDocs.fold<double>(
                          0,
                          (sum, doc) => sum + (doc['amount'] as num).toDouble(),
                        );
                        return ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            Card(
                              color: Colors.white.withOpacity(0.9),
                              child: ListTile(
                                title: const Text(
                                  'Trong ngày',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Số lượt đặt sân: ${dayDocs.length}'),
                                    Text(
                                      'Số sân được đặt: ${dayFieldIds.length}',
                                    ),
                                    Text(
                                      'Tổng tiền: ${NumberFormat.currency(locale: "vi_VN", symbol: "₫").format(dayTotal)}',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              color: Colors.white.withOpacity(0.9),
                              child: ListTile(
                                title: const Text(
                                  'Trong tháng',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Số lượt đặt sân: ${monthDocs.length}',
                                    ),
                                    Text(
                                      'Số sân được đặt: ${monthFieldIds.length}',
                                    ),
                                    Text(
                                      'Tổng tiền: ${NumberFormat.currency(locale: "vi_VN", symbol: "₫").format(monthTotal)}',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
