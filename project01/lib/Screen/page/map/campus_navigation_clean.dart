import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:ui';

import 'package:project01/services/smart_matching_service.dart';
import 'package:project01/Screen/page/map/mapmodel/building_polygon_data.dart';
import 'package:project01/Screen/page/map/feature/marker_helper.dart';
import 'package:project01/widgets/branded_loading.dart';
import 'package:project01/Screen/page/map/feature/room_posts_dialog.dart';
import 'package:project01/models/post.dart';
import 'package:project01/Screen/page/notification/smart_notification_popup.dart';

class CampusNavigation extends StatefulWidget {
  final String? initialFindRequest;

  const CampusNavigation({super.key, this.initialFindRequest});

  @override
  State<CampusNavigation> createState() => _CampusNavigationState();
}

class _CampusNavigationState extends State<CampusNavigation>
    with AutomaticKeepAliveClientMixin {
  GoogleMapController? _mapController;

  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<QuerySnapshot>? _postsSubscription;
  Set<Marker> _markers = {};
  Set<Marker> _buildingMarkers = {};
  // Cache for marker bitmaps to avoid re-drawing every time
  final Map<String, BitmapDescriptor> _markerIconCache = {};
  final Map<String, int> _lastPostCounts = {};
  Set<Circle> _circles = {};
  LatLng? _currentPosition;
  LatLng? _initialMapTarget; // พิกัดเริ่มต้นที่จะใช้ตอนเปิดแมพ
  bool _isFirstLocationUpdate = true; // เอาไว้เช็คตอนโหลด location ครั้งแรก
  bool _isLoadingInitialLocation = true; // รอโหลดพิกัดแรกก่อนโชว์แมพ

  // State สำหรับเมนูนำทางแบบย่อส่วน (Liquid Glass)
  bool _isNavExpanded = false;
  int _selectedBuildingIndex = 0;
  final ScrollController _navScrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      SmartMatchingService.updateUserActivity(currentUserId);
    }

    _updateStatusBarColor();
    _handleMapInitialization(); // เริ่มกระบวนการเตรียมแมพแบบ Robust
    _startBuildingPostsStream();
  }

  Future<void> _handleMapInitialization() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. เช็ค Location Service
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _finishInitializationWithFallback('กรุณาเปิด Location Service ก่อนใช้งาน');
      return;
    }

    // 2. เช็ค/ขอ Permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _finishInitializationWithFallback('กรุณาอนุญาตสิทธิ์ตำแหน่งเพื่อใช้งานแอป');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _finishInitializationWithFallback('กรุณาเปิดสิทธิ์ตำแหน่งในการตั้งค่า');
      return;
    }

    // 3. เมื่อผ่านด่าน Permission แล้ว ค่อยหาพิกัด
    try {
      Position? position = await Geolocator.getLastKnownPosition();

      if (position == null) {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
        ).timeout(const Duration(seconds: 4), onTimeout: () => throw TimeoutException('Location timeout'));
      }

      if (mounted) {
        setState(() {
          _initialMapTarget = LatLng(position!.latitude, position.longitude);
          _isLoadingInitialLocation = false;
        });
        _startLocationTracking(); // เริ่ม Tracking ต่อเนื่อง
      }
    } catch (e) {
      debugPrint('Error getting initial location: $e');
      _finishInitializationWithFallback(null);
    }
  }

  void _finishInitializationWithFallback(String? message) {
    if (mounted) {
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
      setState(() {
        _initialMapTarget = const LatLng(13.733008369761437, 100.48956425829512);
        _isLoadingInitialLocation = false;
      });
      // ถึงหาพิกัดไม่ได้ ก็ต้อง Tracking ทิ้งไว้ เผื่อ User ไปเปิด GPS ทีหลัง
      _startLocationTracking();
    }
  }

  void _startBuildingPostsStream() {
    _postsSubscription = FirebaseFirestore.instance
        .collection('lost_found_items')
        .where('status', isEqualTo: 'active') // โหลดเฉพาะออเดอร์ที่ยังไม่ปิดเคส
        .snapshots()
        .listen(
          (snapshot) async {
            final threeMonthsAgo = DateTime.now().subtract(
              const Duration(days: 90),
            );

            // นับจำนวนโพสต์ของแต่ละอาคารในหน่วยความจำ (รวดเร็วกว่าการ Query ทีละตึก)
            Map<String, int> buildingCounts = {};
            for (var doc in snapshot.docs) {
              final data = doc.data();

              // กรองทิ้งข้อมูลที่เก่าเกิน 3 เดือน ในระดับ Client เพื่อเลี่ยงปัญหา Missing Index ของ Firestore
              final createdAtRaw = data['createdAt'];
              if (createdAtRaw != null && createdAtRaw is Timestamp) {
                if (createdAtRaw.toDate().isBefore(threeMonthsAgo)) {
                  continue; // ข้ามโพสต์ที่เก่าเกิน 90 วัน
                }
              }
              final buildingName = data['building'] as String?;
              if (buildingName != null && buildingName.isNotEmpty) {
                buildingCounts[buildingName] =
                    (buildingCounts[buildingName] ?? 0) + 1;
              }
            }

            final buildings = BuildingPointData.getCampusBuildings();
            Set<Marker> newBuildingMarkers = {};

            for (var building in buildings) {
              int postCount = buildingCounts[building.name] ?? 0;
              final markerId = 'badge_${building.id}';

              try {
                // Only re-create visibility if the count has changed or icon isn't cached
                if (!_markerIconCache.containsKey(markerId) ||
                    _lastPostCounts[markerId] != postCount) {
                  final bitmapIcon =
                      await MarkerHelper.createCompositeMarkerBitmap(
                        building.name.replaceAll('อาคาร ', ''),
                        postCount.toString(),
                      );
                  _markerIconCache[markerId] = bitmapIcon;
                  _lastPostCounts[markerId] = postCount;
                }

                newBuildingMarkers.add(
                  Marker(
                    markerId: MarkerId(markerId),
                    position: building.center,
                    icon: _markerIconCache[markerId]!,
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
                _updateMarkers(); // เอา user marker มารวมใหม่ด้วย
              });
            }
          },
          onError: (error) {
            debugPrint('Error listening to posts stream: $error');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('กำลังพยายามเชื่อมต่อข้อมูลใหม่ (ออฟไลน์)'),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          },
        );
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

              final threeMonthsAgo = DateTime.now().subtract(
                const Duration(days: 90),
              );

              final posts =
                  snapshot.data!.docs
                      .where((doc) {
                        final data = doc.data() as Map<String, dynamic>;

                        // กรองเฉพาะโพสต์ที่เพิ่งหา (Active)
                        if (data['status'] != 'active') return false;

                        // กรองอันที่เก่ากว่า 90 วันทิ้ง (รอระบบเข้าโกดังจัดการ)
                        final createdAtRaw = data['createdAt'];
                        if (createdAtRaw != null && createdAtRaw is Timestamp) {
                          if (createdAtRaw.toDate().isBefore(threeMonthsAgo)) {
                            return false;
                          }
                        }

                        return true;
                      })
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
    // เช็ค Permission อีกรอบเพื่อความชัวร์ (แม้จะเช็คใน Initialization มาแล้ว)
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
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

          // เลื่อนกล้องจากซูมลึก (ที่เริ่มตอนแรก) มาซูมปกติเพื่อให้เห็นภาพรวม
          if (_isFirstLocationUpdate && _mapController != null) {
            _isFirstLocationUpdate = false;
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                _mapController!.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: currentLatLng,
                      zoom: 18, // ซูมออกมาดูภาพรวม
                      bearing: 140.0,
                    ),
                  ),
                );
              }
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _postsSubscription?.cancel();
    _navScrollController.dispose();
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

  void _panToBuilding(LatLng target) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: 19.5, // ซูมเข้าไปใกล้ๆ ตึก
          bearing: 140.0, // คงทิศทางเฉียง
          tilt: 45.0, // เอียงกล้องนิดหน่อยให้ดูมีมิติ
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // สำคัญมากสำหรับ AutomaticKeepAliveClientMixin

    if (_isLoadingInitialLocation) {
      return Scaffold(
        body: Center(
          child: BrandedLoading(size: 60),
        ),
      );
    }

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
              initialCameraPosition: CameraPosition(
                target: _initialMapTarget ?? const LatLng(13.733008369761437, 100.48956425829512),
                zoom: 25, // เริ่มต้นแบบซูมลึกก่อน แล้วค่อยถอยออกมา
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
                    CameraUpdate.newLatLngZoom(_currentPosition!, 19.5),
                  );
                } else {
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      const LatLng(13.732371, 100.490137),
                      19.5,
                    ),
                  );
                }
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),

          // ปุ่มนำทางอาคารแบบ iOS Liquid Glass (อยู่ตรงกลางล่าง)
          Positioned(
            bottom: 30, // ลอยขึ้นมาจากขอบล่างนิดหน่อย
            left: 60, // เว้นที่ให้ปุ่ม Location ซ้าย
            right: 60, // เว้นที่ให้ปุ่ม Notification ขวา
            child: Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isNavExpanded = !_isNavExpanded;
                  });
                  if (_isNavExpanded) {
                    // เลื่อนให้แถบอยู่ตรงกลางที่ตึกปัจจุบัน (-1, 0, +1)
                    Future.delayed(const Duration(milliseconds: 150), () {
                      if (_navScrollController.hasClients) {
                        double screenWidth = MediaQuery.of(context).size.width;
                        double containerWidth =
                            screenWidth - 120; // หัก margin ซ้ายขวาฝั่งละ 60
                        double itemWidthApprox =
                            100.0; // ความกว้างโดยเฉลี่ยของแต่ละปุ่ม

                        double offset =
                            (_selectedBuildingIndex * itemWidthApprox) -
                            (containerWidth / 2) +
                            (itemWidthApprox / 2);
                        if (offset < 0) offset = 0;

                        try {
                          _navScrollController.animateTo(
                            offset,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                          );
                        } catch (e) {
                          debugPrint('Scroll error: $e');
                        }
                      }
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutBack,
                  height: 48,
                  // ถ้าไม่ขยายให้มีความกว้างแค่พอดีข้อความ ถ้าขยายให้กว้างเต็มกรอบ
                  width:
                      _isNavExpanded
                          ? MediaQuery.of(context).size.width - 140
                          : 130,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24), // รูปทรงแคปซูล
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 10,
                        sigmaY: 10,
                      ), // เอฟเฟกต์กระจกฝ้า
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: _isNavExpanded ? 4 : 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(
                            0.55,
                          ), // สีดำโปร่งแสงสไตล์ Glass
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15), // ขอบเงาบางๆ
                            width: 1,
                          ),
                        ),
                        child:
                            _isNavExpanded
                                ? ListView.builder(
                                  controller: _navScrollController,
                                  scrollDirection: Axis.horizontal,
                                  itemCount:
                                      BuildingPointData.getCampusBuildings()
                                          .length,
                                  itemBuilder: (context, index) {
                                    final building =
                                        BuildingPointData.getCampusBuildings()[index];
                                    final isSelected =
                                        _selectedBuildingIndex == index;

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedBuildingIndex = index;
                                          // ปิดตัวเลือกกลับเป็นปุ่มเล็ก หลังจากเลือก (หรือคอมเมนต์บรรทัดล่างออกเพื่อให้มันเปิดค้างไว้)
                                          _isNavExpanded = false;
                                        });
                                        _panToBuilding(building.center);
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              isSelected
                                                  ? Colors.white.withOpacity(
                                                    0.25,
                                                  ) // วงใสๆ ครอบปุ่มที่เลือก
                                                  : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          building.name,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                )
                                : Center(
                                  child: Text(
                                    BuildingPointData.getCampusBuildings()[_selectedBuildingIndex]
                                        .name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Floating notification FAB (ดีไซน์ใหม่เป็นสี่เหลี่ยมขอบมนสีดำ กระดิ่งสีฟ้า)
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
                return GestureDetector(
                  onTap: _showNotifications,
                  child: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text('$unreadCount'),
                    offset: const Offset(-4, 4),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A), // สีดำเข้ม
                        borderRadius: BorderRadius.circular(16), // ขอบมน
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.notifications,
                        color: Color(0xFF2196F3), // สีฟ้าสดใส
                        size: 26,
                      ),
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
