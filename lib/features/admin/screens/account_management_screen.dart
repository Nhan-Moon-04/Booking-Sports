import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _addUserDialog() async {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String email = '';
    String role = 'player';

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Thêm người dùng'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Tên'),
                    validator:
                        (v) =>
                            v == null || v.isEmpty
                                ? 'Không được để trống'
                                : null,
                    onSaved: (v) => name = v ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator:
                        (v) =>
                            v == null || v.isEmpty
                                ? 'Không được để trống'
                                : null,
                    onSaved: (v) => email = v ?? '',
                  ),
                  DropdownButtonFormField<String>(
                    value: role,
                    items: const [
                      DropdownMenuItem(
                        value: 'player',
                        child: Text('Người chơi'),
                      ),
                      DropdownMenuItem(value: 'owner', child: Text('Chủ sân')),
                    ],
                    onChanged: (v) => role = v ?? 'player',
                    decoration: const InputDecoration(labelText: 'Vai trò'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    final doc = _firestore.collection('users').doc();
                    await doc.set({
                      'id': doc.id,
                      'name': name,
                      'email': email,
                      'role': role,
                      'isActive': true,
                    });
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: const Text('Thêm'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteUser(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xóa người dùng?'),
            content: const Text('Bạn có chắc muốn xóa người dùng này?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
    if (confirm == true) {
      await _firestore.collection('users').doc(userId).delete();
    }
  }

  Future<void> _toggleActiveUser(String userId, bool currentActive) async {
    await _firestore.collection('users').doc(userId).update({
      'isActive': !currentActive,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quản lý tài khoản',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      letterSpacing: 1,
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4A90E2),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'Thêm user',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _addUserDialog,
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Lỗi: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Không có user nào',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final userId = docs[index].id;
                      final isActive = data['isActive'] == true;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                        child: ListTile(
                          leading: Icon(
                            data['role'] == 'owner'
                                ? Icons.store
                                : Icons.person,
                            color:
                                data['role'] == 'owner'
                                    ? Colors.orange
                                    : Colors.blue,
                          ),
                          title: Text(
                            data['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Email: ${data['email'] ?? ''}'),
                              Text(
                                'Vai trò: ${data['role'] == 'owner' ? 'Chủ sân' : 'Người chơi'}',
                              ),
                              if (!isActive)
                                const Text(
                                  'Đã vô hiệu hóa',
                                  style: TextStyle(color: Colors.red),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isActive ? Icons.lock : Icons.lock_open,
                                  color: Colors.redAccent,
                                ),
                                tooltip:
                                    isActive
                                        ? 'Vô hiệu hóa user'
                                        : 'Mở khóa user',
                                onPressed:
                                    () => _toggleActiveUser(userId, isActive),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                tooltip: 'Xóa user',
                                onPressed: () => _deleteUser(userId),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
