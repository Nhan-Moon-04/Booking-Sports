import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_mobile/routes/app_routes.dart';
import 'package:do_an_mobile/features/home/screens/home_screen.dart';
import 'package:do_an_mobile/features/content/owner_registration.dart';
import 'package:do_an_mobile/features/content/referral_screen.dart';
import 'package:do_an_mobile/features/content/introduction.dart';
import 'package:do_an_mobile/features/owner/FieldOwnerDashboardScreen.dart';

class ProfileUserScreen extends StatefulWidget {
  const ProfileUserScreen({super.key});

  @override
  State<ProfileUserScreen> createState() => _ProfileUserScreenState();
}

class _ProfileUserScreenState extends State<ProfileUserScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  late DocumentReference _userRef;
  bool _isLoading = true;
  Map<String, dynamic> _userData = {'name': '', 'avatarUrl': null};

  @override
  void initState() {
    super.initState();
    if (_user != null) {
      _userRef = FirebaseFirestore.instance.collection('users').doc(_user!.uid);
      _loadUserData();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserData({int retryCount = 0}) async {
    try {
      final doc = await _userRef.get();

      if (doc.exists) {
        setState(() {
          _userData = doc.data() as Map<String, dynamic>;
          _userData['name'] ??= '';
          _userData['avatarUrl'] ??= '';
        });
      } else {
        await _userRef.set({
          'name': '',
          'avatarUrl': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
        setState(() {
          _userData = {'name': '', 'avatarUrl': ''};
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
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  Future<void> _handleOwnerRegistration() async {
    if (_user == null) {
      debugPrint('Không có người dùng đăng nhập');
      return;
    }

    final userId = _user!.uid;
    debugPrint('Kiểm tra tài khoản với UID: $userId');

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final isOwner = userData['isOwner'] as bool? ?? false;
        debugPrint('Giá trị isOwner: $isOwner');

        if (isOwner) {
          if (!mounted) return;
          debugPrint('Điều hướng đến FieldOwnerDashboardScreen');
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FieldOwnerDashboardScreen()),
          );
        } else {
          if (!mounted) return;
          debugPrint('Điều hướng đến OwnerRegistrationScreen');
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => OwnerRegistrationScreen()),
          );
        }
      } else {
        debugPrint('Document không tồn tại cho UID: $userId');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy thông tin người dùng!')),
        );
      }
    } catch (e) {
      debugPrint('Lỗi khi truy vấn Firestore: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4A90E2)),
      );
    }

    if (_user == null) {
      return const Center(
        child: Text(
          'Vui lòng đăng nhập để xem thông tin',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    final avatarUrl = _userData['avatarUrl'] as String? ?? '';
    final userName =
        _userData['name'].isNotEmpty ? _userData['name'] : 'Người dùng';
    final userEmail = _user?.email ?? 'Chưa có thông tin';

    return Scaffold(
      body: Container(
        color: Colors.grey[200],
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HomeScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.profile);
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.pink[100],
                            backgroundImage:
                                avatarUrl.isNotEmpty
                                    ? NetworkImage(avatarUrl)
                                    : null,
                            child:
                                avatarUrl.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        size: 24,
                                        color: Colors.white,
                                      )
                                    : null,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                userEmail,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.power_settings_new,
                        color: Colors.pink,
                      ),
                      onPressed: _signOut,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    _buildMenuItem('Giới thiệu bạn bè & nhận quà', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => IntroductionScreen(),
                        ),
                      );
                    }),
                    _buildMenuItem('Ưu đãi', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReferralScreen(),
                        ),
                      );
                    }),
                    _buildMenuItem('Điều khoản và điều kiện', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => IntroductionScreen(),
                        ),
                      );
                    }),
                    _buildMenuItem('Vé chúc tồi', () {}),
                    _buildMenuItem('Đăng ký làm chủ sân', _handleOwnerRegistration),
                    _buildMenuItem('Đăng xuất', _signOut),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}