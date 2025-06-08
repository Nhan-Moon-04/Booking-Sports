import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  int _totalBookings = 0;
  int _uniqueUsers = 0;
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    if (_user != null) {
      _loadStatistics();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final userId = _user!.uid;

      // 1. Lấy danh sách id sân do chủ sân sở hữu
      final fieldsSnapshot = await _firestore
          .collection('sports_fields')
          .where('ownerId', isEqualTo: userId)
          .get();

      final fieldIds = fieldsSnapshot.docs.map((doc) => doc.id).toList();

      if (fieldIds.isEmpty) {
        setState(() {
          _isLoading = false;
          _totalBookings = 0;
          _uniqueUsers = 0;
          _totalAmount = 0.0;
        });
        return;
      }

      // 2. Lấy dữ liệu bookings liên quan đến các sân này với paymentStatus = 'paid'
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('fieldId', whereIn: fieldIds)
          .where('paymentStatus', isEqualTo: 'paid')
          .get();

      // 3. Tính tổng tiền và số lượng người đặt
      final bookings = bookingsSnapshot.docs;

      // Tính tổng số booking
      final totalBookings = bookings.length;

      // Tính tổng tiền và tập hợp userId duy nhất
      double totalAmount = 0;
      Set<String> uniqueUserIds = {};

      for (var doc in bookings) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final userId = data['userId'] as String?;
        if (userId != null) uniqueUserIds.add(userId);
        totalAmount += amount;
      }

      setState(() {
        _totalBookings = totalBookings;
        _uniqueUsers = uniqueUserIds.length;
        _totalAmount = totalAmount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải thống kê: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê đặt sân'),
        backgroundColor: Colors.green[700],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng số lượt đặt sân: $_totalBookings',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Số người chơi khác nhau: $_uniqueUsers',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tổng số tiền thu được: ${_totalAmount.toStringAsFixed(0)} VNĐ',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
    );
  }
}
