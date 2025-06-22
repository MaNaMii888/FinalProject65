// campus_navigation.dart
import 'package:flutter/material.dart';
import 'package:project01/Screen/page/map/mapmodel/building_data.dart'; // Make sure this path is correct
import 'package:project01/Screen/page/map/widgets/building_selector.dart';
import 'package:project01/Screen/page/map/widgets/floor_plan_a.dart';
import 'package:project01/Screen/page/map/widgets/floor_plan_b.dart';
import 'package:project01/Screen/page/map/widgets/map_view.dart';
import 'package:project01/Screen/page/map/widgets/view_selector.dart';

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
  bool showPopup = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialFindRequest != null &&
        widget.initialFindRequest!.isNotEmpty) {
      findRequest = widget.initialFindRequest!;
      _processFindRequest(findRequest);
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
          return;
        }
      });
    } catch (e) {
      print('Error processing find request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 100),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 768),
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              children: [
                                Text(
                                  'ระบบนำทางมหาวิทยาลัย',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  currentView == 'map'
                                      ? 'แผนที่ภาพรวม'
                                      : 'ผังอาคารแยกตามชั้น',
                                  style: TextStyle(color: Colors.grey[600]),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          if (currentView == 'map')
                            const MapView()
                          else
                            Column(
                              children: [
                                BuildingSelector(
                                  selectedBuilding: selectedBuilding,
                                  onSelectBuilding: (buildingKey) {
                                    setState(() {
                                      selectedBuilding = buildingKey;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),

                                if (selectedBuilding == 'A')
                                  FloorPlanA(findRequest: findRequest)
                                else if (selectedBuilding == 'B')
                                  FloorPlanB(findRequest: findRequest)
                                else
                                  Container(
                                    padding: const EdgeInsets.all(32),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.2),
                                          spreadRadius: 2,
                                          blurRadius: 5,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.apartment,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'กรุณาเลือกอาคารที่ต้องการดู',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 50,
            right: 16,
            child: ViewSelector(
              currentView: currentView,
              showPopup: showPopup,
              onTogglePopup: () {
                setState(() {
                  showPopup = !showPopup;
                });
              },
              onSelectView: (view) {
                setState(() {
                  currentView = view;
                  showPopup = false;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
