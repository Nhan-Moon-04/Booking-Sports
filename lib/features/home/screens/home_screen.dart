import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:do_an_mobile/firestore database/sport_fields.dart';
import 'package:do_an_mobile/routes/app_routes.dart';
import 'package:do_an_mobile/features/profile/screens/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    HomeContent(),
    const Center(child: Text('Lịch đặt')),
    ProfileScreen(),
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
      final snapshot = await FirebaseFirestore.instance.collection('sports_fields').get();
      setState(() {
        _allSportsFields = snapshot.docs.map((doc) {
          final data = doc.data();
          return SportsField(
            id: doc.id,
            name: data['name'] ?? '',
            address: data['address'] ?? '',
            lat: data['lat']?.toDouble() ?? 0.0,
            lng: data['lng']?.toDouble() ?? 0.0,
            sportType: data['sportType'] ?? '',
          );
        }).toList();
        _sportsFields = List.from(_allSportsFields);
      });
    } catch (e) {
      print('Error fetching sports fields: $e');
    }
  }

  IconData _getMarkerIcon(String sportType) {
    switch (sportType) {
      case 'Bóng đá':
        return Icons.sports_soccer;
      case 'Cầu lông':
        return Icons.sports_tennis;
      case 'Tennis':
        return Icons.sports_tennis;
      case 'Bóng rổ':
        return Icons.sports_basketball;
      default:
        return Icons.sports;
    }
  }

  Future<void> _centerOnUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      _mapController.move(LatLng(position.latitude, position.longitude), 14.0);
    } catch (e) {
      print('Error getting location: $e');
      _mapController.move(_center, 14.0);
    }
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
            Text(
              field.address,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Loại sân: ${field.sportType}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
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
                    Navigator.pop(context);
                    if (_auth.currentUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng đăng nhập để đặt sân')),
                      );
                      return;
                    }
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
    );
  }

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
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm sân...',
                border: InputBorder.none,
                icon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _sportsFields = _allSportsFields
                      .where((field) =>
                          field.name.toLowerCase().contains(value.toLowerCase()))
                      .toList();
                });
              },
            ),
          ),

          const SizedBox(height: 20),

          // Flutter Map
          Stack(
            children: [
              SizedBox(
                height: 200,
                child: _mapLoadingError
                    ? const Center(child: Text('Lỗi tải bản đồ, vui lòng thử lại'))
                    : FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _center,
                          initialZoom: 14.0,
                          onTap: (tapPosition, point) {
                            AppRoutes.goTo(context, AppRoutes.map);
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: const ['a', 'b', 'c'],
                            errorTileCallback: (tile, error, stackTrace) {
                              print('Tile loading error: $error');
                              setState(() {
                                _mapLoadingError = true;
                              });
                            },
                            tileProvider: NetworkTileProvider(),
                          ),
                          MarkerLayer(
                            markers: _sportsFields.map((field) => Marker(
                                  point: LatLng(field.lat, field.lng),
                                  width: 80,
                                  height: 80,
                                  child: GestureDetector(
                                    onTap: () {
                                      _showFieldDetails(context, field);
                                    },
                                    child: Icon(
                                      _getMarkerIcon(field.sportType),
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                )).toList(),
                          ),
                        ],
                      ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  mini: true,
                  onPressed: _centerOnUserLocation,
                  child: const Icon(Icons.my_location),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Danh sách phường
          const Text(
            'Các phường gần đây',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                PhuongChip(name: 'PHUONG 8'),
                PhuongChip(name: 'PHUONG 12'),
                PhuongChip(name: 'PHUONG 15'),
                PhuongChip(name: 'PHUONG 16'),
                PhuongChip(name: 'PHUONG 17'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Danh mục thể thao
          const Text(
            'Danh mục thể thao',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            children: [
              _buildSportCategory(Icons.sports_soccer, 'Bóng đá', Colors.green),
              _buildSportCategory(Icons.sports_tennis, 'Cầu lông', Colors.blue),
              _buildSportCategory(Icons.sports_tennis, 'Tennis', Colors.orange),
              _buildSportCategory(Icons.sports_basketball, 'Bóng rổ', Colors.red),
            ],
          ),

          const SizedBox(height: 20),

          // Danh sách sân gần bạn
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sân gần bạn',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Xem tất cả'),
              ),
            ],
          ),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) => _buildFieldCard(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSportCategory(IconData icon, String name, Color color) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 5),
        Text(name, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

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
                        if (_auth.currentUser == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng đăng nhập để đặt sân')),
                          );
                          return;
                        }
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

class PhuongChip extends StatelessWidget {
  final String name;
  const PhuongChip({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(name),
    );
  }
}