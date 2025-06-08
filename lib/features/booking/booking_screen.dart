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
  List<String> _selectedTimeSlots = [];
  String? _startTimeSlot;
  String? _endTimeSlot;
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

  List<String> _bookedTimeSlots = [];
  bool _isLoadingBookedSlots = false;

  late final String _bookingId;

  @override
  void initState() {
    super.initState();
    _bookingId = DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<void> _fetchBookedTimeSlots() async {
    if (_selectedDate == null) return;

    setState(() {
      _isLoadingBookedSlots = true;
      _bookedTimeSlots.clear();
    });

    try {
      final selectedDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );

      final querySnapshot =
          await _firestore
              .collectionGroup('bookings')
              .where('fieldId', isEqualTo: widget.field.id)
              .where('bookingDate', isEqualTo: Timestamp.fromDate(selectedDate))
              .where('status', whereIn: ['confirmed', 'pending'])
              .get();

      final Set<String> bookedSlots = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final startTime = data['startTimeSlot'] as String?;
        final endTime = data['endTimeSlot'] as String?;

        if (startTime == null || endTime == null) continue;

        final startIndex = _timeSlots.indexWhere(
          (slot) => slot.startsWith(startTime),
        );
        final endIndex = _timeSlots.indexWhere(
          (slot) => slot.startsWith(endTime.split(' - ')[0]),
        );

        if (startIndex != -1 && endIndex != -1) {
          for (int i = startIndex; i < endIndex; i++) {
            bookedSlots.add(_timeSlots[i]);
          }
        }
      }

      setState(() {
        _bookedTimeSlots = bookedSlots.toList();
        _isLoadingBookedSlots = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingBookedSlots = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi kiểm tra khung giờ: $e')));
    }
  }

  void _selectTimeSlots(String timeSlot) {
    // Nếu khung giờ đã được đặt thì không làm gì
    if (_bookedTimeSlots.contains(timeSlot)) return;

    setState(() {
      if (_selectedTimeSlots.contains(timeSlot)) {
        // Nếu đã chọn thì bỏ chọn
        _selectedTimeSlots.clear();
        _startTimeSlot = null;
        _endTimeSlot = null;
      } else {
        if (_startTimeSlot == null) {
          // Bắt đầu chọn khung giờ
          _startTimeSlot = timeSlot;
          _selectedTimeSlots = [timeSlot];
        } else if (_endTimeSlot == null) {
          // Kết thúc chọn khung giờ
          _endTimeSlot = timeSlot;
          final startIndex = _timeSlots.indexOf(_startTimeSlot!);
          final endIndex = _timeSlots.indexOf(_endTimeSlot!);

          // Xác định khoảng giữa start và end
          final minIndex = startIndex < endIndex ? startIndex : endIndex;
          final maxIndex = startIndex < endIndex ? endIndex : startIndex;

          // Lấy tất cả các khung giờ trong khoảng
          final slotsInRange = _timeSlots.sublist(minIndex, maxIndex + 1);

          // Kiểm tra xem có khung giờ nào đã được đặt không
          final hasBookedSlot = slotsInRange.any(
            (slot) => _bookedTimeSlots.contains(slot),
          );

          if (!hasBookedSlot) {
            // Nếu không có khung giờ nào bị đặt thì chọn tất cả
            _selectedTimeSlots = slotsInRange;
          } else {
            // Nếu có khung giờ bị đặt thì thông báo và reset
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Khung giờ đã được đặt, vui lòng chọn lại!'),
              ),
            );
            _startTimeSlot = timeSlot;
            _endTimeSlot = null;
            _selectedTimeSlots = [timeSlot];
          }
        } else {
          // Nếu đã có cả start và end thì reset và chọn lại từ đầu
          _startTimeSlot = timeSlot;
          _endTimeSlot = null;
          _selectedTimeSlots = [timeSlot];
        }
      }
    });
  }

  Booking get currentBooking {
    final timeSlot =
        _selectedTimeSlots.isNotEmpty
            ? _selectedTimeSlots.first
            : _timeSlots[0];
    return Booking(
      id: _bookingId,
      userId: _auth.currentUser?.uid ?? 'unknown_user',
      fieldId: widget.field.id,
      bookingDate: _selectedDate ?? DateTime.now(),
      startTimeSlot: timeSlot,
      endTimeSlot: timeSlot,
      bookingDateTime: DateTime.now(),
      indoorCourt: _indoorCourt,
      note:
          _noteController.text + '\nSố khung giờ: ${_selectedTimeSlots.length}',
      status: 'pending',
      paymentStatus: 'unpaid',
      amount: widget.field.price! * _selectedTimeSlots.length.toDouble(),
      paymentMethod: 'QR',
      createdAt: DateTime.now(),
    );
  }

  String get _paymentData {
    final map = currentBooking.toMap();
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Thanh toán qua QR Code',
              textAlign: TextAlign.center,
            ),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SizedBox(
                      height: 200,
                      width: 200,
                      child: QrImageView(
                        data: _paymentData,
                        version: QrVersions.auto,
                        size: 200,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Số tiền: ${NumberFormat('#,###').format(widget.field.price! * _selectedTimeSlots.length)} VND',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Quét mã QR để thanh toán',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _createPendingBooking(); // <- Thêm dòng này
                },
                child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _saveBookingToFirestore(); // Đã xác nhận thanh toán
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text(
                  'Xác nhận thanh toán',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _createPendingBooking() async {
    try {
      final bookingDateTime =
          _selectedTimeSlots.isNotEmpty
              ? DateTime(
                _selectedDate!.year,
                _selectedDate!.month,
                _selectedDate!.day,
                int.parse(
                  _selectedTimeSlots.first.split(' - ')[0].split(':')[0],
                ),
                int.parse(
                  _selectedTimeSlots.first.split(' - ')[0].split(':')[1],
                ),
              )
              : DateTime.now();

      final bookingDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );

      final start = _selectedTimeSlots.first.split(' - ')[0];
      final end = _selectedTimeSlots.last.split(' - ')[1];

      final booking = Booking(
        id: _bookingId,
        userId: _auth.currentUser!.uid,
        fieldId: widget.field.id,
        bookingDate: bookingDate,
        startTimeSlot: start,
        endTimeSlot: end,
        bookingDateTime: bookingDateTime,
        indoorCourt: _indoorCourt,
        note:
            _noteController.text +
            '\nSố khung giờ: ${_selectedTimeSlots.length}',
        status: 'pending',
        paymentStatus: "unpaid",
        amount: widget.field.price! * _selectedTimeSlots.length.toDouble(),
        paymentMethod: 'qr_code',
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('bookings')
          .doc(_bookingId)
          .set(booking.toMap());

      // Đặt hẹn sau 10 phút nếu chưa thanh toán thì hủy
      Future.delayed(const Duration(minutes: 10), () async {
        final snapshot =
            await _firestore
                .collection('users')
                .doc(_auth.currentUser!.uid)
                .collection('bookings')
                .doc(_bookingId)
                .get();

        if (snapshot.exists && snapshot.data()?['status'] == 'pending') {
          await snapshot.reference.update({'status': 'cancelled'});
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đơn đặt sân đã hết hạn và bị huỷ.'),
              ),
            );
          }
        }
      });
    } catch (e) {
      print('Error creating pending booking: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi tạo đơn pending: $e')));
      }
    }
  }

  Future<void> _saveBookingToFirestore() async {
    try {
      final bookingDateTime =
          _selectedTimeSlots.isNotEmpty
              ? DateTime(
                _selectedDate!.year,
                _selectedDate!.month,
                _selectedDate!.day,
                int.parse(
                  _selectedTimeSlots.first.split(' - ')[0].split(':')[0],
                ),
                int.parse(
                  _selectedTimeSlots.first.split(' - ')[0].split(':')[1],
                ),
              )
              : DateTime.now();

      // Chuẩn hóa bookingDate để chỉ chứa ngày
      final bookingDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );
      final start = _selectedTimeSlots.first.split(' - ')[0];
      final end = _selectedTimeSlots.last.split(' - ')[1];
      final booking = Booking(
        id: _bookingId,
        userId: _auth.currentUser!.uid,
        fieldId: widget.field.id,
        bookingDate: bookingDate, // Lưu chỉ ngày
        startTimeSlot: start,
        endTimeSlot: end,
        bookingDateTime: bookingDateTime,
        indoorCourt: _indoorCourt,
        note:
            _noteController.text +
            '\nSố khung giờ: ${_selectedTimeSlots.length}',
        status: 'confirmed',
        paymentStatus: "paid",
        amount: widget.field.price! * _selectedTimeSlots.length.toDouble(),
        paymentMethod: 'qr_code',
        createdAt: DateTime.now(),
      );

      print('Saving booking: ${booking.toMap()}');

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
      print('Error saving booking: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi đặt sân: $e')));
      }
    }
  }

  Future<void> _initiateBooking() async {
    if (_selectedDate == null || _selectedTimeSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày và khung giờ!')),
      );
      return;
    }

    if (_auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đặt sân!')),
      );
      return;
    }

    await _fetchBookedTimeSlots();
    final hasBookedSlot = _selectedTimeSlots.any(
      (slot) => _bookedTimeSlots.contains(slot),
    );
    if (hasBookedSlot) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Khung giờ đã được đặt, vui lòng chọn lại!'),
        ),
      );
      setState(() {
        _selectedTimeSlots.clear();
        _startTimeSlot = null;
        _endTimeSlot = null;
      });
      return;
    }

    await _showQRPaymentDialog();
  }

  Widget _buildDaySelector() {
    final now = DateTime.now(); // Hiện tại là 04/06/2025, Thứ 4
    final days = List.generate(5, (index) => now.add(Duration(days: index)));

    // Hàm chuyển đổi số weekday thành tên ngày tiếng Việt
    String getVietnameseDay(int weekday) {
      switch (weekday) {
        case 1:
          return "Thứ 2";
        case 2:
          return "Thứ 3";
        case 3:
          return "Thứ 4";
        case 4:
          return "Thứ 5";
        case 5:
          return "Thứ 6";
        case 6:
          return "Thứ 7";
        case 7:
          return "Chủ nhật";
        default:
          return "Không xác định";
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn ngày',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:
                  days.map((day) {
                    final isSelected =
                        _selectedDate != null &&
                        _selectedDate!.day == day.day &&
                        _selectedDate!.month == day.month &&
                        _selectedDate!.year == day.year;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = day;
                          _selectedTimeSlots.clear();
                          _startTimeSlot = null;
                          _endTimeSlot = null;
                        });
                        _fetchBookedTimeSlots(); // Gọi hàm fetch khi chọn ngày mới
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient:
                              isSelected
                                  ? LinearGradient(
                                    colors: [Colors.blue, Colors.lightBlue],
                                  )
                                  : null,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              isSelected
                                  ? null
                                  : Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Tháng ${day.month}', // Hiển thị "Tháng 6" thay vì "Th6"
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
                              getVietnameseDay(
                                day.weekday,
                              ), // Hiển thị ngày trong tuần đúng
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt Sân', style: TextStyle(color: Colors.white)),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.field.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.field.address,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin sân',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.sports, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          widget.field.sportType,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: _indoorCourt,
                          onChanged:
                              (value) => setState(() => _indoorCourt = value!),
                        ),
                        const Text(
                          'Sân trong nhà',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            _buildDaySelector(),
            const SizedBox(height: 16),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chọn khung giờ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _isLoadingBookedSlots
                        ? const Center(child: CircularProgressIndicator())
                        : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: _timeSlots.length,
                          itemBuilder: (context, index) {
                            final timeSlot = _timeSlots[index];
                            final isSelected = _selectedTimeSlots.contains(
                              timeSlot,
                            );
                            final isBooked = _bookedTimeSlots.contains(
                              timeSlot,
                            );

                            return GestureDetector(
                              onTap:
                                  isBooked
                                      ? null
                                      : () => _selectTimeSlots(timeSlot),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient:
                                      isSelected
                                          ? LinearGradient(
                                            colors: [
                                              Colors.blue,
                                              Colors.lightBlue,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                          : null,
                                  color:
                                      isBooked
                                          ? Colors.grey[300]
                                          : isSelected
                                          ? null
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        isBooked
                                            ? Colors.grey
                                            : Colors.grey.shade300,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    timeSlot,
                                    style: TextStyle(
                                      color:
                                          isBooked
                                              ? Colors.grey[600]
                                              : isSelected
                                              ? Colors.white
                                              : Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ghi chú',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        hintText: 'Ghi chú cho đơn hàng...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thành tiền',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tổng số giờ'),
                        Text(
                          '${_selectedTimeSlots.length.toStringAsFixed(1)} giờ',
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
                          _selectedTimeSlots.isNotEmpty
                              ? '${NumberFormat('#,###').format(widget.field.price! * _selectedTimeSlots.length)} VND'
                              : '0 VND',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'HỦY',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _initiateBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'ĐẶT LỊCH',
                      style: TextStyle(color: Colors.white, fontSize: 16),
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
