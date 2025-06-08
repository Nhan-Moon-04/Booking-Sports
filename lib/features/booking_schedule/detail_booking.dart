import 'package:flutter/material.dart';
import 'package:do_an_mobile/Firestore Database/booking.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingDatabase {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> cancelBooking({
    required String userId,
    required String bookingId,
  }) async {
    try {
      final bookingRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('bookings')
          .doc(bookingId);

      await bookingRef.update({'status': 'cancelled'});
    } catch (e) {
      print('Lỗi khi hủy booking: $e');
      rethrow;
    }
  }
}

class BookingDetailScreen extends StatefulWidget {
  final Booking booking;

  const BookingDetailScreen({Key? key, required this.booking}) : super(key: key);

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late Booking booking; // biến nội bộ thay đổi trạng thái được
  final BookingDatabase _bookingDb = BookingDatabase();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    booking = widget.booking; // copy tham chiếu ban đầu
  }

  Future<void> _cancelBooking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _bookingDb.cancelBooking(
        userId: booking.userId,
        bookingId: booking.id,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hủy lịch đặt thành công!')),
      );

      setState(() {
        // Cập nhật trạng thái trong biến booking nội bộ
        booking = booking.copyWith(status: 'cancelled');
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi hủy lịch đặt: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết lịch đặt'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ngày đặt: ${booking.bookingDate.toLocal().toString().split(' ')[0]}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Thời gian: ${booking.startTimeSlot} - ${booking.endTimeSlot}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Sân trong nhà: ${booking.indoorCourt ? "Có" : "Không"}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Trạng thái: ${booking.status}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            if (booking.note.isNotEmpty)
              Text('Ghi chú: ${booking.note}', style: const TextStyle(fontSize: 18)),

            const SizedBox(height: 30),

            if (booking.status != 'cancelled')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _cancelBooking,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Hủy lịch đặt'),
                ),
              )
            else
              const Text('Lịch đặt đã bị hủy',
                  style: TextStyle(color: Colors.red, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
