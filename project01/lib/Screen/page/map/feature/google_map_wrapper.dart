import 'package:flutter/material.dart';
import 'package:project01/widgets/branded_loading.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapWrapper extends StatefulWidget {
  final LatLng initialLocation;
  final double initialZoom;
  final Set<Marker>? markers;
  final Function(GoogleMapController)? onMapCreated;

  const GoogleMapWrapper({
    super.key,
    required this.initialLocation,
    this.initialZoom = 16.0,
    this.markers,
    this.onMapCreated,
  });

  @override
  State<GoogleMapWrapper> createState() => _GoogleMapWrapperState();
}

class _GoogleMapWrapperState extends State<GoogleMapWrapper> {
  bool _mapLoaded = false;
  bool _mapFailed = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Google Map
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.initialLocation,
            zoom: widget.initialZoom,
          ),
          onMapCreated: (GoogleMapController controller) {
            debugPrint('🗺️ Google Maps สร้างเสร็จแล้ว');
            setState(() {
              _mapLoaded = true;
              _mapFailed = false;
            });
            widget.onMapCreated?.call(controller);
          },
          markers: widget.markers ?? {},
          mapType: MapType.normal,
          myLocationEnabled: false, // ปิดไว้ก่อนเพื่อไม่ให้ขอ permission
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          compassEnabled: true,
          buildingsEnabled: true,
          trafficEnabled: false,
          liteModeEnabled: false,
          // เพิ่ม callback สำหรับ error (ถ้ามี)
        ),

        // Loading indicator
        if (!_mapLoaded && !_mapFailed)
          Container(
            color: Colors.grey[100],
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BrandedLoading(size: 40),
                  SizedBox(height: 16),
                  Text(
                    'กำลังโหลดแผนที่...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

        // Error fallback
        if (_mapFailed)
          Container(
            color: Colors.grey[50],
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'ไม่สามารถโหลดแผนที่ได้',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage ?? 'กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _mapFailed = false;
                          _mapLoaded = false;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Debug info (แสดงเฉพาะ debug mode)
        if (!_mapLoaded && !_mapFailed)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'กำลังตรวจสอบ API Key...',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
