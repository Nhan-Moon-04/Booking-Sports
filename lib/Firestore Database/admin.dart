import 'package:cloud_firestore/cloud_firestore.dart';

class Admin {
  final String id;
  final String email;
  final String name;
  final String role; // 'super_admin' để quản lý toàn bộ
  final List<String> managedFields; // Danh sách tất cả ID sân
  final DateTime createdAt;
  final bool isActive;
  final String? phoneNumber;
  final String? address;

  Admin({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.managedFields,
    required this.createdAt,
    required this.isActive,
    this.phoneNumber,
    this.address,
  });

  // Convert model to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'managedFields': managedFields,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'phoneNumber': phoneNumber,
      'address': address,
    };
  }

  // Create model from Firestore document
  factory Admin.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Admin(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'field_manager',
      managedFields: List<String>.from(data['managedFields'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] as bool? ?? true,
      phoneNumber: data['phoneNumber'],
      address: data['address'],
    );
  }

  // Create model from a Map
  factory Admin.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return Admin(
        id: '',
        email: '',
        name: '',
        role: 'field_manager',
        managedFields: [],
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

    return Admin(
      id: data['id']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      role: data['role']?.toString() ?? 'field_manager',
      managedFields: List<String>.from(data['managedFields'] ?? []),
      createdAt: parseTimestamp(data['createdAt']).toDate(),
      isActive: data['isActive'] as bool? ?? true,
      phoneNumber: data['phoneNumber']?.toString(),
      address: data['address']?.toString(),
    );
  }

  Admin copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    List<String>? managedFields,
    DateTime? createdAt,
    bool? isActive,
    String? phoneNumber,
    String? address,
  }) {
    return Admin(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      managedFields: managedFields ?? this.managedFields,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
    );
  }
}