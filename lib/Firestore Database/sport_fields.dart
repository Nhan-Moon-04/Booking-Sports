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
  final String? phone;
  final String? openHours;

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
    this.phone,
    this.openHours,
  });

  factory SportsField.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final GeoPoint? geoPoint = data['location'] as GeoPoint?;
    return SportsField(
      id: doc.id,
      name: data['name'] ?? 'Không có tên',
      address: data['address'] ?? 'Địa chỉ không xác định',
      lat: geoPoint?.latitude ?? 0.0,
      lng: geoPoint?.longitude ?? 0.0,
      sportType: data['sportType'] ?? 'Không xác định',
      imageUrl: data['imageUrl'],
      price: (data['price'] as num?)?.toDouble(),
      distance: (data['distance'] as num?)?.toDouble(),
      rating: (data['rating'] as num?)?.toDouble(),
      reviewCount: data['reviewCount'] as int?,
      phone: data['phone'],
      openHours: data['openHours'],
    );
  }

  SportsField copyWith({
    String? id,
    String? name,
    String? address,
    double? lat,
    double? lng,
    String? sportType,
    String? imageUrl,
    double? price,
    double? distance,
    double? rating,
    int? reviewCount,
    String? phone,
    String? openHours,
  }) {
    return SportsField(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      sportType: sportType ?? this.sportType,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      distance: distance ?? this.distance,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      phone: phone ?? this.phone,
      openHours: openHours ?? this.openHours,
    );
  }
}
