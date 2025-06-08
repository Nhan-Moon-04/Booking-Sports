import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String userId;
  final String fieldId;
  final DateTime bookingDate;
  final String startTimeSlot;
  final String endTimeSlot;
  final DateTime bookingDateTime;
  final bool indoorCourt;
  final String note;
  final String status;
  final String paymentStatus;
  final double amount;
  final String paymentMethod;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.userId,
    required this.fieldId,
    required this.bookingDate,
    required this.startTimeSlot,
    required this.endTimeSlot,
    required this.bookingDateTime,
    required this.indoorCourt,
    required this.note,
    required this.status,
    required this.paymentStatus,
    required this.amount,
    required this.paymentMethod,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fieldId': fieldId,
      'bookingDate': bookingDate,
      'startTimeSlot': startTimeSlot,
      'endTimeSlot': endTimeSlot,
      'bookingDateTime': bookingDateTime,
      'indoorCourt': indoorCourt,
      'note': note,
      'status': status,
      'paymentStatus': paymentStatus,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt,
    };
  }

  factory Booking.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      fieldId: data['fieldId'] ?? '',
      bookingDate: (data['bookingDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startTimeSlot: data['startTimeSlot'] ?? '',
      endTimeSlot: data['endTimeSlot'] ?? '',
      bookingDateTime: (data['bookingDateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      indoorCourt: data['indoorCourt'] ?? false,
      note: data['note'] ?? '',
      status: data['status'] ?? '',
      paymentStatus: data['paymentStatus'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: data['paymentMethod'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory Booking.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return Booking(
        id: '',
        userId: '',
        fieldId: '',
        bookingDate: DateTime.now(),
        startTimeSlot: '',
        endTimeSlot: '',
        bookingDateTime: DateTime.now(),
        indoorCourt: false,
        note: '',
        status: '',
        paymentStatus: '',
        amount: 0.0,
        paymentMethod: '',
        createdAt: DateTime.now(),
      );
    }

    DateTime parseDate(dynamic value) {
      try {
        if (value is Timestamp) {
          return value.toDate();
        } else if (value is String) {
          return DateTime.parse(value);
        } else {
          return DateTime.now();
        }
      } catch (e) {
        print('Error parsing date: $e, value: $value');
        return DateTime.now();
      }
    }

    return Booking(
      id: data['id']?.toString() ?? '',
      userId: data['userId']?.toString() ?? '',
      fieldId: data['fieldId']?.toString() ?? '',
      bookingDate: parseDate(data['bookingDate']),
      startTimeSlot: data['startTimeSlot']?.toString() ?? '',
      endTimeSlot: data['endTimeSlot']?.toString() ?? '',
      bookingDateTime: parseDate(data['bookingDateTime']),
      indoorCourt: data['indoorCourt'] as bool? ?? false,
      note: data['note']?.toString() ?? '',
      status: data['status']?.toString() ?? '',
      paymentStatus: data['paymentStatus']?.toString() ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: data['paymentMethod']?.toString() ?? '',
      createdAt: parseDate(data['createdAt']),
    );
  }

  Booking copyWith({
    String? id,
    String? userId,
    String? fieldId,
    DateTime? bookingDate,
    String? startTimeSlot,
    String? endTimeSlot,
    DateTime? bookingDateTime,
    bool? indoorCourt,
    String? note,
    String? status,
    String? paymentStatus,
    double? amount,
    String? paymentMethod,
    DateTime? createdAt,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fieldId: fieldId ?? this.fieldId,
      bookingDate: bookingDate ?? this.bookingDate,
      startTimeSlot: startTimeSlot ?? this.startTimeSlot,
      endTimeSlot: endTimeSlot ?? this.endTimeSlot,
      bookingDateTime: bookingDateTime ?? this.bookingDateTime,
      indoorCourt: indoorCourt ?? this.indoorCourt,
      note: note ?? this.note,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
