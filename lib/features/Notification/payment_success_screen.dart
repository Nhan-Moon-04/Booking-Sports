import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:do_an_mobile/Firestore Database/booking.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final Booking booking;
  final String fieldName;

  const PaymentSuccessScreen({
    super.key,
    required this.booking,
    required this.fieldName,
  });

  @override
  _PaymentSuccessScreenState createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _saveBookingAndNotification();
  }

  Future<void> _saveBookingAndNotification() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Lưu thông tin đặt sân
      await firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('bookings')
          .doc(widget.booking.id)
          .set(widget.booking.toMap());

      // Lưu thông báo vào Firestore
      final notificationId = DateTime.now().millisecondsSinceEpoch.toString();
      final notification = {
        'id': notificationId,
        'userId': auth.currentUser!.uid,
        'title': 'Đặt sân thành công',
        'message':
            'Bạn đã đặt sân ${widget.fieldName} vào ngày ${DateFormat('dd/MM/yyyy').format(widget.booking.bookingDate)} từ ${widget.booking.startTimeSlot} đến ${widget.booking.endTimeSlot}.',
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'isRead': false,
      };
      await firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('notifications')
          .doc(notificationId)
          .set(notification);

      setState(() {
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu dữ liệu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh Toán Thành Công', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.lightBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        automaticallyImplyLeading: false, // Ẩn nút back mặc định
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.lightBlueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _isSaving
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 80,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Thanh toán và đặt sân thành công!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Sân: ${widget.fieldName}',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ngày: ${DateFormat('dd/MM/yyyy').format(widget.booking.bookingDate)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Khung giờ: ${widget.booking.startTimeSlot} - ${widget.booking.endTimeSlot}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tổng tiền: ${NumberFormat('#,###').format(widget.booking.amount)} VND',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          if (widget.booking.note.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Ghi chú: ${widget.booking.note}',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context); // Quay lại màn hình trước (HomeScreen)
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Quay lại',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}