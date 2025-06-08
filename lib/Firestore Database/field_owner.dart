import 'package:cloud_firestore/cloud_firestore.dart';

class FieldOwner {
  final String id;
  final String email;
  final String name;
  final List<String> ownedFields; // Danh sách ID sân do chủ sở hữu
  final DateTime createdAt;
  final bool isActive;
  final String? phoneNumber;
  final String? address;

  FieldOwner({
    required this.id,
    required this.email,
    required this.name,
    required this.ownedFields,
    required this.createdAt,
    required this.isActive,
    this.phoneNumber,
    this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'ownedFields': ownedFields,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'phoneNumber': phoneNumber,
      'address': address,
    };
  }

  factory FieldOwner.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FieldOwner(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      ownedFields: List<String>.from(data['ownedFields'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] as bool? ?? true,
      phoneNumber: data['phoneNumber'],
      address: data['address'],
    );
  }

  factory FieldOwner.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return FieldOwner(
        id: '',
        email: '',
        name: '',
        ownedFields: [],
        createdAt: DateTime.now(),
        isActive: true,
        phoneNumber: null,
        address: null,
      );
    }

    Timestamp parseTimestamp(dynamic value) {
      try {
        if (value is Timestamp) {
          return value;
        } else if (value is String) {
          return Timestamp.fromDate(DateTime.parse(value));
        } else {
          return Timestamp.now();
        }
      } catch (e) {
        print('Error parsing timestamp: $e, value: $value');
        return Timestamp.now();
      }
    }

    return FieldOwner(
      id: data['id']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      ownedFields: List<String>.from(data['ownedFields'] ?? []),
      createdAt: parseTimestamp(data['createdAt']).toDate(),
      isActive: data['isActive'] as bool? ?? true,
      phoneNumber: data['phoneNumber']?.toString(),
      address: data['address']?.toString(),
    );
  }

  FieldOwner copyWith({
    String? id,
    String? email,
    String? name,
    List<String>? ownedFields,
    DateTime? createdAt,
    bool? isActive,
    String? phoneNumber,
    String? address,
  }) {
    return FieldOwner(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      ownedFields: ownedFields ?? this.ownedFields,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
    );
  }
}