import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_mobile/firestore database/sport_fields.dart';

class FieldManagementScreen extends StatefulWidget {
  const FieldManagementScreen({super.key});

  @override
  State<FieldManagementScreen> createState() => _FieldManagementScreenState();
}

class _FieldManagementScreenState extends State<FieldManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<List<SportsField>> _futureFields;

  @override
  void initState() {
    super.initState();
    _futureFields = _fetchFields();
  }

  Future<List<SportsField>> _fetchFields() async {
    final snapshot = await _firestore.collection('sports_fields').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      double lat = 0;
      double lng = 0;
      if (data['location'] is GeoPoint) {
        lat = (data['location'] as GeoPoint).latitude;
        lng = (data['location'] as GeoPoint).longitude;
      } else if (data['location'] is List && data['location'].length == 2) {
        lat = (data['location'][0] as num).toDouble();
        lng = (data['location'][1] as num).toDouble();
      }
      return SportsField(
        id: doc.id,
        name: data['name'] ?? '',
        address: data['address'] ?? '',
        lat: lat,
        lng: lng,
        sportType: data['sportType'] ?? '',
        phone: data['phone'],
        openHours: data['openHours'],
        price: data['price'] != null ? (data['price'] as num).toDouble() : null,
        imageUrl: data['imageUrl'],
        distance:
            data['distance'] != null
                ? (data['distance'] as num).toDouble()
                : null,
        rating:
            data['rating'] != null ? (data['rating'] as num).toDouble() : null,
        reviewCount:
            data['reviewCount'] != null
                ? (data['reviewCount'] as num).toInt()
                : null,
      );
    }).toList();
  }

  void _refresh() {
    setState(() {
      _futureFields = _fetchFields();
    });
  }

  Future<void> _showFieldDialog({SportsField? field}) async {
    final formKey = GlobalKey<FormState>();
    String name = field?.name ?? '';
    String address = field?.address ?? '';
    String sportType = field?.sportType ?? '';
    String phone = field?.phone ?? '';
    String openHours = field?.openHours ?? '';
    String price = field?.price?.toString() ?? '';
    String imageUrl = field?.imageUrl ?? '';
    String lat = field != null ? field.lat.toString() : '';
    String lng = field != null ? field.lng.toString() : '';

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              field == null ? 'Thêm sân mới' : 'Sửa thông tin sân',
              style: const TextStyle(
                color: Color(0xFF4A90E2),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: name,
                      decoration: const InputDecoration(labelText: 'Tên sân'),
                      validator:
                          (v) =>
                              v == null || v.isEmpty
                                  ? 'Không được để trống'
                                  : null,
                      onSaved: (v) => name = v ?? '',
                      textCapitalization: TextCapitalization.words,
                    ),
                    TextFormField(
                      initialValue: address,
                      decoration: const InputDecoration(labelText: 'Địa chỉ'),
                      validator:
                          (v) =>
                              v == null || v.isEmpty
                                  ? 'Không được để trống'
                                  : null,
                      onSaved: (v) => address = v ?? '',
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    TextFormField(
                      initialValue: sportType,
                      decoration: const InputDecoration(labelText: 'Bộ môn'),
                      onSaved: (v) => sportType = v ?? '',
                      textCapitalization: TextCapitalization.words,
                    ),
                    TextFormField(
                      initialValue: phone,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                      ),
                      onSaved: (v) => phone = v ?? '',
                      keyboardType: TextInputType.phone,
                    ),
                    TextFormField(
                      initialValue: openHours,
                      decoration: const InputDecoration(
                        labelText: 'Giờ mở cửa',
                      ),
                      onSaved: (v) => openHours = v ?? '',
                    ),
                    TextFormField(
                      initialValue: price,
                      decoration: const InputDecoration(labelText: 'Giá'),
                      keyboardType: TextInputType.number,
                      onSaved: (v) => price = v ?? '',
                    ),
                    TextFormField(
                      initialValue: imageUrl,
                      decoration: const InputDecoration(labelText: 'Ảnh (URL)'),
                      onSaved: (v) => imageUrl = v ?? '',
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: TextFormField(
                            initialValue: lat,
                            decoration: const InputDecoration(
                              labelText: 'Vĩ độ',
                            ),
                            keyboardType: TextInputType.number,
                            onSaved: (v) => lat = v ?? '',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: TextFormField(
                            initialValue: lng,
                            decoration: const InputDecoration(
                              labelText: 'Kinh độ',
                            ),
                            keyboardType: TextInputType.number,
                            onSaved: (v) => lng = v ?? '',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    final data = {
                      'name': name,
                      'address': address,
                      'sportType': sportType,
                      'phone': phone,
                      'openHours': openHours,
                      'price': double.tryParse(price) ?? 0,
                      'imageUrl': imageUrl,
                      'location': GeoPoint(
                        double.tryParse(lat) ?? 0,
                        double.tryParse(lng) ?? 0,
                      ),
                      // Các trường mặc định khi thêm mới
                      'distance': field?.distance ?? 0,
                      'rating': field?.rating ?? 0,
                      'reviewCount': field?.reviewCount ?? 0,
                    };
                    if (field == null) {
                      // Thêm mặc định nếu là thêm mới
                      data['distance'] = 0;
                      data['rating'] = 0;
                      data['reviewCount'] = 0;
                      await _firestore.collection('sports_fields').add(data);
                    } else {
                      await _firestore
                          .collection('sports_fields')
                          .doc(field.id)
                          .update(data);
                    }
                    if (mounted) Navigator.pop(context);
                    _refresh();
                  }
                },
                child: Text(field == null ? 'Thêm' : 'Lưu'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteField(SportsField field) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xóa sân?'),
            content: const Text('Bạn có chắc muốn xóa sân này?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
    if (confirm == true) {
      await _firestore.collection('sports_fields').doc(field.id).delete();
      _refresh();
    }
  }

  Widget _buildFieldTile(SportsField field) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      child: ListTile(
        leading: const Icon(Icons.sports_soccer, color: Color(0xFF4A90E2)),
        title: Text(
          field.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Địa chỉ: ${field.address}'),
            Text('Bộ môn: ${field.sportType}'),
            Text('SĐT: ${field.phone ?? ""}'),
            Text('Giờ mở cửa: ${field.openHours ?? ""}'),
            Text('Giá: ${field.price?.toStringAsFixed(0) ?? ""} đ'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: () => _showFieldDialog(field: field),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteField(field),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Text(
                'Quản lý sân',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  letterSpacing: 1,
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<SportsField>>(
                future: _futureFields,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Lỗi: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'Không có sân nào',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  final fields = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    itemCount: fields.length,
                    itemBuilder:
                        (context, index) => _buildFieldTile(fields[index]),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF4A90E2),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text(
                  'Thêm sân',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => _showFieldDialog(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
