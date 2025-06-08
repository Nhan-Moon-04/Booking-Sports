import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_mobile/features/owner/FieldDetailScreen.dart';
import 'package:do_an_mobile/features/owner/AddFieldScreen.dart';

class ManageFieldsScreen extends StatelessWidget {
  const ManageFieldsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Chưa đăng nhập')));
    }

    final fieldsRef = FirebaseFirestore.instance
        .collection('sports_fields')
        .where('ownerId', isEqualTo: currentUser.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sân'),
        backgroundColor: Colors.green[700],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: fieldsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Lỗi khi tải dữ liệu.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final fields = snapshot.data!.docs;

          if (fields.isEmpty) {
            return const Center(child: Text('Bạn chưa có sân nào.'));
          }

          return ListView.builder(
            itemCount: fields.length,
            itemBuilder: (context, index) {
              final field = fields[index];
              final data = field.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading:
                      data['imageUrl'] != null
                          ? Image.network(
                            data['imageUrl'],
                            width: 60,
                            fit: BoxFit.cover,
                          )
                          : const Icon(Icons.image, size: 60),
                  title: Text(data['name'] ?? 'Không có tên'),
                  subtitle: Text(data['address'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => FieldDetailScreen(fieldId: field.id),
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => FieldDetailScreen(fieldId: field.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddFieldScreen()),
          );
        },
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add),
      ),
    );
  }
}
