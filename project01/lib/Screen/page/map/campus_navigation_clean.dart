// campus_navigation_clean.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; // Add geolocator
import 'dart:async'; // Add async for StreamSubscription
import 'package:project01/Screen/page/map/mapmodel/building_data.dart';
import 'package:project01/Screen/page/map/feature/floor_plan_a.dart';
import 'package:project01/Screen/page/map/feature/floor_plan_b.dart';
import 'package:project01/Screen/page/notification/smart_notification_screen.dart';
import 'package:project01/services/smart_matching_service.dart';

class CampusNavigation extends StatefulWidget {
  final String? initialFindRequest;

  const CampusNavigation({super.key, this.initialFindRequest});

  @override
  State<CampusNavigation> createState() => _CampusNavigationState();
}

class _CampusNavigationState extends State<CampusNavigation>
    with SingleTickerProviderStateMixin {
  String? selectedBuilding;
  String findRequest = '';
  final PageController _pageController = PageController();
  GoogleMapController? _mapController;
  late TabController _tabController;

  Map<String, RoomData>? roomDataMap;
  bool isLoadingRoomData = false;

  // เพิ่ม State สำหรับ GPS Tracking
  StreamSubscription<Position>? _positionStreamSubscription;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
        // เปลี่ยนสี status bar ตาม tab ที่เลือก
        _updateStatusBarColor();
      }
    });

    if (widget.initialFindRequest != null &&
        widget.initialFindRequest!.isNotEmpty) {
      findRequest = widget.initialFindRequest!;
      _processFindRequest(findRequest);
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      SmartMatchingService.updateUserActivity(currentUserId);
    }

    _loadRoomData();

    // ตั้งค่า status bar เริ่มต้น
    _updateStatusBarColor();

    // เริ่มการติดตาม GPS
    _startLocationTracking();
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. ตรวจสอบว่าเปิด Location Service บนมือถือหรือยัง
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

    // 2. ขอสิทธิ์ Permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่ง')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('สิทธิ์ถูกปฏิเสธถาวร ไม่สามารถดึงตำแหน่งได้'),
          ),
        );
      }
      return;
    }

    // 3. เมื่อได้สิทธิ์แล้ว เริ่ม Stream ดูดพิกัดแบบต่อเนื่อง
    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high, // ความแม่นยำสูง
      distanceFilter:
          5, // สั่งอัพเดทเมื่อเดินไปครบทุกๆ 5 เมตร (ลดการทำงานซ้ำซ้อน)
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      final currentLatLng = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _currentPosition = currentLatLng;

          // สร้างหมุด (Marker) เคลื่อนที่ตามคน
          _markers = {
            Marker(
              markerId: const MarkerId('my_current_location'),
              position: currentLatLng,
              infoWindow: const InfoWindow(title: 'คุณอยู่ที่นี่'),
            ),
          };

          // สร้างวงรัศมีสีฟ้า
          _circles = {
            Circle(
              circleId: const CircleId('my_accuracy_radius'),
              center: currentLatLng,
              radius: position.accuracy, // วาดความกว้างวงกลมตามความแม่นยำ GPS
              fillColor: Colors.blue.withOpacity(0.2),
              strokeColor: Colors.blue,
              strokeWidth: 2,
            ),
          };
        });

        // แพนกล้องตามผู้ใช้อัตโนมัติ (ถ้าต้องการให้แอพล็อกเป้าตลอด)
        // _mapController?.animateCamera(CameraUpdate.newLatLng(currentLatLng));
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription
        ?.cancel(); // อย่าลืมยกเลิก Stream เมื่อปิดหน้าต่าง
    _pageController.dispose();
    _tabController.dispose();
    // รีเซ็ต status bar เมื่อออกจากหน้านี้
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  // ฟังก์ชันสำหรับอัพเดทสี status bar
  void _updateStatusBarColor() {
    // ทั้ง 2 หน้าใช้ status bar โปร่งใสเหมือนกัน
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
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

  Future<void> _loadRoomData() async {
    if (isLoadingRoomData) return;
    if (!mounted) return;

    setState(() {
      isLoadingRoomData = true;
    });

    try {
      final buildingDataWithPosts =
          await BuildingDataService.getBuildingDataWithPosts();

      final Map<String, RoomData> newRoomDataMap = {};

      if (selectedBuilding != null &&
          buildingDataWithPosts.containsKey(selectedBuilding)) {
        final building = buildingDataWithPosts[selectedBuilding]!;
        for (final room in building.rooms) {
          if (room.roomData != null) {
            newRoomDataMap[room.id.toString()] = room.roomData!;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        roomDataMap = newRoomDataMap;
        isLoadingRoomData = false;
      });
    } catch (e) {
      debugPrint('Error loading room data: $e');
      if (!mounted) return;
      setState(() {
        isLoadingRoomData = false;
      });
    }
  }

  Future<void> _loadRoomDataForBuilding(String buildingId) async {
    if (!mounted) return;
    setState(() {
      isLoadingRoomData = true;
    });

    try {
      final building = buildingData[buildingId];
      if (building != null) {
        final Map<String, RoomData> newRoomDataMap = {};

        for (final room in building.rooms) {
          final buildingData = await BuildingDataService.getBuildingData(
            buildingId,
            room.id.toString(),
            room.name,
          );
          newRoomDataMap[room.id.toString()] = buildingData;
        }

        if (!mounted) return;
        setState(() {
          roomDataMap = newRoomDataMap;
          isLoadingRoomData = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading room data for building: $e');
      if (!mounted) return;
      setState(() {
        isLoadingRoomData = false;
      });
    }
  }

  void _processFindRequest(String request) {
    debugPrint('Processing find request: $request');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface, // สีแดง Crimson
      body: Stack(
        children: [
          // Fullscreen content
          Positioned.fill(
            child: TabBarView(
              controller: _tabController,
              children: [_buildMapView(), _buildBuildingView()],
            ),
          ),

          // Custom TabBar overlay - ลอยทั้ง 2 หน้า
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.45),
                    Colors.black.withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
              ),
              child: _buildCustomTabBar(),
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
                return IconButton(
                  onPressed: _showNotifications,
                  icon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text('$unreadCount'),
                    child: const Icon(Icons.notifications),
                  ),
                  color: Theme.of(context).colorScheme.surface, // สีของไอคอน
                  iconSize: 40, // ขนาดของไอคอน
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      Colors.transparent,
                    ),
                    overlayColor: WidgetStateProperty.all(
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                    ), // ตอนกดให้ดูมีเอฟเฟกต์
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // แยก TabBar ออกมาเป็น widget แยก
  Widget _buildCustomTabBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCustomTab(0, 'แผนที่'),
        const SizedBox(width: 24),
        Container(width: 1, height: 16, color: Colors.white.withOpacity(0.3)),
        const SizedBox(width: 24),
        _buildCustomTab(1, 'ผังอาคาร'),
      ],
    );
  }

  Widget _buildCustomTab(int index, String title) {
    final isSelected = _tabController.index == index;

    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 32,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;

        if (screenWidth < 600) {
          // Mobile - Fullscreen
          return Stack(
            children: [
              Positioned.fill(
                child: GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    debugPrint('✅ Google Maps โหลดสำเร็จ');
                  },
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(13.732371977476102, 100.49013701457356),
                    zoom: 17.0,
                  ),
                  markers: _markers, // ใช้ state ของ marker
                  circles: _circles, // ใช้ state ของ circle
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  mapType: MapType.normal,
                  zoomControlsEnabled: false,
                  zoomGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  onTap: (LatLng position) {
                    debugPrint(
                      '📍 แตะแผนที่ที่: ${position.latitude}, ${position.longitude}',
                    );
                  },
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                    ),
                  },
                ),
              ),
              Positioned(
                left: 20,
                bottom: 20,
                child: FloatingActionButton.small(
                  heroTag: "center_campus",
                  onPressed: () {
                    if (_currentPosition != null) {
                      // ถ้าหาตำแหน่งเราเจอ ให้วิ่งไปหาเรา
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(_currentPosition!, 18.0),
                      );
                    } else {
                      // ไม่งั้นไป center ปกติ
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          const LatLng(13.732371977476102, 100.49013701457356),
                          17.0,
                        ),
                      );
                    }
                  },
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.my_location, color: Colors.white),
                ),
              ),
            ],
          );
        } else {
          // Tablet/Desktop - Responsive
          final statusBarHeight = MediaQuery.of(context).padding.top;
          final padding = screenWidth < 900 ? 24.0 : 32.0;

          return Column(
            children: [
              SizedBox(height: (statusBarHeight * 0.4).clamp(16.0, 32.0)),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Card(
                    elevation: 8,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: GoogleMap(
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                      },
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(13.732371977476102, 100.49013701457356),
                        zoom: 17.0,
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
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildBuildingView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final statusBarHeight = MediaQuery.of(context).padding.top;

        // คำนวณ padding แบบ responsive - เพิ่ม padding บนสำหรับ TabBar ที่ลอย
        final topPadding =
            statusBarHeight + 60.0; // status bar + tab bar height

        if (screenWidth < 600) {
          // Mobile layout - fullscreen เหมือนหน้า Map
          return Padding(
            padding: EdgeInsets.only(top: topPadding),
            child: PageView.builder(
              controller: _pageController,
              itemCount: 2,
              onPageChanged: (index) {
                if (!mounted) return;
                setState(() {
                  selectedBuilding = index == 0 ? 'A' : 'B';
                });
                _loadRoomDataForBuilding(selectedBuilding!);
              },
              itemBuilder: (context, index) {
                return SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: index == 0 ? FloorPlanA() : FloorPlanB(),
                );
              },
            ),
          );
        } else {
          // Tablet/Desktop layout
          final padding = screenWidth < 900 ? 24.0 : 32.0;

          return Padding(
            padding: EdgeInsets.only(
              top: topPadding,
              left: padding,
              right: padding,
              bottom: padding,
            ),
            child: PageView.builder(
              controller: _pageController,
              itemCount: 2,
              onPageChanged: (index) {
                if (!mounted) return;
                setState(() {
                  selectedBuilding = index == 0 ? 'A' : 'B';
                });
                _loadRoomDataForBuilding(selectedBuilding!);
              },
              itemBuilder: (context, index) {
                return Card(
                  elevation: 8,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: index == 0 ? FloorPlanA() : FloorPlanB(),
                );
              },
            ),
          );
        }
      },
    );
  }
}
