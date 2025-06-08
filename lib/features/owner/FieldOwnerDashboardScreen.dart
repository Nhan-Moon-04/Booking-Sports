import 'package:flutter/material.dart';

class FieldOwnerDashboardScreen extends StatelessWidget {
  const FieldOwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng điều khiển Chủ Sân'),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDashboardButton(
              context,
              title: 'Quản lý sân',
              icon: Icons.sports_soccer,
              onTap: () {
                Navigator.pushNamed(context, '/manage_fields');
              },
            ),
            const SizedBox(height: 16),
            _buildDashboardButton(
              context,
              title: 'Quản lý lịch đặt sân',
              icon: Icons.schedule,
              onTap: () {
                Navigator.pushNamed(context, '/manage_bookings');
              },
            ),
            const SizedBox(height: 16),
            _buildDashboardButton(
              context,
              title: 'Thống kê',
              icon: Icons.bar_chart,
              onTap: () {
                Navigator.pushNamed(context, '/statistics');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardButton(BuildContext context,
      {required String title,
      required IconData icon,
      required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 28),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18),
          ),
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
