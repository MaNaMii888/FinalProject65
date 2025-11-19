// campus_navigation_clean.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  }

  @override
  void dispose() {
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
            child: IconButton(
              onPressed: _showNotifications,
              icon: const Icon(Icons.notifications),
              color: Theme.of(context).colorScheme.surface, // สีของไอคอน
              iconSize: 40, // ขนาดของไอคอน
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.transparent),
                overlayColor: WidgetStateProperty.all(
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                ), // ตอนกดให้ดูมีเอฟเฟกต์
              ),
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
                  markers: const {},
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
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
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        const LatLng(13.732371977476102, 100.49013701457356),
                        17.0,
                      ),
                    );
                  },
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.school, color: Colors.white),
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
                      markers: const {},
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
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
