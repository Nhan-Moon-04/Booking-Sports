import 'package:do_an_mobile/features/home/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_mobile/routes/app_routes.dart';
import 'package:do_an_mobile/features/admin/screens/admin_dashboard_screen.dart';
import 'package:do_an_mobile/features/owner/FieldOwnerDashboardScreen.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    try {
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        throw FirebaseAuthException(
          code: 'empty-fields',
          message: 'Vui lòng nhập đầy đủ email và mật khẩu',
        );
      }

      setState(() => _isLoading = true);
      debugPrint(
        'Bắt đầu quá trình đăng nhập với email: ${_emailController.text.trim()}',
      );

      await Future.delayed(const Duration(milliseconds: 50));

      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout:
                () =>
                    throw FirebaseAuthException(
                      code: 'timeout',
                      message: 'Kết nối quá lâu. Vui lòng kiểm tra mạng',
                    ),
          );

      final userId = userCredential.user?.uid;
      debugPrint('Đăng nhập thành công! UserID: $userId');

      // Kiểm tra vai trò admin trong Firestore với debug
      final adminDoc =
          await FirebaseFirestore.instance
              .collection('admins')
              .doc(userId)
              .get();

      debugPrint(
        'Kiểm tra admin: Document exists: ${adminDoc.exists}, Data: ${adminDoc.data()}',
      );

      if (!mounted) return;

      if (adminDoc.exists) {
        final role = adminDoc.data()?['role'];

        switch (role) {
          case 'super_admin':
            debugPrint('Điều hướng đến AdminDashboardScreen cho UID: $userId');
            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              (route) => false,
            );
            break;

          case 'field_manager':
            debugPrint(
              'Điều hướng đến FieldOwnerDashboardScreen cho UID: $userId',
            );
            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const FieldOwnerDashboardScreen(),
              ),
              (route) => false,
            );
            break;

          default:
            debugPrint(
              'Điều hướng đến HomeScreen (user thường) cho UID: $userId',
            );
            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
        }
      } else {
        debugPrint(
          'Không tìm thấy thông tin người dùng, điều hướng đến HomeScreen',
        );
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'LỖI FIREBASE CHI TIẾT: ${e.code} - ${e.message} - ${e.stackTrace?.toString()}',
      );

      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'Email không hợp lệ';
          break;
        case 'user-disabled':
          errorMessage = 'Tài khoản đã bị vô hiệu hóa';
          break;
        case 'user-not-found':
          errorMessage = 'Không tìm thấy tài khoản';
          break;
        case 'wrong-password':
          errorMessage = 'Sai mật khẩu';
          break;
        case 'invalid-credential':
          errorMessage = 'Thông tin đăng nhập không hợp lệ hoặc đã hết hạn';
          break;
        case 'network-request-failed':
          errorMessage = 'Lỗi kết nối mạng';
          break;
        default:
          errorMessage = 'Đăng nhập thất bại: ${e.message}';
      }

      if (!mounted) return;
      _showErrorDialog(context, errorMessage);
    } catch (e) {
      debugPrint('LỖI KHÔNG XÁC ĐỊNH: $e');
      if (!mounted) return;
      _showErrorDialog(context, 'Lỗi hệ thống: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Lỗi đăng nhập'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.sports_tennis,
                    size: 100,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Đăng Nhập',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(2.0, 2.0),
                          blurRadius: 4.0,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        prefixIcon: const Icon(Icons.email, color: Colors.blue),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                      ),
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4A90E2),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Color(0xFF4A90E2),
                                ),
                              )
                              : const Text(
                                'Đăng nhập',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed:
                        _isLoading
                            ? null
                            : () => Navigator.pushNamed(
                              context,
                              AppRoutes.register,
                            ),
                    child: const Text(
                      'Chưa có tài khoản? Đăng ký',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
