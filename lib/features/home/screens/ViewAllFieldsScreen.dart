import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:do_an_mobile/firestore database/sport_fields.dart'; // Import SportsField class

class ViewAllFieldsScreen extends StatelessWidget {
  final List<SportsField> sportsFields;

  const ViewAllFieldsScreen({super.key, required this.sportsFields});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tất cả sân thể thao'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: sportsFields.isEmpty
          ? const Center(
              child: Text(
                'Không tìm thấy sân thể thao nào',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sportsFields.length,
              itemBuilder: (context, index) {
                return _buildFieldCard(context, sportsFields[index]);
              },
            ),
    );
  }

  Widget _buildFieldCard(BuildContext context, SportsField field) {
    final FirebaseAuth _auth = FirebaseAuth.instance;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(
                  field.imageUrl ?? 'https://via.placeholder.com/400x200',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${field.price?.toStringAsFixed(0) ?? '100.000'} VND/giờ • ${field.distance?.toStringAsFixed(1) ?? 'N/A'} km',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${field.rating?.toStringAsFixed(1) ?? '4.8'} (${field.reviewCount ?? '120'})',
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_auth.currentUser == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng đăng nhập để đặt sân'),
                            ),
                          );
                          return;
                        }
                        _showFieldDetails(context, field);
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

  void _showFieldDetails(BuildContext context, SportsField field) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(field.address, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(
              'Loại sân: ${field.sportType}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Khoảng cách: ${field.distance?.toStringAsFixed(1) ?? 'N/A'} km',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${field.rating?.toStringAsFixed(1) ?? '4.8'} (${field.reviewCount ?? '120'})',
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to booking screen (adjust route as needed)
                    Navigator.pushNamed(
                      context,
                      '/booking',
                      arguments: {'field': field},
                    );
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
    );
  }
}