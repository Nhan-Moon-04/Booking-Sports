import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_mobile/Firestore%20Database/booking.dart';
import 'package:do_an_mobile/features/booking_schedule/detail_booking.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ManageBookingScreen extends StatefulWidget {
  const ManageBookingScreen({Key? key}) : super(key: key);

  @override
  State<ManageBookingScreen> createState() => _ManageBookingScreenState();
}

class _ManageBookingScreenState extends State<ManageBookingScreen> {
  // Các filter đã bỏ 'Lịch hôm nay' và 'Tất cả'
  // Chỉ còn các filter: 'Lịch đã hủy', 'Chờ xác nhận', 'Chờ thanh toán'
  int _selectedFilterIndex = 0; // 0: cancelled, 1: pending confirm, 2: pending payment

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _filterLabels = [
    'Lịch đã hủy',       // index 0
    'Chờ xác nhận',      // index 1
    'Chờ thanh toán',    // index 2
  ];

  Stream<List<Booking>> _fetchBookings() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return const Stream.empty();

    Query<Map<String, dynamic>> bookingQuery = _firestore
        .collection('users')
        .doc(userId)
        .collection('bookings');

    if (_selectedFilterIndex == 0) {
      // Lịch đã hủy
      bookingQuery = bookingQuery.where('status', isEqualTo: 'cancelled');
    } else if (_selectedFilterIndex == 1) {
      // Chờ xác nhận: status = pending, paymentStatus = paid
      bookingQuery = bookingQuery
          .where('status', isEqualTo: 'pending')
          .where('paymentStatus', isEqualTo: 'paid');
    } else if (_selectedFilterIndex == 2) {
      // Chờ thanh toán: status = pending, paymentStatus = unpaid
      bookingQuery = bookingQuery
          .where('status', isEqualTo: 'pending')
          .where('paymentStatus', isEqualTo: 'unpaid');
    }

    return bookingQuery.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Booking.fromDocument(doc)).toList());
  }

  Future<void> _updateBookingStatus(String bookingId, String status,
      {String? paymentStatus}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    Map<String, dynamic> data = {'status': status};
    if (paymentStatus != null) {
      data['paymentStatus'] = paymentStatus;
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('bookings')
        .doc(bookingId)
        .update(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý lịch đặt'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_filterLabels.length, (index) {
                  final isSelected = _selectedFilterIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ElevatedButton(
                      onPressed: () => setState(() {
                        _selectedFilterIndex = index;
                      }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isSelected ? Colors.pink : Colors.grey[300],
                        foregroundColor:
                            isSelected ? Colors.white : Colors.black,
                      ),
                      child: Text(_filterLabels[index]),
                    ),
                  );
                }),
              ),
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
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        padding: const EdgeInsets.all(16),
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          final booking = bookings[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                  'Thời gian: ${booking.startTimeSlot} - ${booking.endTimeSlot}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ngày đặt: ${booking.bookingDate.toLocal().toString().split(' ')[0]}',
                                  ),
                                  Text('Trạng thái: ${booking.status}'),
                                  Text('Thanh toán: ${booking.paymentStatus}'),
                                  Text(
                                      'Sân trong nhà: ${booking.indoorCourt ? "Có" : "Không"}'),
                                  if (booking.note.isNotEmpty)
                                    Text('Ghi chú: ${booking.note}'),
                                  if (_selectedFilterIndex == 1) // Chờ xác nhận
                                    Row(
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green),
                                          onPressed: () async {
                                            await _updateBookingStatus(
                                                booking.id, 'confirmed');
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content:
                                                        Text('Xác nhận thành công!')));
                                          },
                                          child: const Text('Xác nhận'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red),
                                          onPressed: () async {
                                            await _updateBookingStatus(
                                                booking.id, 'cancelled',
                                                paymentStatus: 'unpaid');
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text('Đã hủy lịch!')));
                                          },
                                          child: const Text('Hủy'),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BookingDetailScreen(booking: booking),
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
