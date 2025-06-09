import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:do_an_mobile/firestore database/sport_fields.dart';
import 'package:do_an_mobile/routes/app_routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:do_an_mobile/features/booking_schedule/booking_schedule_screen.dart';
import 'package:do_an_mobile/features/navbar/nav_screens.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:do_an_mobile/features/profile/profile_user/profile_user.dart';
import 'package:do_an_mobile/features/Notification/payment_success_screen.dart';
import 'package:do_an_mobile/Firestore Database/booking.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isSearching = false; // Thêm biến trạng thái cho tìm kiếm
  final TextEditingController _searchController = TextEditingController();
  final List<Widget> _screens = [
    HomeContent(),
    BookingScheduleScreen(),
    ProfileUserScreen(),
    NotificationPage()
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0
          ? AppBar(
              leading: _isSearching
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        setState(() {
                          _isSearching = false;
                          _searchController.clear();
                        });
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => nav_screens()),
                        );
                      },
                    ),
              title: _isSearching
                  ? AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(10),
                          prefixIcon: Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                            },
                          ),
                        ),
                      ),
                    )
                  : null,
              actions: _isSearching
                  ? []
                  : [
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          setState(() {
                            _isSearching = true;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat_bubble),
                        onPressed: () => setState(() => _currentIndex = 1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications),
                        onPressed: () => setState(() => _currentIndex = 3),
                      ),
                      IconButton(
                        icon: const Icon(Icons.account_circle),
                        onPressed: () => setState(() => _currentIndex = 2),
                      ),
                    ],
              elevation: 0,
              backgroundColor: Colors.transparent,
            )
          : null,
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF4A90E2),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Lịch đặt',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Thông báo'),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final MapController _mapController = MapController();
  final LatLng _center = LatLng(10.762622, 106.660172);
  List<SportsField> _allSportsFields = [];
  List<SportsField> _sportsFields = [];
  bool _mapLoadingError = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _fetchSportsFields();
  }

  Future<void> _fetchSportsFields() async {
    try {
      print("Đang kết nối tới Firestore...");
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('sports_fields')
              .limit(10)
              .get();

      print("Nhận được ${querySnapshot.size} documents");

      if (querySnapshot.size == 0) {
        print("Không tìm thấy sân nào trong database");
        return;
      }

      // Lấy vị trí hiện tại của người dùng
      Position? userPosition;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          print('Location services are disabled');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng bật dịch vụ định vị')),
          );
          return;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            print('Location permissions are denied');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Quyền truy cập vị trí bị từ chối')),
            );
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          print('Location permissions are permanently denied');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quyền truy cập vị trí bị từ chối vĩnh viễn'),
            ),
          );
          return;
        }

        userPosition = await Geolocator.getCurrentPosition();
      } catch (e) {
        print('Error getting user location: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi lấy vị trí: $e')));
      }

      final fields =
          querySnapshot.docs.map((doc) {
            print("Document ID: ${doc.id}");
            SportsField field = SportsField.fromFirestore(doc);

            // Tính khoảng cách từ vị trí người dùng đến sân bóng
            double? distance;
            if (userPosition != null) {
              distance =
                  Geolocator.distanceBetween(
                    userPosition.latitude,
                    userPosition.longitude,
                    field.lat,
                    field.lng,
                  ) /
                  1000; // Chuyển đổi từ mét sang kilômét
            }

            // Tạo bản sao mới với distance được cập nhật
            return field.copyWith(distance: distance);
          }).toList();

      setState(() {
        _allSportsFields = fields;
        _sportsFields = List.from(_allSportsFields);
      });
    } catch (e, stackTrace) {
      print("Lỗi khi đọc Firestore: $e");
      print(stackTrace);
      setState(() {
        _mapLoadingError = true;
      });
    }
  }

  String _getSportIcon(String sportType) {
    switch (sportType) {
      case 'Bóng đá':
        return 'assets/Icons/football.png';
      case 'Cầu lông':
        return 'assets/Icons/badminton.png';
      case 'Tennis':
        return 'assets/Icons/tennis.png';
      case 'Bóng rổ':
        return 'assets/Icons/basketball.png';
      default:
        return 'assets/Icons/marker.png';
    }
  }

  Future<void> _centerOnUserLocation() async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Dịch vụ định vị bị tắt');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng bật dịch vụ định vị')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Quyền truy cập vị trí bị từ chối');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quyền truy cập vị trí bị từ chối')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Quyền truy cập vị trí bị từ chối vĩnh viễn');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quyền truy cập vị trí bị từ chối vĩnh viễn')),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('Không thể lấy vị trí trong thời gian cho phép');
      },
    );

    print('Vị trí người dùng: ${position.latitude}, ${position.longitude}');
    _mapController.move(LatLng(position.latitude, position.longitude), 14.0);
  } catch (e) {
    print('Lỗi lấy vị trí: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lỗi lấy vị trí: $e')),
    );
    // Fallback về toạ độ mặc định ở Việt Nam
    _mapController.move(const LatLng(10.762622, 106.660172), 14.0);
  }
}

  //fill
  void _showFieldDetails(BuildContext context, SportsField field) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  field.address,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Loại sân: ${field.sportType}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${field.rating?.toStringAsFixed(1) ?? '4.8'} (${field.reviewCount ?? '120'})',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          AppRoutes.booking,
                          arguments: {'field': field},
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A90E2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Đặt ngay',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  //icon sport
  Widget _buildSportMarker(BuildContext context, SportsField field) {
    Color markerColor;
    switch (field.sportType) {
      case 'Cầu lông':
        markerColor = const Color(0xFFF48FB1);
        break;
      case 'Bóng đá':
        markerColor = const Color(0xFFA5D6A7);
        break;
      default:
        markerColor = const Color(0xFF90A4AE);
    }

    return GestureDetector(
      onTap: () => _showFieldDetails(context, field),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: markerColor.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/Icons/marker.png',
              width: 50,
              height: 50,
              color: markerColor,
              colorBlendMode: BlendMode.srcIn,
            ),
            Image.asset(
              _getSportIcon(field.sportType),
              width: 30,
              height: 30,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(preferredSize: Size.zero, child: SizedBox.shrink()),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child:
            _mapLoadingError
                ? const Center(
                  child: Text(
                    'Lỗi tải bản đồ, vui lòng thử lại',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                )
                
                : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 300,
                          width: double.infinity,
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    initialCenter: _center,
                                    initialZoom: 14.0,
                                    onTap: (tapPosition, point) {
                                      AppRoutes.goTo(
                                        context,
                                        AppRoutes.map,
                                        arguments: _sportsFields,
                                      );
                                    },
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                                      subdomains: const ['a', 'b', 'c', 'd'],
                                      errorTileCallback: (
                                        tile,
                                        error,
                                        stackTrace,
                                      ) {
                                        print('Tile loading error: $error');
                                        setState(() {
                                          _mapLoadingError = true;
                                        });
                                      },
                                      tileProvider: NetworkTileProvider(),
                                    ),
                                    MarkerClusterLayerWidget(
                                      options: MarkerClusterLayerOptions(
                                        maxClusterRadius: 45,
                                        markers:
                                            _sportsFields.map((field) {
                                              return Marker(
                                                point: LatLng(
                                                  field.lat,
                                                  field.lng,
                                                ),
                                                width: 50,
                                                height: 50,
                                                child: _buildSportMarker(
                                                  context,
                                                  field,
                                                ),
                                              );
                                            }).toList(),
                                        builder: (context, markers) {
                                          return Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.pinkAccent
                                                  .withOpacity(0.8),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${markers.length}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                bottom: 16,
                                right: 16,
                                child: FloatingActionButton(
                                  onPressed: _centerOnUserLocation,
                                  backgroundColor: const Color(0xFF4A90E2),
                                  elevation: 6,
                                  child: const Icon(
                                    Icons.my_location,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Danh mục thể thao',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 4,
                          children: [
                            _buildSportCategory(
                              Icons.sports_soccer,
                              'Bóng đá',
                              Colors.green,
                            ),
                            _buildSportCategory(
                              Icons.sports,
                              'Cầu lông',
                              Colors.blue,
                            ),
                            _buildSportCategory(
                              Icons.sports_tennis,
                              'Tennis',
                              Colors.orange,
                            ),
                            _buildSportCategory(
                              Icons.sports_basketball,
                              'Bóng rổ',
                              Colors.red,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Sân gần bạn',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/view_all_fields',
                                  arguments: _sportsFields,
                                );
                              },
                              child: const Text(
                                'Xem tất cả',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _sportsFields.isEmpty
                            ? const Center(
                              child: Text(
                                "Không tìm thấy sân thể thao nào",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            )
                            : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount:
                                  _sportsFields.length > 5
                                      ? 5
                                      : _sportsFields.length,
                              itemBuilder: (context, index) {
                                return _buildFieldCard(
                                  context,
                                  _sportsFields[index],
                                );
                              },
                            ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

//build view card
  Widget _buildFieldCard(BuildContext context, SportsField field) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              field.imageUrl ?? 'https://via.placeholder.com/400x200',
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error, color: Colors.red),
                );
              },
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
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${field.price?.toStringAsFixed(0) ?? '100.000'} VND/giờ • ${field.distance != null ? field.distance!.toStringAsFixed(1) : 'N/A'}km',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${field.rating?.toStringAsFixed(1) ?? '4.8'} (${field.reviewCount ?? '120'})',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_auth.currentUser == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng đăng nhập để đặt sân'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        _showFieldDetails(context, field);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A90E2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Đặt ngay',
                        style: TextStyle(fontSize: 14),
                      ),
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

  Widget _buildSportCategory(IconData icon, String name, Color color) {
    return GestureDetector(
      onTap: () {},
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
