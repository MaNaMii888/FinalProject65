import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final loc.Location _location = loc.Location();
  LatLng _currentLocation = const LatLng(13.7330, 100.4895);
  final String _mapType = 'university'; // เปลี่ยนเป็น university
  String _address = 'กำลังค้นหาตำแหน่ง...';
  bool _showUniversityMap = true; // สำหรับสลับแผนที่

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    loc.PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) return;
    }

    final userLocation = await _location.getLocation();
    setState(() {
      _currentLocation = LatLng(
        userLocation.latitude!,
        userLocation.longitude!,
      );
    });
    _getAddressFromLatLng(_currentLocation);
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          _address =
              "${p.street ?? ''} ${p.subLocality ?? ''} ${p.locality ?? ''} ${p.administrativeArea ?? ''}";
        });
      }
    } catch (e) {
      setState(() {
        _address = "ไม่พบที่อยู่";
      });
    }
  }

  String getTileLayerUrl() {
    switch (_mapType) {
      case 'university':
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'; // จะเปลี่ยนเป็น custom tile server
      case 'streets':
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      default:
        return 'https://tile.opentopomap.org/{z}/{x}/{y}.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 16,
            ),
            children: [
              // ถ้าเปิดใช้แผนที่มหาวิทยาลัย จะแสดงรูปแผนที่เป็นพื้นหลัง
              if (_showUniversityMap)
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                        'assets/images/map.png',
                      ), // ใส่รูปแผนที่ในโฟลเดอร์ assets
                      fit: BoxFit.cover,
                      opacity: 0.8, // ความโปร่งใส
                    ),
                  ),
                ),

              // Tile Layer ปกติ (จะแสดงทับรูปแผนที่หรือแยกกัน)
              TileLayer(
                urlTemplate: getTileLayerUrl(),
                userAgentPackageName: 'com.example.app',
              ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 60,
                    height: 60,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.location_pin,
                          size: 50,
                          color: Colors.red,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 2,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            "คุณอยู่ที่นี่",
                            style: TextStyle(fontSize: 12, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ปุ่มสลับแผนที่
          Positioned(
            right: 16,
            top: 100,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white.withOpacity(0.9),
              onPressed: () {
                setState(() {
                  _showUniversityMap = !_showUniversityMap;
                });
              },
              child: Icon(
                _showUniversityMap ? Icons.map : Icons.school,
                color: Colors.blue,
              ),
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              color: Colors.white.withOpacity(0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.place, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _address,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
