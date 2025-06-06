import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'filter_screens.dart';
import 'package:do_an_mobile/features/booking/booking_screen.dart';
import 'package:do_an_mobile/firestore database/sport_fields.dart';
import 'package:do_an_mobile/features/booking_schedule/booking_schedule_screen.dart';

class nav_screens extends StatefulWidget {
  const nav_screens({super.key});

  @override
  State<nav_screens> createState() => _nav_screensState();
}

class _nav_screensState extends State<nav_screens> {
  String searchText = '';
  Map<String, dynamic> filters = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách cụm sân'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Khung tìm kiếm và icon bộ lọc
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchText = value.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm sân...',
                      prefixIcon: const Icon(Icons.search),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_alt_outlined, size: 28),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FilterScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('sports_fields')
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Không có dữ liệu'));
                }
                String removeDiacritics(String str) {
                  // Chuyển tiếng Việt có dấu thành không dấu
                  const withDiacritics =
                      'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ'
                      'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
                  const withoutDiacritics =
                      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
                      'AAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';
                  for (int i = 0; i < withDiacritics.length; i++) {
                    str = str.replaceAll(
                      withDiacritics[i],
                      withoutDiacritics[i],
                    );
                  }
                  return str;
                }

                // Lọc dữ liệu theo searchText (tên, địa chỉ, loại môn thể thao, không phân biệt dấu)
                final filteredDocs =
                    snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = removeDiacritics(
                        (data['name'] ?? '').toString().toLowerCase(),
                      );
                      final address = removeDiacritics(
                        (data['address'] ?? '').toString().toLowerCase(),
                      );
                      final sportType = removeDiacritics(
                        (data['sportType'] ?? '').toString().toLowerCase(),
                      );
                      final search = removeDiacritics(searchText.toLowerCase());
                      return name.contains(search) ||
                          address.contains(search) ||
                          sportType.contains(search);
                    }).toList();
                // ...existing code...
                return ListView(
                  padding: const EdgeInsets.all(12),
                  children:
                      filteredDocs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final field = SportsField.fromFirestore(doc);
                        return GestureDetector(
                          onTap: () {
                            _showFieldDetails(context, field);
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Ảnh đại diện sân
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      data['imageUrl'] ??
                                          'https://via.placeholder.com/80',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                width: 60,
                                                height: 60,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.sports,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Thông tin sân
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['name'] ?? 'Không tên',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          data['address'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${(data['rating'] ?? 0).toStringAsFixed(1)}/5',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '(${data['reviewCount'] ?? 0})',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  BookingScreen(field: field),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE84C88),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Đặt Ngay'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFieldDetails(BuildContext context, SportsField field) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ảnh bìa
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: Image.network(
                          field.imageUrl ??
                              'https://via.placeholder.com/400x180',
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tên sân và số sao
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    field.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${field.rating?.toStringAsFixed(1) ?? '0.0'}/5',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '(${field.reviewCount ?? 0})',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Số điện thoại
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone_android,
                                  size: 18,
                                  color: Colors.pink,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '',
                                  /* field.phone ?? 'Chưa có số điện thoại',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),*/
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Tabs
                            DefaultTabController(
                              length: 3,
                              child: Column(
                                children: [
                                  TabBar(
                                    labelColor: Colors.pink,
                                    unselectedLabelColor: Colors.black54,
                                    indicatorColor: Colors.pink,
                                    tabs: const [
                                      Tab(text: 'Thông Tin'),
                                      Tab(text: 'Bảng giá'),
                                      Tab(text: 'Thư Viện Ảnh'),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 320,
                                    child: TabBarView(
                                      children: [
                                        // Tab Thông Tin
                                        SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Ưu đãi (nếu có)
                                              const SizedBox(height: 12),
                                              const Text(
                                                'Ưu đãi cho bạn',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[100],
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.pink[100],
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: const Text(
                                                        'FREE',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.pink,
                                                          fontSize: 18,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    const Expanded(
                                                      child: Text(
                                                        'Đặt sân miễn phí\nÁp dụng cho hóa đơn tối đa 1,000,000 VND',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              // Địa chỉ
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.location_on,
                                                    color: Colors.pink,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      field.address,
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              // Giờ hoạt động
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.access_time,
                                                    color: Colors.pink,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    /*field.openHours ??*/
                                                    'Chưa có',
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              // Bộ môn
                                              Row(
                                                children: [
                                                  const Text(
                                                    'Bộ môn:',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text('✓ ${field.sportType}'),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              // Dịch vụ
                                              const Text(
                                                'Dịch vụ:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                /*field.services ??*/
                                                'Chưa có thông tin',
                                              ),
                                              const SizedBox(height: 8),
                                              // Mô tả
                                              const Text(
                                                'Mô Tả',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                '',
                                                /*doi goi databassedatabasse*/
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Tab Bảng giá
                                        Center(
                                          child: Text(
                                            'Bảng giá đang cập nhật...',
                                          ),
                                        ),
                                        // Tab Thư viện ảnh
                                        Center(
                                          child: Text(
                                            'Thư viện ảnh đang cập nhật...',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Đánh giá
                            const Text(
                              'Đánh giá',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),

                            const SizedBox(height: 16),
                            // Nút đặt lịch
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              BookingScreen(field: field),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE84C88),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: const Text('ĐẶT LỊCH'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }
}
