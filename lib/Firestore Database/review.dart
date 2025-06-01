class Review {
  String id;
  String fieldId;
  String userId;
  String comment;
  double rating;

  Review({
    required this.id,
    required this.fieldId,
    required this.userId,
    required this.comment,
    required this.rating,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fieldId': fieldId,
      'userId': userId,
      'comment': comment,
      'rating': rating,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'],
      fieldId: map['fieldId'],
      userId: map['userId'],
      comment: map['comment'],
      rating: map['rating'].toDouble(),
    );
  }
}