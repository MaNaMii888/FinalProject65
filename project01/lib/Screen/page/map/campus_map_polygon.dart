import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

import 'package:project01/services/smart_matching_service.dart';
import 'package:project01/Screen/page/map/mapmodel/building_polygon_data.dart';
import 'package:project01/Screen/page/map/feature/marker_helper.dart';
import 'package:project01/Screen/page/map/feature/room_posts_dialog.dart';
import 'package:project01/models/post.dart';
import 'package:project01/Screen/page/notification/smart_notification_popup.dart';

class CampusMapPolygon extends StatefulWidget {
  final String? initialFindRequest;

  const CampusMapPolygon({super.key, this.initialFindRequest});

  @override
  State<CampusMapPolygon> createState() => _CampusMapPolygonState();
}

class _CampusMapPolygonState extends State<CampusMapPolygon> {
  GoogleMapController? _mapController;

  StreamSubscription<Position>? _positionStreamSubscription;
  Set<Marker> _markers = {};
  Set<Marker> _buildingMarkers = {};
  Set<Circle> _circles = {};
  LatLng? _currentPosition;
  bool _isFirstLocationUpdate = true; // เอาไว้เช็คตอนโหลด location ครั้งแรก

  @override
  void initState() {
    super.initState();

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      SmartMatchingService.updateUserActivity(currentUserId);
    }

