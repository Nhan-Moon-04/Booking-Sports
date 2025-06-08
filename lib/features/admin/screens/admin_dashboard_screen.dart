import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_mobile/firestore database/sport_fields.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<List<SportsField>> _futureFields;

  @override
  void initState() {
    super.initState();
    _futureFields = _fetchFields();
  }

  Future<List<SportsField>> _fetchFields() async {
    final snapshot = await _firestore.collection('sport_fields').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return SportsField(
        id: doc.id,
        name: data['name'] ?? '',
        address: data['address'] ?? '',
        lat: (data['lat'] ?? 0).toDouble(),
        lng: (data['lng'] ?? 0).toDouble(),
        sportType: data['sportType'] ?? '',
      );
    }).toList();
  }

  void _refresh() {
    setState(() {
      _futureFields = _fetchFields();
    });
  }

  void _editField(SportsField field) {
    // TODO: Thêm logic chỉnh sửa sân
  }

  void _deleteField(SportsField field) {
    // TODO: Thêm logic xóa sân
  }

  Widget _buildFieldTile(SportsField field) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.sports),
        title: Text(field.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Địa chỉ: ${field.address}'),
            Text('Loại sân: ${field.sportType}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editField(field),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteField(field),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng điều khiển Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<SportsField>>(
        future: _futureFields,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Lỗi tải dữ liệu'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có sân nào'));
          }

          final fields = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: fields.length,
            itemBuilder: (context, index) => _buildFieldTile(fields[index]),
          );
        },
      ),
    );
  }
}
