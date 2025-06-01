import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:do_an_mobile/firestore database/sport_fields.dart';
import 'package:do_an_mobile/routes/app_routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LatLng _center = LatLng(10.762622, 106.660172);

  List<SportsField> _allSportsFields = []; // List gốc chưa lọc
  List<SportsField> _sportsFields = [];    // List hiển thị sau lọc

  bool _mapLoadingError = false;

  @override
  void initState() {
    super.initState();
    _fetchSportsFields();
  }

  Future<void> _fetchSportsFields() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('sports_fields').get();
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
        _sportsFields = List.from(_allSportsFields); // Copy dữ liệu để hiển thị
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
      _mapController.move(_center, 14.0); // Fallback to default center
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
            Text(field.address, style: TextStyle(color: Colors.grey[600])),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ sân thể thao'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _centerOnUserLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          _mapLoadingError
              ? Center(child: Text('Lỗi tải bản đồ, vui lòng thử lại'))
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(initialCenter: _center, initialZoom: 14.0),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      errorTileCallback: (tile, error, stackTrace) {
                        print('Tile loading error: $error');
                        setState(() {
                          _mapLoadingError = true;
                        });
                      },
                      tileProvider: NetworkTileProvider(),
                    ),
                    MarkerLayer(
                      markers: _sportsFields
                          .map(
                            (field) => Marker(
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
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm sân...',
                  border: InputBorder.none,
                  icon: const Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    if (value.isEmpty) {
                      _sportsFields = List.from(_allSportsFields);
                    } else {
                      _sportsFields = _allSportsFields
                          .where((field) => field.name.toLowerCase().contains(value.toLowerCase()))
                          .toList();
                    }
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
