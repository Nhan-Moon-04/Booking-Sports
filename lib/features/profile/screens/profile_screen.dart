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
          'avatarUrl': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (retryCount < 3) {
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
    if (!mounted) return;
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
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: Icon(icon, color: Colors.blue, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        subtitle: Text(
          value.isEmpty ? 'Chưa cập nhật' : value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
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
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4A90E2)));
    }

    final avatarUrl = _userData['avatarUrl'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              try {
                final result = await Navigator.of(context)
                    .pushNamed(AppRoutes.profileEdit, arguments: _userData);
                if (result == true) {
                  await _loadUserData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cập nhật thành công'),
                        backgroundColor: Color(0xFF4A90E2),
                      ),
                    );
                  }
                }
              } catch (e) {
                debugPrint('Lỗi navigation: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Không thể mở trang chỉnh sửa: $e')),
                  );
                }
              }
            },
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
          child: Column(
            children: [
              const SizedBox(height: 20),
              Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  child: CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? const Icon(Icons.person, size: 60, color: Colors.white)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 30),
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
                  value: _formatDate((_userData['createdAt'] as Timestamp).toDate()),
                ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    'ĐĂNG XUẤT',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 6,
                  ),
                  onPressed: _signOut,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}