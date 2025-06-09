import 'package:do_an_mobile/features/home/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_mobile/routes/app_routes.dart';
import 'package:do_an_mobile/features/admin/screens/admin_dashboard_screen.dart';
import 'package:do_an_mobile/features/owner/FieldOwnerDashboardScreen.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  // Hàm đăng nhập bằng email và mật khẩu
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

      await _handleUserNavigation(userCredential.user);
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      debugPrint('LỖI KHÔNG XÁC ĐỊNH: $e');
      if (!mounted) return;
      _showErrorDialog(context, 'Lỗi hệ thống: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Hàm đăng nhập bằng Google
  Future<void> _signInWithGoogle() async {
    try {
      setState(() => _isGoogleLoading = true);
      debugPrint('Bắt đầu đăng nhập bằng Google');

      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('Người dùng hủy đăng nhập Google');
        return; // Người dùng hủy đăng nhập
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw FirebaseAuthException(
              code: 'timeout',
              message: 'Kết nối quá lâu. Vui lòng kiểm tra mạng',
            ),
          );

      final user = userCredential.user;
      if (user != null) {
        // Lưu thông tin người dùng vào Firestore nếu là lần đầu
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'email': user.email,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
            'createdAt': Timestamp.now(),
            'role': 'user', // Mặc định là user thường
          });
          debugPrint('Lưu thông tin người dùng mới: ${user.uid}');
        }

        await _handleUserNavigation(user);
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      debugPrint('LỖI GOOGLE SIGN-IN: $e');
      if (!mounted) return;
      _showErrorDialog(context, 'Lỗi đăng nhập Google: $e');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  // Hàm xử lý điều hướng dựa trên vai trò người dùng
  Future<void> _handleUserNavigation(User? user) async {
    if (user == null) {
      debugPrint('Không có người dùng, hủy điều hướng');
      return;
    }

    final userId = user.uid;
    debugPrint('Đăng nhập thành công! UserID: $userId');

    final adminDoc = await FirebaseFirestore.instance
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
          debugPrint('Điều hướng đến FieldOwnerDashboardScreen cho UID: $userId');
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const FieldOwnerDashboardScreen()),
            (route) => false,
          );
          break;

        default:
          debugPrint('Điều hướng đến HomeScreen (user thường) cho UID: $userId');
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
      }
    } else {
      debugPrint('Không tìm thấy thông tin admin, điều hướng đến HomeScreen');
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  // Hàm xử lý lỗi Firebase Authentication
  void _handleAuthError(FirebaseAuthException e) {
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
      case 'timeout':
        errorMessage = 'Kết nối quá lâu. Vui lòng kiểm tra mạng';
        break;
      default:
        errorMessage = 'Đăng nhập thất bại: ${e.message}';
    }

    if (!mounted) return;
    _showErrorDialog(context, errorMessage);
  }

  // Hàm gửi email đặt lại mật khẩu
  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showErrorDialog(context, 'Vui lòng nhập email để đặt lại mật khẩu');
      return;
    }

    try {
      setState(() => _isLoading = true);
      debugPrint('Gửi email đặt lại mật khẩu cho: $email');

      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: email)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw FirebaseAuthException(
              code: 'timeout',
              message: 'Kết nối quá lâu. Vui lòng kiểm tra mạng',
            ),
          );

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Thành công'),
          content: Text('Email đặt lại mật khẩu đã được gửi đến $email'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      debugPrint('LỖI GỬI EMAIL ĐẶT LẠI MẬT KHẨU: $e');
      if (!mounted) return;
      _showErrorDialog(context, 'Lỗi hệ thống: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Hàm hiển thị dialog lỗi
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi'),
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
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading || _isGoogleLoading ? null : _resetPassword,
                      child: const Text(
                        'Quên mật khẩu?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading || _isGoogleLoading ? null : _login,
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
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading || _isGoogleLoading ? null : _signInWithGoogle,
                      icon: _isGoogleLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : Image.asset(
                              'assets/images/google_logo.jpg',
                              height: 24,
                            ),
                      label: const Text(
                        'Đăng nhập bằng Google',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading || _isGoogleLoading
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