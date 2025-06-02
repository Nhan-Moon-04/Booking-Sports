import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:do_an_mobile/firestore database/sport_fields.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'package:do_an_mobile/Firestore Database/booking.dart';

class BookingScreen extends StatefulWidget {
  final SportsField field;

  const BookingScreen({super.key, required this.field});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  bool _indoorCourt = true;
  final TextEditingController _noteController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _timeSlots = [
    '14:00 - 15:00',
    '15:00 - 16:00',
    '16:00 - 17:00',
    '17:00 - 18:00',
    '18:00 - 19:00',
    '19:00 - 20:00',
    '20:00 - 21:00',
    '21:00 - 22:00',
    '22:00 - 23:00',
    '23:00 - 24:00',
  ];

  late final String _bookingId;

  @override
  void initState() {
    super.initState();
    _bookingId = DateTime.now().millisecondsSinceEpoch.toString();
  }

  Booking get currentBooking {
    return Booking(
      id: _bookingId,
      userId: _auth.currentUser?.uid ?? 'unknown_user',
      fieldId: widget.field.id, // chắc chắn field phải có id
      bookingDate: _selectedDate ?? DateTime.now(),
      timeSlot: _selectedTimeSlot ?? _timeSlots[0],
      bookingDateTime: DateTime.now(),
      indoorCourt: _indoorCourt,
      note: _noteController.text,
      status: 'pending',
      paymentStatus: 'unpaid',
      amount: widget.field.price!.toDouble(),
      paymentMethod: 'QR',
      createdAt: DateTime.now(),
    );
  }

  String get _paymentData {
    final map = currentBooking.toMap();
    // Chuyển DateTime sang chuỗi ISO để JSON encode
    final mapStringDates = map.map((key, value) {
      if (value is DateTime) {
        return MapEntry(key, value.toIso8601String());
      }
      return MapEntry(key, value);
    });
    return jsonEncode(mapStringDates);
  }

  Future<void> _showQRPaymentDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Thanh toán qua QR Code'),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 200,
                    width: 200,
                    child: QrImageView(
                      data: _paymentData,
                      version: QrVersions.auto,
                      size: 200,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Số tiền: ${NumberFormat('#,###').format(widget.field.price)} VND',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Quét mã QR để thanh toán',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop(); // Đóng dialog trước
                  await _saveBookingToFirestore(); // Gửi booking lên Firestore
                },
                child: const Text('Xác nhận thanh toán'),
              ),
            ],
          ),
    );
  }

  Future<void> _saveBookingToFirestore() async {
    try {
      final startTime = _selectedTimeSlot!.split(' - ')[0];
      final hours = int.parse(startTime.split(':')[0]);
      final minutes = int.parse(startTime.split(':')[1]);

      final bookingDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        hours,
        minutes,
      );

      final booking = Booking(
        id: _bookingId,
        userId: _auth.currentUser!.uid,
        fieldId: widget.field.id,
        bookingDate: _selectedDate!,
        timeSlot: _selectedTimeSlot!,
        bookingDateTime: bookingDateTime,
        indoorCourt: _indoorCourt,
        note: _noteController.text,
        status: 'confirmed',
        paymentStatus: 'paid',
        amount: widget.field.price!.toDouble(),
        paymentMethod: 'qr_code',
        createdAt: DateTime.now(),
      );

      // Save to the subcollection /users/{userId}/bookings/{bookingId}
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('bookings')
          .doc(_bookingId)
          .set(booking.toMap());

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đặt sân thành công!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi đặt sân: $e')));
      }
    }
  }

  Future<void> _initiateBooking() async {
    if (_selectedDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày và giờ!')),
      );
      return;
    }

    if (_auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đặt sân!')),
      );
      return;
    }

    await _showQRPaymentDialog();
  }

  Widget _buildDaySelector() {
    final now = DateTime.now();
    final days = List.generate(5, (index) => now.add(Duration(days: index)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thứ Hai',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:
              days.map((day) {
                final isSelected =
                    _selectedDate != null &&
                    _selectedDate!.day == day.day &&
                    _selectedDate!.month == day.month;

                return GestureDetector(
                  onTap:
                      () => setState(() {
                        _selectedDate = day;
                        _selectedTimeSlot = null;
                      }),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'THG ${day.month}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.grey,
                          ),
                        ),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          'TH ${day.weekday}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 16),
        const Text('SÂN 1: 0', style: TextStyle(fontSize: 16)),
        const Text('SÂN 2: 0', style: TextStyle(fontSize: 16)),
        const Text('SÂN 3: 0', style: TextStyle(fontSize: 16)),
        const Text('SÂN 4: 0', style: TextStyle(fontSize: 16)),
        const Text('SÂN 5: 0', style: TextStyle(fontSize: 16)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đặt Sân'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Facility information
            Text(
              widget.field.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.field.address,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Sport type selection
            const Text(
              'Bộ môn',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(value: true, onChanged: null),
                const Text('Pickleball'),
                const SizedBox(width: 16),
                Checkbox(value: false, onChanged: null),
                const Text('Loại sân'),
              ],
            ),
            Row(
              children: [
                Checkbox(
                  value: _indoorCourt,
                  onChanged: (value) => setState(() => _indoorCourt = value!),
                ),
                const Text('Sân trong nhà'),
              ],
            ),
            const Divider(height: 32),

            // Date and time selection
            _buildDaySelector(),
            const SizedBox(height: 16),

            // Time slots grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _timeSlots.length,
              itemBuilder: (context, index) {
                final timeSlot = _timeSlots[index];
                final isSelected = _selectedTimeSlot == timeSlot;

                return ElevatedButton(
                  onPressed: () => setState(() => _selectedTimeSlot = timeSlot),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? Colors.blue : Colors.white,
                    foregroundColor: isSelected ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    elevation: 0,
                  ),
                  child: Text(timeSlot),
                );
              },
            ),
            const SizedBox(height: 16),

            // Notes section
            const Text(
              'Ghi chú',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'Ghi chú cho đơn hàng...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const Divider(height: 32),

            // Total section
            const Text(
              'Thành tiền',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng số giờ'),
                Text(
                  _selectedTimeSlot != null ? '1.0 giờ' : '0.0 giờ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng tiền'),
                Text(
                  _selectedTimeSlot != null
                      ? '${NumberFormat('#,###').format(widget.field.price)} VND'
                      : '0 VND',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text(
                      'HỦY',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _initiateBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'ĐẶT LỊCH',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
