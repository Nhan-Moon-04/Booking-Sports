import 'package:do_an_mobile/Firestore%20Database/booking.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:do_an_mobile/features/booking_schedule/detail_booking.dart';

class BookingScheduleScreen extends StatefulWidget {
  const BookingScheduleScreen({Key? key}) : super(key: key);

  @override
  State<BookingScheduleScreen> createState() => _BookingScheduleScreenState();
}

class _BookingScheduleScreenState extends State<BookingScheduleScreen> {
  // 0: Today, 1: All, 2: Cancelled (đã hủy)
  int _selectedFilterIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _filterLabels = ['Lịch hôm nay', 'Tất cả', 'Lịch đã hủy'];

  Stream<List<Booking>> _fetchBookings() {
  final userId = _auth.currentUser?.uid;
  if (userId == null) return const Stream.empty();

  Query<Map<String, dynamic>> bookingQuery = _firestore
      .collection('users')
      .doc(userId)
      .collection('bookings');

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day); // bỏ phần giờ

  if (_selectedFilterIndex == 0) {
    // Lịch hôm nay: chỉ lấy lịch confirmed và ngày khớp
    bookingQuery = bookingQuery
        .where('status', isEqualTo: 'confirmed')
        .where('bookingDate', isEqualTo: Timestamp.fromDate(today));
  } else if (_selectedFilterIndex == 1) {
    // Tất cả lịch (trừ đã hủy)
    bookingQuery = bookingQuery.where('status', isNotEqualTo: 'cancelled');
  } else if (_selectedFilterIndex == 2) {
    // Lịch đã hủy
    bookingQuery = bookingQuery.where('status', isEqualTo: 'cancelled');
  }

  return bookingQuery.snapshots().map(
    (snapshot) =>
        snapshot.docs.map((doc) => Booking.fromDocument(doc)).toList(),
  );
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
                ...List.generate(_filterLabels.length, (index) {
                  final isSelected = _selectedFilterIndex == index;
                  return ElevatedButton(
                    onPressed:
                        () => setState(() => _selectedFilterIndex = index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isSelected ? Colors.pink : Colors.grey[300],
                      foregroundColor: isSelected ? Colors.white : Colors.black,
                    ),
                    child: Text(_filterLabels[index]),
                  );
                }),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Booking>>(
              stream: _fetchBookings(),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8,
                      ),
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
                              title: Text(
                                'Thời gian: ${booking.startTimeSlot} - ${booking.endTimeSlot}',
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ngày đặt: ${booking.bookingDate.toLocal().toString().split(' ')[0]}',
                                  ),
                                  Text('Trạng thái: ${booking.status}'),
                                  Text(
                                    'Sân trong nhà: ${booking.indoorCourt ? "Có" : "Không"}',
                                  ),
                                  if (booking.note.isNotEmpty)
                                    Text('Ghi chú: ${booking.note}'),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => BookingDetailScreen(
                                          booking: booking,
                                        ),
                                  ),
                                );
                              },
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
