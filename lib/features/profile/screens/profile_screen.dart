import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_mobile/routes/app_routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  late DocumentReference _userRef;
  bool _isLoading = true;
  Map<String, dynamic> _userData = {
    'name': '',
    'phone': '',
    'address': '',
    'avatarUrl': null,
  };

  @override
  void initState() {
    super.initState();
    _userRef = FirebaseFirestore.instance.collection('users').doc(_user?.uid);
    _loadUserData();
  }

  Future<void> _loadUserData({int retryCount = 0}) async {
    try {
      final doc = await _userRef.get();

      if (doc.exists) {
        setState(() {
          _userData = doc.data() as Map<String, dynamic>;
        });
      } else {
        await _userRef.set({
          'name': '',
          'phone': '',
          'address': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (retryCount < 3) {
        // Tự động retry sau 2 giây
        await Future.delayed(const Duration(seconds: 2));
        await _loadUserData(retryCount: retryCount + 1);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Không thể kết nối đến server'),
              action: SnackBarAction(
                label: 'Thử lại',
                onPressed: () => _loadUserData(),
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        subtitle: Text(
          value.isEmpty ? 'Chưa cập nhật' : value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    return date != null
        ? '${date.day}/${date.month}/${date.year}'
        : '--/--/----';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              try {
                final result = await Navigator.of(
                  context,
                ).pushNamed(AppRoutes.profileEdit, arguments: _userData);

                if (result == true) {
                  await _loadUserData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cập nhật thành công')),
                  );
                }
              } catch (e) {
                debugPrint('Lỗi navigation: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Không thể mở trang chỉnh sửa: $e')),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[200],
              backgroundImage:
                  _userData['avatarUrl'] != null
                      ? NetworkImage(_userData['avatarUrl']!)
                      : null,
              child:
                  _userData['avatarUrl'] == null
                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
            ),
            const SizedBox(height: 20),

            _buildInfoTile(
              icon: Icons.email,
              title: 'Email',
              value: _user?.email ?? 'Chưa có thông tin',
            ),

            _buildInfoTile(
              icon: Icons.person,
              title: 'Họ và tên',
              value: _userData['name'] ?? '',
            ),

            _buildInfoTile(
              icon: Icons.phone,
              title: 'Số điện thoại',
              value: _userData['phone'] ?? '',
            ),

            _buildInfoTile(
              icon: Icons.location_on,
              title: 'Địa chỉ',
              value: _userData['address'] ?? '',
            ),

            if (_userData['createdAt'] != null)
              _buildInfoTile(
                icon: Icons.calendar_today,
                title: 'Ngày tham gia',
                value: _formatDate(
                  (_userData['createdAt'] as Timestamp).toDate(),
                ),
              ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('ĐĂNG XUẤT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _signOut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
