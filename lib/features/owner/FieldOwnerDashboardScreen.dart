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
      final querySnapshot =
          await _firestore
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi tải danh sách sân: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng điều khiển Chủ Sân'),
        backgroundColor: Colors.green[700],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.green),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_ownedFields.isNotEmpty)
                      Text(
                        'Sân của bạn (${_ownedFields.length}):',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (_ownedFields.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _ownedFields.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                label: Text(_ownedFields[index]),
                                backgroundColor: Colors.green[100],
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    _buildDashboardButton(
                      context,
                      title: 'Quản lý sân',
                      icon: Icons.sports_soccer,
                      onTap: () {
                        if (_ownedFields.isNotEmpty) {
                          Navigator.pushNamed(context, AppRoutes.manage_fields);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bạn chưa sở hữu sân nào!'),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDashboardButton(
                      context,
                      title: 'Quản lý lịch đặt sân',
                      icon: Icons.schedule,
                      onTap: () {
                        if (_ownedFields.isNotEmpty) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.manage_bookings,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bạn chưa sở hữu sân nào!'),
                            ),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 16),
                    _buildDashboardButton(
                      context,
                      title: 'Thống kê',
                      icon: Icons.bar_chart,
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
                  ],
                ),
              ),
    );
  }

  Widget _buildDashboardButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 28),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(title, style: const TextStyle(fontSize: 18)),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
      ),
    );
  }
}
