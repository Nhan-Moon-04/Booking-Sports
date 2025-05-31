import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:do_an_mobile/routes/app_routes.dart';
import 'package:do_an_mobile/features/profile/screens/profile_screen.dart'; // Thêm import này

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const HomeContent(), // Widget chứa nội dung trang chủ
    const Center(child: Text('Lịch đặt')), // Placeholder
    const ProfileScreen(), // Màn hình profile đã tạo
  ];

  final List<Map<String, dynamic>> _sports = [
    {'name': 'Bóng đá', 'icon': Icons.sports_soccer, 'color': Colors.green},
    {'name': 'Cầu lông', 'icon': Icons.sports_tennis, 'color': Colors.blue},
    {'name': 'Tennis', 'icon': Icons.sports_tennis, 'color': Colors.orange},
    {'name': 'Bóng rổ', 'icon': Icons.sports_basketball, 'color': Colors.red},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0 
          ? AppBar(
              title: const Text('Đặt Sân Thể Thao'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.account_circle),
                  onPressed: () => setState(() => _currentIndex = 2),
                ),
              ],
            )
          : null,
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Lịch đặt',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}

// Tách nội dung trang chủ thành widget riêng
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(24),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sân...',
                border: InputBorder.none,
                icon: Icon(Icons.search),
              ),
            ),
          ),
          // ... (giữ nguyên các phần còn lại của trang chủ)
        ],
      ),
    );
  }

// Giữ nguyên hàm _buildFieldCard
  Widget _buildFieldCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: const DecorationImage(
                image: NetworkImage('https://via.placeholder.com/400x200'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sân bóng đá A1',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  '100.000 VND/giờ • 5km',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        SizedBox(width: 4),
                        Text('4.8 (120)'),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        AppRoutes.goTo(context, '/booking');
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text('Đặt ngay'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}