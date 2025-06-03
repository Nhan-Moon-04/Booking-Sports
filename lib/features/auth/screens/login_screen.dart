import 'package:do_an_mobile/features/home/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:do_an_mobile/routes/app_routes.dart';

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
      debugPrint('Bắt đầu quá trình đăng nhập');

      await Future.delayed(const Duration(milliseconds: 50));

      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw FirebaseAuthException(
              code: 'timeout',
              message: 'Kết nối quá lâu. Vui lòng kiểm tra mạng',
            ),
          );

      debugPrint('Đăng nhập thành công! UserID: ${userCredential.user?.uid}');

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('LỖI FIREBASE: ${e.code} - ${e.message}');

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
      builder: (context) => AlertDialog(
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
                  // Logo hoặc tiêu đề
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

                  // Email Field
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        prefixIcon: const Icon(Icons.email, color: Colors.blue),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password Field
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                      ),
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Button
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
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Color(0xFF4A90E2),
                              ),
                            )
                          : const Text(
                              'Đăng nhập',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Register Button
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.pushNamed(context, AppRoutes.register),
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