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
    // Validate input
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      throw FirebaseAuthException(
        code: 'empty-fields',
        message: 'Vui lòng nhập đầy đủ email và mật khẩu',
      );
    }

    setState(() => _isLoading = true);
    debugPrint('Bắt đầu quá trình đăng nhập');

    // Thêm delay để đảm bảo UI kịp cập nhật
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
    
    // Sử dụng rootNavigator để đảm bảo chuyển trang trong mọi trường hợp
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Đăng nhập'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            TextButton(
              onPressed: _isLoading 
                  ? null 
                  : () => Navigator.pushNamed(context, AppRoutes.register),
              child: const Text('Chưa có tài khoản? Đăng ký'),
            ),
          ],
        ),
      ),
    );
  }
}