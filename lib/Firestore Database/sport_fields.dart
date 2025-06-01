import 'package:flutter/material.dart';
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
    );
  }
}

class SportsFieldList extends StatefulWidget {
  @override
  _SportsFieldListState createState() => _SportsFieldListState();
}

class _SportsFieldListState extends State<SportsFieldList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<SportsField> fields = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSportsFields();
  }

  Future<void> fetchSportsFields() async {
    try {
      final snapshot = await _firestore.collection('SportsField').get();
      print('Tìm thấy ${snapshot.docs.length} document');
      final loadedFields = snapshot.docs.map((doc) => SportsField.fromFirestore(doc)).toList();

      setState(() {
        fields = loadedFields;
        isLoading = false;
      });
    } catch (e) {
      print('Lỗi khi lấy dữ liệu: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return Center(child: CircularProgressIndicator());

    if (fields.isEmpty) return Center(child: Text('Không có dữ liệu sân thể thao'));

    return ListView.builder(
      itemCount: fields.length,
      itemBuilder: (context, index) {
        final field = fields[index];
        return Card(
          margin: EdgeInsets.all(8),
          child: ListTile(
            title: Text(field.name),
            subtitle: Text(field.address),
            leading: field.imageUrl != null
                ? Image.network(field.imageUrl!, width: 60, height: 60, fit: BoxFit.cover)
                : SizedBox(width: 60, height: 60, child: Icon(Icons.sports_soccer)),
          ),
        );
      },
    );
  }
}
