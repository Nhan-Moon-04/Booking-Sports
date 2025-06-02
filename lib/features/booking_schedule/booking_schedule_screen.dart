import 'package:do_an_mobile/Firestore%20Database/booking.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:do_an_mobile/Firestore Database/booking_database.dart'; 

class BookingScheduleScreen extends StatefulWidget {
  const BookingScheduleScreen({super.key});

  @override
  State<BookingScheduleScreen> createState() => _BookingScheduleScreenState();
}

class _BookingScheduleScreenState extends State<BookingScheduleScreen> {
  int _currentFilter = 0; // 0: Today, 1: All, 2: Pending
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _filterOptions = ['Lịch hôm nay', 'Tất cả', 'Giờ chờ'];

  Stream<List<Booking>> getBookingsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return const Stream.empty();

    Query<Map<String, dynamic>> query = _firestore
        .collection('users')
        .doc(userId)
        .collection('bookings');

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    if (_currentFilter == 0) {
      query = query
          .where('bookingDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('bookingDate', isLessThan: Timestamp.fromDate(endOfDay));
    } else if (_currentFilter == 2) {
      query = query.where('status', isEqualTo: 'pending');
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Booking.fromDocument(doc))
        .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách lịch đặt'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: Icon(Icons.notifications),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.search),
                ...List.generate(_filterOptions.length, (index) {
                  return ElevatedButton(
                    onPressed: () => setState(() => _currentFilter = index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _currentFilter == index ? Colors.pink : Colors.grey[300],
                    ),
                    child: Text(_filterOptions[index]),
                  );
                }),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Booking>>(
              stream: getBookingsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Lỗi khi tải dữ liệu'));
                }
                final bookings = snapshot.data ?? [];
                if (bookings.isEmpty) {
                  return const Center(child: Text('Không có đơn đặt nào'));
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng số đơn:'),
                          Text('${bookings.length}'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          final booking = bookings[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            child: ListTile(
                              title: Text('Thời gian: ${booking.timeSlot}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Ngày đặt: ${booking.bookingDate.toLocal().toString().split(' ')[0]}'),
                                  Text('Trạng thái: ${booking.status}'),
                                  Text('Sân trong nhà: ${booking.indoorCourt ? "Có" : "Không"}'),
                                  if (booking.note.isNotEmpty) Text('Ghi chú: ${booking.note}'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
