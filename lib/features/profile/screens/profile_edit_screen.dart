import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = false;
  File? _avatarImage;
  String? _avatarUrl;
  UploadTask? _uploadTask;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _nameController.text = doc['name'] ?? '';
          _phoneController.text = doc['phone'] ?? '';
          _addressController.text = doc['address'] ?? '';
          _avatarUrl = doc['avatarUrl'];
        });
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Lỗi khi tải dữ liệu: ${e.toString()}');
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );

    if (pickedFile != null) {
      setState(() {
        _avatarImage = File(pickedFile.path);
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Bạn chưa đăng nhập!');
      return;
    }

    if (_avatarImage == null) {
      _showMessage('Bạn chưa chọn ảnh để upload!');
      return;
    }

    final fileExists = await _avatarImage!.exists();
    if (!fileExists) {
      _showMessage('File ảnh không tồn tại hoặc không thể đọc được.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_$timestamp.jpg';

      final ref = FirebaseStorage.instance
          .ref()
          .child('users/${user.uid}/profile_images/$fileName');
      debugPrint('Upload path: ${ref.fullPath}');

      _uploadTask = ref.putFile(
        _avatarImage!,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'uploadedBy': user.uid},
        ),
      );

      final snapshot = await _uploadTask!.whenComplete(() => null);

      if (snapshot.state == TaskState.success) {
        final url = await ref.getDownloadURL();
        debugPrint('Download URL: $url');

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'avatarUrl': url,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        setState(() => _avatarUrl = url);
        _showMessage('Cập nhật ảnh đại diện thành công!');
      } else {
        _showMessage('Upload ảnh thất bại. Vui lòng thử lại.');
        debugPrint('UploadTask không thành công, trạng thái: ${snapshot.state}');
      }
    } on FirebaseException catch (e, stack) {
      debugPrint('FirebaseException code: ${e.code}');
      debugPrint('FirebaseException message: ${e.message}');
      debugPrint('Stack trace: $stack');

      if (e.code == 'object-not-found') {
        _showMessage('Lỗi: Không tìm thấy đường dẫn lưu trữ. Vui lòng thử lại.');
      } else if (e.code == 'permission-denied') {
        _showMessage(
            'Lỗi: Không có quyền truy cập lưu trữ. Kiểm tra rules Firebase Storage.');
      } else {
        _showMessage('Lỗi Firebase: ${e.message}');
      }
    } catch (e) {
      debugPrint('Lỗi không xác định: ${e.toString()}');
      _showMessage('Lỗi không xác định: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Vui lòng đăng nhập để cập nhật thông tin');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showMessage('Cập nhật thành công!');
        Navigator.pop(context, true); // Trả về true để thông báo cập nhật thành công
      }
    } catch (e) {
      _showMessage('Lỗi: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: message.contains('thành công') ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _isLoading ? null : _pickImage,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[300],
              backgroundImage: _avatarImage != null
                  ? FileImage(_avatarImage!)
                  : (_avatarUrl != null && _avatarUrl!.isNotEmpty
                      ? NetworkImage(_avatarUrl!)
                      : null) as ImageProvider?,
              child: _avatarImage == null && (_avatarUrl == null || _avatarUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 60, color: Colors.white)
                  : null,
            ),
          ),
          if (!_isLoading)
            const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: Icon(Icons.edit, size: 22, color: Color(0xFF4A90E2)),
            ),
          if (_isLoading && _uploadTask != null)
            StreamBuilder<TaskSnapshot>(
              stream: _uploadTask!.snapshotEvents,
              builder: (context, snapshot) {
                double progress = 0;
                if (snapshot.hasData) {
                  final data = snapshot.data!;
                  progress = data.bytesTransferred / data.totalBytes;
                }
                return Positioned.fill(
                  child: CircularProgressIndicator(
                    value: progress,
                    color: const Color(0xFF4A90E2),
                    backgroundColor: Colors.black26,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    String? Function(String?) validator, {
    TextInputType? inputType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: TextFormField(
          controller: controller,
          keyboardType: inputType,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.grey),
            border: InputBorder.none,
            prefixIcon: Icon(icon, color: const Color.fromARGB(255, 240, 87, 194)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: validator,
          style: const TextStyle(color: Colors.black87),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa thông tin', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _isLoading ? null : _updateProfile,
            tooltip: 'Lưu thông tin',
          ),
        ],
        backgroundColor: const Color(0xFF4A90E2),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Center(child: _buildAvatar()),
                const SizedBox(height: 30),
                _buildTextField(
                  _nameController,
                  'Họ và tên',
                  Icons.person,
                  (value) =>
                      value == null || value.isEmpty ? 'Vui lòng nhập họ tên' : null,
                ),
                _buildTextField(
                  _phoneController,
                  'Số điện thoại',
                  Icons.phone,
                  (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập số điện thoại';
                    }
                    if (!RegExp(r'^(0|\+84)[0-9]{9,10}$').hasMatch(value)) {
                      return 'Số điện thoại không hợp lệ';
                    }
                    return null;
                  },
                  inputType: TextInputType.phone,
                ),
                _buildTextField(
                  _addressController,
                  'Địa chỉ',
                  Icons.location_on,
                  (value) =>
                      value == null || value.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
                  maxLines: 2,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4A90E2),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 6,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Color(0xFF4A90E2),
                            ),
                          )
                        : const Text(
                            'LƯU THÔNG TIN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _uploadTask?.cancel();
    super.dispose();
  }
}