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
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _locationController;
  late TextEditingController _sportTypeController;
  late TextEditingController _priceController;
  late TextEditingController _phoneController;
  late TextEditingController _openHoursController;
  bool _isLoading = true;

  late SportsField _currentField;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _locationController = TextEditingController();
    _sportTypeController = TextEditingController();
    _priceController = TextEditingController();
    _phoneController = TextEditingController();
    _openHoursController = TextEditingController();
    _loadFieldDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _locationController.dispose();
    _sportTypeController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _openHoursController.dispose();
    super.dispose();
  }

  Future<void> _loadFieldDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('sports_fields')
          .doc(widget.fieldId)
          .get();

      if (doc.exists) {
        _currentField = SportsField.fromFirestore(doc);

        setState(() {
          _nameController.text = _currentField.name;
          _addressController.text = _currentField.address;
          _locationController.text = '${_currentField.lat},${_currentField.lng}';
          _sportTypeController.text = _currentField.sportType;
          _priceController.text = _currentField.price.toString();
          _phoneController.text = _currentField.phone.toString();
          _openHoursController.text = _currentField.openHours.toString();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy thông tin sân')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải thông tin sân: $e')),
      );
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
        SnackBar(
          content: Text('Đã cập nhật thông tin sân ${field.name}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi cập nhật: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteField() async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text(
        'Xác nhận xóa sân',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: const Text(
        'Bạn có chắc chắn muốn xóa sân này không? Hành động này không thể hoàn tác.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'Hủy',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Xóa',
            style: TextStyle(color: Colors.red),
          ),
        ),
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
        const SnackBar(
          content: Text('Đã xóa sân thành công'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi xóa: $e'),
          backgroundColor: Colors.red,
        ),
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
          const SnackBar(
            content: Text('Vị trí phải có định dạng: latitude,longitude'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final lat = double.tryParse(parts[0]);
      final lng = double.tryParse(parts[1]);
      if (lat == null || lng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vị trí phải là số hợp lệ'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final price = double.tryParse(_priceController.text) ?? 0.0;

      // Tạo SportsField mới với dữ liệu cập nhật
      final updatedField = _currentField.copyWith(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        lat: lat,
        lng: lng,
        sportType: _sportTypeController.text.trim(),
        price: price,
        phone: _phoneController.text.trim(),
        openHours: _openHoursController.text.trim(),
      );

      updateSportsField(updatedField);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi Tiết Sân',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteField,
            tooltip: 'Xóa sân',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hình ảnh sân
                    if (_currentField.imageUrl != null && _currentField.imageUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _currentField.imageUrl!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 180,
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 180,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.error_outline, size: 50),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.sports_soccer, size: 50, color: Colors.grey),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Form thông tin
                    _buildFormField(
                      controller: _nameController,
                      label: 'Tên sân',
                      icon: Icons.stadium,
                      validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên sân' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildFormField(
                      controller: _addressController,
                      label: 'Địa chỉ',
                      icon: Icons.location_on,
                      validator: (value) => value!.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildFormField(
                      controller: _locationController,
                      label: 'Tọa độ (lat,lng)',
                      icon: Icons.map,
                      validator: (value) => value!.isEmpty ? 'Vui lòng nhập tọa độ' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildFormField(
                      controller: _sportTypeController,
                      label: 'Loại sân',
                      icon: Icons.sports,
                      validator: (value) => value!.isEmpty ? 'Vui lòng nhập loại sân' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildFormField(
                      controller: _priceController,
                      label: 'Giá thuê (VNĐ)',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Vui lòng nhập giá thuê' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildFormField(
                      controller: _phoneController,
                      label: 'Số điện thoại',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) => value!.isEmpty ? 'Vui lòng nhập số điện thoại' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildFormField(
                      controller: _openHoursController,
                      label: 'Giờ mở cửa',
                      icon: Icons.access_time,
                      validator: (value) => value!.isEmpty ? 'Vui lòng nhập giờ mở cửa' : null,
                    ),
                    const SizedBox(height: 32),

                    // Nút lưu
                    ElevatedButton(
                      onPressed: _onSavePressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'LƯU THAY ĐỔI',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[800]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue[800]!),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16, horizontal: 16),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}