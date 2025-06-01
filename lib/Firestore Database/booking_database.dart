import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking.dart';

class BookingDatabase {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addBooking(Booking booking) async {
    await _firestore.collection('bookings').doc(booking.id).set(booking.toMap());
  }

  Future<List<Booking>> getBookingsForField(String fieldId) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('fieldId', isEqualTo: fieldId)
        .get();
    return snapshot.docs.map((doc) => Booking.fromMap(doc.data())).toList();
  }
}