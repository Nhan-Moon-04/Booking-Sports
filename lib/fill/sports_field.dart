import 'package:cloud_firestore/cloud_firestore.dart';

class SportsField {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String sportType;
  final String? imageUrl;
  final double? price;
  final double? distance;
  final double? rating;
  final int? reviewCount;

  SportsField({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.sportType,
    this.imageUrl,
    this.price,
    this.distance,
    this.rating,
    this.reviewCount,
  });

  factory SportsField.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SportsField(
      id: doc.id,
      name: data['name'] ?? 'Không có tên',
      address: data['address'] ?? 'Địa chỉ không xác định',
      lat: (data['location'] as GeoPoint).latitude,
      lng: (data['location'] as GeoPoint).longitude,
      sportType: data['sportType'] ?? 'Không xác định',
      imageUrl: data['imageUrl'],
      price: (data['price'] as num?)?.toDouble(),
      distance: (data['distance'] as num?)?.toDouble(),
      rating: (data['rating'] as num?)?.toDouble(),
      reviewCount: data['reviewCount'] as int?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'location': GeoPoint(lat, lng),
      'sportType': sportType,
      'imageUrl': imageUrl,
      'price': price,
      'distance': distance,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }
}
