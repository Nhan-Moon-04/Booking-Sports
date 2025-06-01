import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  String id;
  String userId;
  String fieldId;
  DateTime bookingTime;
  String status;

  Booking({
    required this.id,
    required this.userId,
    required this.fieldId,
    required this.bookingTime,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fieldId': fieldId,
      'bookingTime': bookingTime,
      'status': status,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'],
      userId: map['userId'],
      fieldId: map['fieldId'],
      bookingTime: (map['bookingTime'] as Timestamp).toDate(),
      status: map['status'],
    );
  }
}