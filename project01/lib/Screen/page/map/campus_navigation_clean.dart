// campus_navigation_clean.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:project01/Screen/page/map/mapmodel/building_data.dart';
import 'package:project01/Screen/page/map/feature/floor_plan_a.dart';
import 'package:project01/Screen/page/map/feature/floor_plan_b.dart';
import 'package:project01/Screen/page/notification/smart_notification_popup.dart';
import 'package:project01/Screen/page/map/feature/action_button.dart';
import 'package:project01/services/smart_matching_service.dart';

class CampusNavigation extends StatefulWidget {
  final String? initialFindRequest;

  const CampusNavigation({super.key, this.initialFindRequest});

  @override
  State<CampusNavigation> createState() => _CampusNavigationState();
}

class _CampusNavigationState extends State<CampusNavigation> {
  String currentView = 'map'; // Default view
  String? selectedBuilding;
  String findRequest = '';
  final PageController _pageController = PageController();
  GoogleMapController? _mapController;

  // เพิ่มตัวแปรสำหรับเก็บข้อมูลห้อง
  Map<String, RoomData>? roomDataMap;
  bool isLoadingRoomData = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialFindRequest != null &&
        widget.initialFindRequest!.isNotEmpty) {
      findRequest = widget.initialFindRequest!;
      _processFindRequest(findRequest);
    }

    // อัพเดท user activity สำหรับ smart notification
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      SmartMatchingService.updateUserActivity(currentUserId);
    }

    // โหลดข้อมูลห้องเมื่อเริ่มต้น
    _loadRoomData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // แสดง notifications แบบ popup
  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SmartNotificationPopup(),
    );
  }

  // เพิ่มฟังก์ชันสำหรับโหลดข้อมูลห้อง
  Future<void> _loadRoomData() async {
    if (isLoadingRoomData) return;

    if (!mounted) return;
    setState(() {
      isLoadingRoomData = true;
    });

    try {
      final buildingDataWithPosts =
          await BuildingDataService.getBuildingDataWithPosts();

      // สร้าง Map ของ RoomData สำหรับอาคารที่เลือก
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

  // เพิ่มฟังก์ชันสำหรับโหลดข้อมูลห้องสำหรับอาคารเฉพาะ
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
            buildingId, // zoneId
            room.id.toString(), // buildingId
            room.name, // buildingName
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

  // เพิ่มฟังก์ชันสำหรับประมวลผลคำขอค้นหา
  void _processFindRequest(String request) {
    // ตรรกะการประมวลผลคำขอค้นหา
    debugPrint('Processing find request: $request');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use SafeArea to avoid overlap with camera notch/status bar
      body: SafeArea(
        top: true,
        bottom: false,
        child: currentView == 'map' ? _buildMapView() : _buildBuildingView(),
      ),
      // ไม่มี bottomNavigationBar แล้ว เพราะใช้ปุ่ม action เล็กๆ แทน
    );
  }

  Widget _buildMapView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;

        // ตรวจหา safe area และ status bar
        final statusBarHeight = MediaQuery.of(context).padding.top;
        final topPadding = (statusBarHeight * 0.3).clamp(8.0, 20.0);

        if (screenWidth < 600) {
          // Mobile - ใช้พื้นที่เต็มหน้าจอ
          return Column(
            children: [
              // เพิ่มระยะห่างจาก status bar แบบ Dynamic
              SizedBox(height: topPadding),

              // แถบหัวข้อสีม่วง - "แผนที่มหาวิทยาลัย"
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  // ลบ borderRadius ให้เป็นเหลี่ยมตรง
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40), // สร้างสมดุล
                    Expanded(
                      child: Text(
                        'แผนที่มหาวิทยาลัย',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Prompt',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Notification action
                        _showNotifications();
                      },
                      child: Icon(
                        Icons.notifications,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),

              // พื้นที่แผนที่หลัก - จะเชื่อมต่อกับ Google Maps (เพิ่มขนาดให้มากขึ้น)
              Expanded(
                child: Stack(
                  children: [
                    // พื้นที่แผนที่หลัก - Google Maps
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: GoogleMap(
                            onMapCreated: (GoogleMapController controller) {
                              _mapController = controller;
                              debugPrint('✅ Google Maps โหลดสำเร็จ');
                            },
                            initialCameraPosition: const CameraPosition(
                              target: LatLng(
                                13.7563,
                                100.5018,
                              ), // กรุงเทพฯ ใจกลาง
                              zoom: 15.0,
                            ),
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            mapType: MapType.normal,
                            zoomGesturesEnabled: true,
                            scrollGesturesEnabled: true,
                            rotateGesturesEnabled: true,
                            tiltGesturesEnabled: true,
                            onTap: (LatLng position) {
                              debugPrint(
                                '📍 แตะแผนที่ที่: ${position.latitude}, ${position.longitude}',
                              );
                            },
                            gestureRecognizers:
                                <Factory<OneSequenceGestureRecognizer>>{
                                  Factory<OneSequenceGestureRecognizer>(
                                    () => EagerGestureRecognizer(),
                                  ),
                                },
                          ),
                        ),
                      ),
                    ),

                    // ปุ่ม Action กลมๆ ด้านขวา - สำหรับเปลี่ยนไปหน้าอาคาร
                    Positioned(
                      right: 20,
                      bottom: 20,
                      child: BuildingActionButton(
                        onPressed: () {
                          setState(() {
                            currentView = 'building';
                            selectedBuilding ??= 'A';
                            if (selectedBuilding != null) {
                              _loadRoomDataForBuilding(selectedBuilding!);
                            }
                          });
                        },
                        size: 28,
                        elevation: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        } else {
          // Tablet/Desktop - ปรับขนาดให้เหมาะสม
          return Column(
            children: [
              // เพิ่มระยะห่างจาก status bar แบบ Dynamic
              SizedBox(height: (statusBarHeight * 0.4).clamp(16.0, 32.0)),

              // แถบหัวข้อสีม่วง - "แผนที่มหาวิทยาลัย"
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: screenWidth < 900 ? 28 : 32,
                  horizontal: screenWidth < 900 ? 32 : 40,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(width: screenWidth < 900 ? 50 : 60), // สร้างสมดุล
                    Expanded(
                      child: Text(
                        'แผนที่มหาวิทยาลัย',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: screenWidth < 900 ? 28 : 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Prompt',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Notification action
                        _showNotifications();
                      },
                      child: Icon(
                        Icons.notifications,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: screenWidth < 900 ? 32 : 36,
                      ),
                    ),
                  ],
                ),
              ),

              // พื้นที่แผนที่หลัก - จะเชื่อมต่อกับ Google Maps (เพิ่มขนาดให้มากขึ้น)
              Expanded(
                child: Stack(
                  children: [
                    // พื้นที่แผนที่หลัก
                    Padding(
                      padding: EdgeInsets.all(screenWidth < 900 ? 24 : 32),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.secondary.withOpacity(0.1),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.map,
                                    size: 100,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 24),
                                  Text(
                                    'แผนที่มหาวิทยาลัย\n(จะเชื่อมต่อกับ Google Maps)',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ปุ่ม Action กลมๆ ด้านขวา - สำหรับเปลี่ยนไปหน้าอาคาร
                    Positioned(
                      right: screenWidth < 900 ? 28 : 36,
                      bottom: screenWidth < 900 ? 28 : 36,
                      child: BuildingActionButton(
                        onPressed: () {
                          setState(() {
                            currentView = 'building';
                            selectedBuilding ??= 'A';
                            if (selectedBuilding != null) {
                              _loadRoomDataForBuilding(selectedBuilding!);
                            }
                          });
                        },
                        size: screenWidth < 900 ? 32 : 36,
                        elevation: 10,
                      ),
                    ),
                  ],
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
        final screenHeight = MediaQuery.of(context).size.height;

        // ตรวจหา safe area และ status bar
        final statusBarHeight = MediaQuery.of(context).padding.top;

        // คำนวณระยะห่างที่เหมาะสม
        final topPadding = (statusBarHeight * 0.3).clamp(
          8.0,
          20.0,
        ); // 30% ของ status bar แต่ไม่เกิน 20
        final headerHeight = screenHeight * 0.08; // 8% ของความสูงหน้าจอ
        final tabHeight = screenHeight * 0.06; // 6% ของความสูงหน้าจอ

        if (screenWidth < 600) {
          // Mobile layout - ใช้ Dynamic sizing
          return Column(
            children: [
              // เพิ่มระยะห่างจาก status bar แบบ Dynamic
              SizedBox(height: topPadding),

              // Zone Header - ขนาด Dynamic
              Container(
                width: double.infinity,
                height: headerHeight,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.06, // 6% ของความกว้างหน้าจอ
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  // ลบ borderRadius ให้เป็นเหลี่ยมตรง
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40), // สร้างสมดุล
                    Expanded(
                      child: Text(
                        'ผังอาคาร',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: (headerHeight * 0.4).clamp(
                            20.0,
                            28.0,
                          ), // 40% ของ header height
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Prompt',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Notification action
                        _showNotifications();
                      },
                      child: Icon(
                        Icons.notifications,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),

              // Zone Tabs - ขนาด Dynamic และชิดหัว
              Container(
                height: tabHeight,
                margin: EdgeInsets.zero, // ไม่มีเว้นช่องเลย
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondary.withOpacity(0.3),
                  borderRadius: BorderRadius.zero, // ไม่มีความโค้งมน
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedBuilding = 'A';
                          });
                          _pageController.animateToPage(
                            0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                          _loadRoomDataForBuilding('A');
                        },
                        child: Container(
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color:
                                selectedBuilding == 'A'
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                            borderRadius: BorderRadius.zero, // ไม่มีความโค้งมน
                          ),
                          child: Center(
                            child: Text(
                              'โซน A',
                              style: TextStyle(
                                color:
                                    selectedBuilding == 'A'
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.onPrimary
                                        : Theme.of(context).colorScheme.primary,
                                fontSize: (tabHeight * 0.4).clamp(
                                  12.0,
                                  18.0,
                                ), // 40% ของ tab height
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Prompt',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedBuilding = 'B';
                          });
                          _pageController.animateToPage(
                            1,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                          _loadRoomDataForBuilding('B');
                        },
                        child: Container(
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color:
                                selectedBuilding == 'B'
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                            borderRadius: BorderRadius.zero, // ไม่มีความโค้งมน
                          ),
                          child: Center(
                            child: Text(
                              'โซน B',
                              style: TextStyle(
                                color:
                                    selectedBuilding == 'B'
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.onPrimary
                                        : Theme.of(context).colorScheme.primary,
                                fontSize: (tabHeight * 0.4).clamp(
                                  12.0,
                                  18.0,
                                ), // 40% ของ tab height
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Prompt',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // PageView สำหรับแสดงผังอาคาร - ระยะห่าง Dynamic
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    if (!mounted) return;
                    setState(() {
                      selectedBuilding = index == 0 ? 'A' : 'B';
                    });
                    _loadRoomDataForBuilding(selectedBuilding!);
                  },
                  children: [
                    // หน้า 1: Zone A - กล่องครอบอาคารเต็มหน้าจอ
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          // อาคารเต็มพื้นที่ - ขยายให้เต็ม Container
                          Positioned.fill(child: FloorPlanA()),
                          // ปุ่ม Action กลมๆ ด้านขวา - สำหรับเปลี่ยนไปหน้าแผนที่
                          Positioned(
                            right: 20,
                            bottom: 20,
                            child: MapActionButton(
                              onPressed: () {
                                setState(() {
                                  currentView = 'map';
                                  selectedBuilding = null;
                                });
                              },
                              size: 28,
                              elevation: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // หน้า 2: Zone B - กล่องครอบอาคารเต็มหน้าจอ
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          // อาคารเต็มพื้นที่ - ขยายให้เต็ม Container
                          Positioned.fill(child: FloorPlanB()),
                          // ปุ่ม Action กลมๆ ด้านขวา - สำหรับเปลี่ยนไปหน้าแผนที่
                          Positioned(
                            right: 20,
                            bottom: 20,
                            child: MapActionButton(
                              onPressed: () {
                                setState(() {
                                  currentView = 'map';
                                  selectedBuilding = null;
                                });
                              },
                              size: 28,
                              elevation: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        } else {
          // Tablet/Desktop layout - ใช้ Dynamic sizing เช่นกัน
          return Column(
            children: [
              // เพิ่มระยะห่างจาก status bar แบบ Dynamic
              SizedBox(height: (statusBarHeight * 0.4).clamp(16.0, 32.0)),

              // Zone Header - ขนาด Dynamic
              Container(
                width: double.infinity,
                height:
                    headerHeight *
                    1.2, // เพิ่มขนาดเล็กน้อยสำหรับ tablet/desktop
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04, // 4% ของความกว้างหน้าจอ
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  // ลบ borderRadius ให้เป็นเหลี่ยมตรง
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(width: screenWidth < 900 ? 50 : 60), // สร้างสมดุล
                    Expanded(
                      child: Text(
                        'ผังอาคาร',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: (headerHeight * 0.5).clamp(
                            24.0,
                            40.0,
                          ), // 50% ของ header height
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Prompt',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Notification action
                        _showNotifications();
                      },
                      child: Icon(
                        Icons.notifications,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: screenWidth < 900 ? 32 : 36,
                      ),
                    ),
                  ],
                ),
              ),

              // Zone Tabs - ขนาด Dynamic และชิดหัว
              Container(
                height:
                    tabHeight * 1.3, // เพิ่มขนาดเล็กน้อยสำหรับ tablet/desktop
                margin: EdgeInsets.zero, // ไม่มีเว้นช่องเลย
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondary.withOpacity(0.3),
                  borderRadius: BorderRadius.zero, // ไม่มีความโค้งมน
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedBuilding = 'A';
                          });
                          _pageController.animateToPage(
                            0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                          _loadRoomDataForBuilding('A');
                        },
                        child: Container(
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color:
                                selectedBuilding == 'A'
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                            borderRadius: BorderRadius.zero, // ไม่มีความโค้งมน
                          ),
                          child: Center(
                            child: Text(
                              'โซน A',
                              style: TextStyle(
                                color:
                                    selectedBuilding == 'A'
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.onPrimary
                                        : Theme.of(context).colorScheme.primary,
                                fontSize: (tabHeight * 0.5).clamp(
                                  16.0,
                                  24.0,
                                ), // 50% ของ tab height
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Prompt',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedBuilding = 'B';
                          });
                          _pageController.animateToPage(
                            1,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                          _loadRoomDataForBuilding('B');
                        },
                        child: Container(
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color:
                                selectedBuilding == 'B'
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                            borderRadius: BorderRadius.zero, // ไม่มีความโค้งมน
                          ),
                          child: Center(
                            child: Text(
                              'โซน B',
                              style: TextStyle(
                                color:
                                    selectedBuilding == 'B'
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.onPrimary
                                        : Theme.of(context).colorScheme.primary,
                                fontSize: (tabHeight * 0.5).clamp(
                                  16.0,
                                  24.0,
                                ), // 50% ของ tab height
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Prompt',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // PageView สำหรับแสดงผังอาคาร - ระยะห่าง Dynamic
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      selectedBuilding = index == 0 ? 'A' : 'B';
                    });
                    _loadRoomDataForBuilding(selectedBuilding!);
                  },
                  children: [
                    // หน้า 1: Zone A - กล่องครอบอาคารเต็มหน้าจอ (Tablet/Desktop)
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          // อาคารเต็มพื้นที่
                          FloorPlanA(),
                          // ปุ่ม Action กลมๆ ด้านขวา - สำหรับเปลี่ยนไปหน้าแผนที่
                          Positioned(
                            right: screenWidth < 900 ? 28 : 36,
                            bottom: screenWidth < 900 ? 28 : 36,
                            child: MapActionButton(
                              onPressed: () {
                                setState(() {
                                  currentView = 'map';
                                  selectedBuilding = null;
                                });
                              },
                              size: screenWidth < 900 ? 32 : 36,
                              elevation: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // หน้า 2: Zone B - กล่องครอบอาคารเต็มหน้าจอ (Tablet/Desktop)
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          // อาคารเต็มพื้นที่ - ขยายให้เต็ม Container
                          Positioned.fill(child: FloorPlanB()),
                          // ปุ่ม Action กลมๆ ด้านขวา - สำหรับเปลี่ยนไปหน้าแผนที่
                          Positioned(
                            right: screenWidth < 900 ? 28 : 36,
                            bottom: screenWidth < 900 ? 28 : 36,
                            child: MapActionButton(
                              onPressed: () {
                                setState(() {
                                  currentView = 'map';
                                  selectedBuilding = null;
                                });
                              },
                              size: screenWidth < 900 ? 32 : 36,
                              elevation: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
      },
    );
  }
}
