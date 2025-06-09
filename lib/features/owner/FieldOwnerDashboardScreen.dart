import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_mobile/routes/app_routes.dart';

class FieldOwnerDashboardScreen extends StatefulWidget {
  const FieldOwnerDashboardScreen({super.key});

  @override
  State<FieldOwnerDashboardScreen> createState() =>
      _FieldOwnerDashboardScreenState();
}

class _FieldOwnerDashboardScreenState extends State<FieldOwnerDashboardScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> _ownedFields = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (_user != null) {
      _loadOwnedFields();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadOwnedFields() async {
    try {
      final userId = _user!.uid;
      final querySnapshot = await _firestore
          .collection('sports_fields')
          .where('ownerId', isEqualTo: userId)
          .get();

      final fieldNames =
          querySnapshot.docs.map((doc) => doc['name'] as String).toList();

      setState(() {
        _ownedFields = fieldNames;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải danh sách sân: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Trang chủ Chủ Sân',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header với thông tin chào mừng
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_circle,
                            size: 50, color: Colors.white),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xin chào, ${_user?.displayName ?? 'Quản lý'}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Quản lý ${_ownedFields.length} sân thể thao',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Danh sách sân dưới dạng card ngang
                  if (_ownedFields.isNotEmpty) ...[
                    const Text(
                      'Danh sách sân của bạn',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _ownedFields.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 160,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.sports_soccer,
                                      size: 30, color: Colors.blue[800]),
                                  const SizedBox(height: 8),
                                  Text(
                                    _ownedFields[index],
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[800]),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Các chức năng chính dưới dạng grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _buildFeatureCard(
                        context,
                        icon: Icons.sports_soccer,
                        title: 'Quản lý sân',
                        color: Colors.blue[600]!,
                        onTap: () {
                          if (_ownedFields.isNotEmpty) {
                            Navigator.pushNamed(
                                context, AppRoutes.manage_fields);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Bạn chưa sở hữu sân nào!'),
                              ),
                            );
                          }
                        },
                      ),
                      _buildFeatureCard(
                        context,
                        icon: Icons.schedule,
                        title: 'Lịch đặt sân',
                        color: Colors.green[600]!,
                        onTap: () {
                          if (_ownedFields.isNotEmpty) {
                            Navigator.pushNamed(
                                context, AppRoutes.manage_bookings);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Bạn chưa sở hữu sân nào!'),
                              ),
                            );
                          }
                        },
                      ),
                      _buildFeatureCard(
                        context,
                        icon: Icons.bar_chart,
                        title: 'Thống kê',
                        color: Colors.orange[600]!,
                        onTap: () {
                          if (_ownedFields.isNotEmpty) {
                            Navigator.pushNamed(context, AppRoutes.statistics);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Bạn chưa sở hữu sân nào!'),
                              ),
                            );
                          }
                        },
                      ),
                      _buildFeatureCard(
                        context,
                        icon: Icons.settings,
                        title: 'Cài đặt',
                        color: Colors.purple[600]!,
                        onTap: () {
                          // Thêm chức năng cài đặt nếu cần
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}