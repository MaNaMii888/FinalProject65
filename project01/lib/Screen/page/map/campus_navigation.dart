// campus_navigation.dart
import 'package:flutter/material.dart';
import 'package:project01/Screen/page/map/mapmodel/building_data.dart'; // Make sure this path is correct
import 'package:project01/Screen/page/map/widgets/building_selector.dart';
import 'package:project01/Screen/page/map/widgets/floor_plan_a.dart';
import 'package:project01/Screen/page/map/widgets/floor_plan_b.dart';
import 'package:project01/Screen/page/map/widgets/map_view.dart';

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
    // โหลดข้อมูลห้องเมื่อเริ่มต้น
    _loadRoomData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // เพิ่มฟังก์ชันสำหรับโหลดข้อมูลห้อง
  Future<void> _loadRoomData() async {
    if (isLoadingRoomData) return;

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

      setState(() {
        roomDataMap = newRoomDataMap;
        isLoadingRoomData = false;
      });
    } catch (e) {
      debugPrint('Error loading room data: $e');
      setState(() {
        isLoadingRoomData = false;
      });
    }
  }

  // เพิ่มฟังก์ชันสำหรับโหลดข้อมูลห้องสำหรับอาคารเฉพาะ
  Future<void> _loadRoomDataForBuilding(String buildingId) async {
    setState(() {
      isLoadingRoomData = true;
    });

    try {
      final building = buildingData[buildingId];
      if (building != null) {
        final Map<String, RoomData> newRoomDataMap = {};

        for (final room in building.rooms) {
          final roomData = await BuildingDataService.getRoomData(
            buildingId,
            room.id.toString(),
            room.name,
          );
          newRoomDataMap[room.id.toString()] = roomData;
        }

        setState(() {
          roomDataMap = newRoomDataMap;
          isLoadingRoomData = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading room data for building $buildingId: $e');
      setState(() {
        isLoadingRoomData = false;
      });
    }
  }

  void _processFindRequest(String request) {
    if (request.isEmpty) {
      return;
    }

    try {
      setState(() {
        findRequest = request;
      });

      buildingData.forEach((buildingKey, building) {
        final room = building.rooms.firstWhere(
          (r) =>
              r.name.toLowerCase().contains(request.toLowerCase()) ||
              r.id.toString().toLowerCase() == request.toLowerCase(),
          orElse: () => Room(id: '', name: '', type: ''),
        );
        if (room.id != '') {
          setState(() {
            selectedBuilding = buildingKey;
            currentView = 'building';
          });
          // โหลดข้อมูลห้องสำหรับอาคารที่เลือก
          _loadRoomDataForBuilding(buildingKey);
          return;
        }
      });
    } catch (e) {
      debugPrint('Error processing find request: $e');
    }
  }

  void _onBuildingChanged(String buildingKey) {
    setState(() {
      selectedBuilding = buildingKey;
    });

    // โหลดข้อมูลห้องสำหรับอาคารที่เลือก
    _loadRoomDataForBuilding(buildingKey);

    // เลื่อนไปยังหน้าที่เหมาะสม
    if (buildingKey == 'A') {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (buildingKey == 'B') {
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFFFFF),
      appBar: AppBar(
        title: Text(currentView == 'map' ? 'แผนที่มหาวิทยาลัย' : 'ผังอาคาร'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.grey[800],
        actions: [
          // เพิ่มปุ่ม refresh สำหรับโหลดข้อมูลใหม่
          if (currentView == 'building')
            IconButton(
              icon: Icon(
                isLoadingRoomData ? Icons.refresh : Icons.refresh,
                color: isLoadingRoomData ? Colors.grey : Colors.blue,
              ),
              onPressed:
                  isLoadingRoomData
                      ? null
                      : () {
                        if (selectedBuilding != null) {
                          _loadRoomDataForBuilding(selectedBuilding!);
                        }
                      },
            ),
        ],
      ),
      body: currentView == 'map' ? _buildMapView() : _buildBuildingView(),
      // ปรับปรุง BottomNavigationBar ให้มีฟังก์ชันการทำงานที่สมบูรณ์
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavigationButton(
                  icon: Icons.map,
                  label: 'แผนที่',
                  isSelected: currentView == 'map',
                  onTap: () {
                    setState(() {
                      currentView = 'map';
                      selectedBuilding = null;
                    });
                  },
                ),
                _buildNavigationButton(
                  icon: Icons.apartment,
                  label: 'อาคาร',
                  isSelected: currentView == 'building',
                  onTap: () {
                    setState(() {
                      currentView = 'building';
                      if (selectedBuilding == null) {
                        selectedBuilding = 'A'; // Default to building A
                      }
                    });
                    // โหลดข้อมูลห้องเมื่อเปลี่ยนไปดูอาคาร
                    if (selectedBuilding != null) {
                      _loadRoomDataForBuilding(selectedBuilding!);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        if (screenWidth < 600) {
          // Mobile - ใช้พื้นที่เต็มหน้าจอ
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const MapView(),
            ),
          );
        } else if (screenWidth < 900) {
          // Tablet - จำกัดขนาดปานกลาง
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: const MapView(),
            ),
          );
        } else {
          // Desktop - จำกัดขนาดและจัดกึ่งกลาง
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: screenWidth * 0.8,
                maxHeight: screenHeight * 0.7,
              ),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const MapView(),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildBuildingView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;

        if (screenWidth < 600) {
          // Mobile layout
          return Column(
            children: [
              // Building Selector
              Padding(
                padding: const EdgeInsets.all(12),
                child: BuildingSelector(
                  selectedBuilding: selectedBuilding,
                  onSelectBuilding: _onBuildingChanged,
                ),
              ),

              // PageView สำหรับแสดงผังอาคาร
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      selectedBuilding = index == 0 ? 'A' : 'B';
                    });
                    // โหลดข้อมูลห้องเมื่อเปลี่ยนหน้า
                    _loadRoomDataForBuilding(selectedBuilding!);
                  },
                  children: [
                    // หน้า 1: อาคาร A
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: FloorPlanA(
                            findRequest: findRequest,
                            roomDataMap: roomDataMap,
                          ),
                        ),
                      ),
                    ),
                    // หน้า 2: อาคาร B
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: FloorPlanB(
                            findRequest: findRequest,
                            roomDataMap: roomDataMap,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        } else {
          // Tablet/Desktop layout
          return Column(
            children: [
              // Building Selector
              Padding(
                padding: EdgeInsets.all(screenWidth < 900 ? 16 : 24),
                child: BuildingSelector(
                  selectedBuilding: selectedBuilding,
                  onSelectBuilding: _onBuildingChanged,
                ),
              ),

              // PageView สำหรับแสดงผังอาคาร
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      selectedBuilding = index == 0 ? 'A' : 'B';
                    });
                    // โหลดข้อมูลห้องเมื่อเปลี่ยนหน้า
                    _loadRoomDataForBuilding(selectedBuilding!);
                  },
                  children: [
                    // หน้า 1: อาคาร A
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth < 900 ? 16 : 24,
                      ),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: FloorPlanA(
                            findRequest: findRequest,
                            roomDataMap: roomDataMap,
                          ),
                        ),
                      ),
                    ),
                    // หน้า 2: อาคาร B
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth < 900 ? 16 : 24,
                      ),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: FloorPlanB(
                            findRequest: findRequest,
                            roomDataMap: roomDataMap,
                          ),
                        ),
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

  Widget _buildNavigationButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[600] : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
