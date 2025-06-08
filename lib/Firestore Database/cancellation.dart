import 'package:cloud_firestore/cloud_firestore.dart';

class Cancellation {
  final String id;
  final String bookingId;
  final String userId;
  final String fieldId;
  final DateTime cancelledAt;
  final String? reason;
  final double refundAmount;
  final String refundStatus; // 'pending', 'approved', 'rejected'
  final String? adminNote;
  final String originalStatus; // Status before cancellation

  Cancellation({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.fieldId,
    required this.cancelledAt,
    this.reason,
    required this.refundAmount,
    this.refundStatus = 'pending',
    this.adminNote,
    required this.originalStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'userId': userId,
      'fieldId': fieldId,
      'cancelledAt': cancelledAt,
      'reason': reason,
      'refundAmount': refundAmount,
      'refundStatus': refundStatus,
      'adminNote': adminNote,
      'originalStatus': originalStatus,
    };
  }

  factory Cancellation.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Cancellation(
      id: doc.id,
      bookingId: data['bookingId'] ?? '',
      userId: data['userId'] ?? '',
      fieldId: data['fieldId'] ?? '',
      cancelledAt: (data['cancelledAt'] as Timestamp).toDate(),
      reason: data['reason'],
      refundAmount: (data['refundAmount'] as num).toDouble(),
      refundStatus: data['refundStatus'] ?? 'pending',
      adminNote: data['adminNote'],
      originalStatus: data['originalStatus'] ?? '',
    );
  }
}