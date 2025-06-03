import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:do_an_mobile/firestore database/sport_fields.dart';
import 'package:do_an_mobile/routes/app_routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:do_an_mobile/features/booking_schedule/booking_schedule_screen.dart';
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LatLng _center = LatLng(10.762622, 106.660172);

  List<SportsField> _allSportsFields = []; // List gốc chưa lọc
  List<SportsField> _sportsFields = []; // List hiển thị sau lọc
  bool _mapLoadingError = false;

  @override
  void initState() {
    super.initState();
    _fetchSportsFields();
  }

  Future<void> _fetchSportsFields() async {
    try {
      print("Đang kết nối tới Firestore...");
      final querySnapshot =
          await FirebaseFirestore.instance.collection('sports_fields').limit(10).get();

      print("Nhận được ${querySnapshot.size} documents");

      if (querySnapshot.size == 0) {
        print("Không tìm thấy sân nào trong database");
        return;
      }

      final fields = querySnapshot.docs.map((doc) {
        print("Document ID: ${doc.id}");
        return SportsField.fromFirestore(doc);
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
      _mapController.move(_center, 14.0); // Fallback to default center
    }
  }

  void _showFieldDetails(BuildContext context, SportsField field) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              field.address,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Loại sân: ${field.sportType}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    SizedBox(width: 4),
                    Text('4.8 (120)', style: TextStyle(color: Colors.white)),
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

 Widget _buildSportMarker(BuildContext context, SportsField field) {
  // Chọn màu marker theo loại thể thao
  Color markerColor;
  switch (field.sportType) {
    case 'Cầu lông':
      markerColor = Color(0xFFF48FB1); // Hồng pastel
      break;
    case 'Bóng đá':
      markerColor = Color(0xFFA5D6A7); // Xanh pastel
      break;
    default:
      markerColor = Color(0xFF90A4AE); // Xám pastel
  }

  return GestureDetector(
    onTap: () => _showFieldDetails(context, field),
    child: Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: markerColor.withOpacity(0.4),
            blurRadius: 6,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Nền marker đổi màu
          Image.asset(
            'assets/Icons/marker.png',
            width: 50,
            height: 50,
            color: markerColor,
            colorBlendMode: BlendMode.srcIn,
          ),
          // Biểu tượng thể thao (GIỮ MÀU GỐC, KHÔNG TÔ MÀU)
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


  Widget _buildNavButton(String label, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        // Xử lý khi nhấn nút (có thể thêm logic chuyển tab)
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.pinkAccent : Colors.grey,
            size: 24,
          ),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.pinkAccent : Colors.grey,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bản đồ sân thể thao',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.pinkAccent,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.white),
            onPressed: _centerOnUserLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          _mapLoadingError
              ? const Center(child: Text('Lỗi tải bản đồ, vui lòng thử lại'))
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 14.0,
                    onPositionChanged: (position, hasGesture) {
                      // Có thể thêm logic nếu cần
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      errorTileCallback: (tile, error, stackTrace) {
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
                        markers: _sportsFields.map((field) => Marker(
                              point: LatLng(field.lat, field.lng),
                              width: 50,
                              height: 50,
                              child: _buildSportMarker(context, field),
                            )).toList(),
                        builder: (context, markers) {
                          return Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.pinkAccent.withOpacity(0.8),
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
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm sân...',
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: Colors.pinkAccent),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.pinkAccent),
                    onPressed: () {
                      setState(() {
                        _sportsFields = List.from(_allSportsFields);
                      });
                    },
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    if (value.isEmpty) {
                      _sportsFields = List.from(_allSportsFields);
                    } else {
                      _sportsFields = _allSportsFields
                          .where((field) =>
                              field.name.toLowerCase().contains(value.toLowerCase()))
                          .toList();
                    }
                  });
                },
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavButton('Bản đồ', Icons.map, true),
                  _buildNavButton('Tìm bạn', Icons.group, false),
                  _buildNavButton('Đặt sân', Icons.calendar_today, false),
                  _buildNavButton('Nổi bật', Icons.star, false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}