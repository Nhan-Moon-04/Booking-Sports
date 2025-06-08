import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:do_an_mobile/Firestore Database/sport_fields.dart'; // import model

class AddFieldScreen extends StatefulWidget {
  const AddFieldScreen({Key? key}) : super(key: key);

  @override
  State<AddFieldScreen> createState() => _AddFieldScreenState();
}

class _AddFieldScreenState extends State<AddFieldScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _locationController = TextEditingController(); // nhập dạng "lat,lng"
  final _sportTypeController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _openHoursController = TextEditingController();

  bool _isLoading = false;

  Future<void> _addField() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn chưa đăng nhập')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Parse lat,lng từ input
      final locationParts = _locationController.text.split(',');
      final lat = double.tryParse(locationParts[0].trim()) ?? 0.0;
      final lng = double.tryParse(locationParts[1].trim()) ?? 0.0;

      // Tạo object SportsField tạm
      final newField = SportsField(
        id: '', // id sẽ do Firestore cấp
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        lat: lat,
        lng: lng,
        sportType: _sportTypeController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        price: _priceController.text.isEmpty
            ? null
            : double.tryParse(_priceController.text.trim()),
        distance: null,
        rating: null,
        reviewCount: null,
        ownerId: user.uid,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        openHours: _openHoursController.text.trim().isEmpty
            ? null
            : _openHoursController.text.trim(),
      );

      // Thêm xuống Firestore
      await FirebaseFirestore.instance.collection('sports_fields').add({
        'name': newField.name,
        'address': newField.address,
        'location': GeoPoint(newField.lat, newField.lng),
        'sportType': newField.sportType,
        'imageUrl': newField.imageUrl,
        'price': newField.price,
        'distance': newField.distance,
        'rating': newField.rating,
        'reviewCount': newField.reviewCount,
        'ownerId': newField.ownerId,
        'phone': newField.phone,
        'openHours': newField.openHours,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm sân thành công!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi thêm sân: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _locationController.dispose();
    _sportTypeController.dispose();
    _imageUrlController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _openHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm sân mới')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Tên sân'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Nhập tên sân' : null,
                    ),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Địa chỉ'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Nhập địa chỉ' : null,
                    ),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                          labelText: 'Vị trí (latitude,longitude)'),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Nhập vị trí';
                        final parts = value.split(',');
                        if (parts.length != 2) return 'Vị trí không đúng định dạng';
                        if (double.tryParse(parts[0].trim()) == null ||
                            double.tryParse(parts[1].trim()) == null) {
                          return 'Vị trí phải là số hợp lệ';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _sportTypeController,
                      decoration:
                          const InputDecoration(labelText: 'Loại thể thao'),
                    ),
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(labelText: 'URL ảnh'),
                    ),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Giá (VNĐ)'),
                      keyboardType: TextInputType.number,
                    ),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Số điện thoại'),
                      keyboardType: TextInputType.phone,
                    ),
                    TextFormField(
                      controller: _openHoursController,
                      decoration:
                          const InputDecoration(labelText: 'Giờ mở cửa'),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _addField,
                      child: const Text('Thêm sân'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
