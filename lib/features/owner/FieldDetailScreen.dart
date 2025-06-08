import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_mobile/Firestore Database/sport_fields.dart';

class FieldDetailScreen extends StatefulWidget {
  final String fieldId;

  const FieldDetailScreen({Key? key, required this.fieldId}) : super(key: key);

  @override
  State<FieldDetailScreen> createState() => _FieldDetailScreenState();
}

class _FieldDetailScreenState extends State<FieldDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  bool _isLoading = true;

  late SportsField _currentField;

  @override
  void initState() {
    super.initState();
    _loadFieldDetails();
  }

  Future<void> _loadFieldDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('sports_fields')
          .doc(widget.fieldId)
          .get();

      if (doc.exists) {
        _currentField = SportsField.fromFirestore(doc);

        _nameController.text = _currentField.name;
        _locationController.text = '${_currentField.lat},${_currentField.lng}';
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> updateSportsField(SportsField field) async {
    try {
      await FirebaseFirestore.instance
          .collection('sports_fields')
          .doc(field.id)
          .update({
        'name': field.name,
        'address': field.address,
        'location': GeoPoint(field.lat, field.lng),
        'sportType': field.sportType,
        'imageUrl': field.imageUrl,
        'price': field.price,
        'distance': field.distance,
        'rating': field.rating,
        'reviewCount': field.reviewCount,
        'ownerId': field.ownerId,
        'phone': field.phone,
        'openHours': field.openHours,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật thành công cho sân: ${field.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật sân: $e')),
      );
    }
  }

  Future<void> _deleteField() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa sân này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('sports_fields')
            .doc(widget.fieldId)
            .delete();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa sân')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa: $e')),
        );
      }
    }
  }

  void _onSavePressed() {
    if (_formKey.currentState!.validate()) {
      // Parse location string thành lat, lng
      final locationText = _locationController.text.trim();
      final parts = locationText.split(',');
      if (parts.length != 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vị trí không đúng định dạng latitude,longitude')),
        );
        return;
      }

      final lat = double.tryParse(parts[0]);
      final lng = double.tryParse(parts[1]);
      if (lat == null || lng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vị trí phải là số hợp lệ')),
        );
        return;
      }

      // Tạo SportsField mới với dữ liệu cập nhật
      final updatedField = _currentField.copyWith(
        name: _nameController.text.trim(),
        lat: lat,
        lng: lng,
      );

      updateSportsField(updatedField);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết sân')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Tên sân'),
                      validator: (value) =>
                          value!.isEmpty ? 'Không được để trống' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                          labelText: 'Vị trí (latitude,longitude)'),
                      validator: (value) =>
                          value!.isEmpty ? 'Không được để trống' : null,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _onSavePressed,
                          child: const Text('Lưu'),
                        ),
                        ElevatedButton(
                          onPressed: _deleteField,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Xóa'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