    _updateStatusBarColor();
    _startLocationTracking();
    _loadBuildingPoints();
  }

  Future<void> _loadBuildingPoints() async {
    final buildings = BuildingPointData.getCampusBuildings();
    Set<Marker> newBuildingMarkers = {};

    // 1. รีเซตข้อมูลเก่าออก
    setState(() {
      _buildingMarkers.clear();
    });

    for (var building in buildings) {
      // 3. ดึงยอดประกาศของตึกนั้น
      try {
        final querySnapshot =
            await FirebaseFirestore.instance
                .collection('lost_found_items')
                .where('building', isEqualTo: building.name)
                .get();

        int postCount = querySnapshot.docs.length;

        // ปักหมุดแบบ Composite (สีม่วงคอยบอกโซน + สีแดงคอยบอกจำนวน)
        // แสดงหมุดเสมอแม้ว่า postCount == 0 (ไม่มีของหาย)
        final bitmapIcon = await MarkerHelper.createCompositeMarkerBitmap(
          building.name.replaceAll(
            'อาคาร ',
            '',
          ), // ตัดคำว่า อาคาร ออกเพื่อให้ในวงกลมมีแค่เลขตึก จะได้ไม่ยาวเกินไป
          postCount.toString(),
        );

        newBuildingMarkers.add(
          Marker(
            markerId: MarkerId('badge_${building.id}'),
            position: building.center,
            icon: bitmapIcon,
            anchor: const Offset(0.5, 0.5),
            consumeTapEvents: true,
            onTap: () {
              _showBuildingPosts(
                building.id,
                building.name,
                building.displayFullName,
              );
            },
          ),
        );
      } catch (e) {
        debugPrint('Error loading badge for ${building.name}: $e');
      }
    }

    if (mounted) {
      setState(() {
        _buildingMarkers = newBuildingMarkers;
        _updateMarkers(); // เอา user marker มารวมใหม่
      });
    }
  }

  void _updateMarkers({Marker? myLocationMarker}) {
    Set<Marker> merged = Set.from(_buildingMarkers);
    if (myLocationMarker != null) {
      merged.add(myLocationMarker);
    } else {
      // พยายามเก็บ my location เดิมไว้ถ้ามี
      final currentLocMarker =
          _markers
              .where((m) => m.markerId.value == 'my_current_location')
              .toList();
      if (currentLocMarker.isNotEmpty) {
        merged.add(currentLocMarker.first);
      }
    }
    setState(() {
      _markers = merged;
    });
  }

  void _showBuildingPosts(
    String buildingId,
    String buildingName,
    String buildingFullName,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => FutureBuilder<QuerySnapshot>(
            future:
                FirebaseFirestore.instance
                    .collection('lost_found_items')
                    .where('building', isEqualTo: buildingName)
                    .orderBy('createdAt', descending: true)
                    .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return AlertDialog(
                  title: const Text('เกิดข้อผิดพลาด'),
                  content: Text(snapshot.error.toString()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ปิด'),
                    ),
                  ],
                );
              }

              final posts =
                  snapshot.data!.docs
                      .map(
                        (doc) => Post.fromJson({
                          ...doc.data() as Map<String, dynamic>,
                          'id': doc.id,
                        }),
                      )
                      .toList();

              return RoomPostsDialog(
                roomName:
                    buildingFullName, // ชื่อเต็มของอาคาร (เช่น อาคารเรียนรวม) ตัวหนา
                buildingName:
                    buildingName, // ชื่อโซน/ชื่อตึกเดิม (เช่น อาคาร 16) ตัวบาง
                posts: posts,
              );
            },
          ),
    );
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'กรุณาเปิด Location Service ของเครื่องก่อนใช้งานแผนที่',
            ),
          ),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      final currentLatLng = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _currentPosition = currentLatLng;

          final myLocationMarker = Marker(
            markerId: const MarkerId('my_current_location'),
            position: currentLatLng,
            infoWindow: const InfoWindow(title: 'คุณอยู่ที่นี่'),
          );

          _updateMarkers(myLocationMarker: myLocationMarker);

          _circles = {
            Circle(
              circleId: const CircleId('my_accuracy_radius'),
              center: currentLatLng,
              radius: position.accuracy,
              fillColor: Colors.blue.withOpacity(0.2),
              strokeColor: Colors.blue,
              strokeWidth: 2,
            ),
          };

          // เลื่อนกล้องไปหาผู้ใช้เฉพาะครั้งแรกที่จับพิกัดได้
          if (_isFirstLocationUpdate && _mapController != null) {
            _isFirstLocationUpdate = false;
            _mapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: currentLatLng,
                  zoom: 18.0, // ซูมดูผู้ใช้ชัดๆ
                  bearing: 140.0, // คงทิศทางเฉียงๆ ไว้
                ),
              ),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  void _updateStatusBarColor() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).primaryColor,
      builder: (context) => const SmartNotificationPopup(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // Google Map Full Screen
          Positioned.fill(
            child: GoogleMap(
              padding: const EdgeInsets.only(
                top: 100,
                left: 16,
              ), // เลื่อน Compass ลงมาจากขอบบน
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              initialCameraPosition: const CameraPosition(
                // ขยับศูนย์กลางแผนที่ให้คลุมตึกทุกฝั่งได้ดีเหมือนในรูป
                target: LatLng(13.733008369761437, 100.48956425829512),
                zoom: 25,
                // หมุนทิศทาง(Bearing) เข็มทิศสีแดงจะชี้เฉียงลงมาซ้ายล่างเหมือนหน้าจอตัวอย่างเป๊ะ
                bearing: 140.0,
              ),
              markers: _markers,
              circles: _circles,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              zoomControlsEnabled: false,
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: true,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                ),
              },
            ),
          ),

          // ปุ่มบอกตำแหน่งฉัน
          Positioned(
            left: 20,
            bottom: 24,
            child: FloatingActionButton.small(
              heroTag: "center_campus",
              onPressed: () {
                if (_currentPosition != null) {
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(_currentPosition!, 18.0),
                  );
                } else {
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      const LatLng(13.732371, 100.490137),
                      18.0,
                    ),
                  );
                }
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),

          // Floating notification FAB
          Positioned(
            right: 20,
            bottom: 24,
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseAuth.instance.currentUser?.uid != null
                      ? FirebaseFirestore.instance
                          .collection('notifications')
                          .where(
                            'userId',
                            isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                          )
                          .where('isRead', isEqualTo: false)
                          .snapshots()
                      : const Stream.empty(),
              builder: (context, snapshot) {
                int unreadCount = 0;
                if (snapshot.hasData) {
                  unreadCount = snapshot.data!.docs.length;
                }
                return FloatingActionButton.small(
                  heroTag: "notification_bell",
                  onPressed: _showNotifications,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  child: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text('$unreadCount'),
                    child: Icon(
                      Icons.notifications,
                      color: Theme.of(context).primaryColorDark,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
