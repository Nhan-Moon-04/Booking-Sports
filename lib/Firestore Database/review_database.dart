import 'package:cloud_firestore/cloud_firestore.dart';
import 'review.dart';

class ReviewDatabase {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addReview(Review review) async {
    await _firestore.collection('reviews').doc(review.id).set(review.toMap());
  }

  Future<List<Review>> getReviewsForField(String fieldId) async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('fieldId', isEqualTo: fieldId)
        .get();
    return snapshot.docs.map((doc) => Review.fromMap(doc.data())).toList();
  }
}