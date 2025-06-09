import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:do_an_mobile/Firestore Database/booking.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Booking> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchUserBookings();
  }

  Future<void> _fetchUserBookings() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookings')
          .where('status', whereIn: ['pending', 'confirmed', 'cancelled'])
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _notifications = querySnapshot.docs
            .map((doc) => Booking.fromDocument(doc))
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải thông báo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Thông báo')),
      body: _notifications.isEmpty
          ? Center(child: Text('Không có thông báo nào'))
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final booking = _notifications[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    leading: Icon(Icons.sports_tennis),
                    title: Text(
                      'Đặt sân - ${booking.status == 'pending' ? 'Chờ xác nhận' : booking.status == 'confirmed' ? 'Đã xác nhận' : 'Đã hủy'}',
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ngày: ${DateFormat('dd/MM/yyyy').format(booking.bookingDate)}'),
                        Text('Thời gian: ${booking.startTimeSlot} - ${booking.endTimeSlot}'),
                        Text('Số tiền: ${NumberFormat('#,###').format(booking.amount)} VND'),
                      ],
                    ),
                    trailing: Text(DateFormat('HH:mm dd/MM/yyyy').format(booking.createdAt)),
                  ),
                );
              },
            ),
    );
  }
}