// campus_navigation.dart
import 'package:flutter/material.dart';
import 'package:project01/Screen/page/map/mapmodel/building_data.dart'; // Make sure this path is correct
// campus_navigation.dart

// CustomPainter สำหรับวาดผังอาคาร A
class FloorPlanAPainter extends CustomPainter {
  final String? findRequest; // สำหรับไฮไลท์ห้องที่ค้นหา

  FloorPlanAPainter({this.findRequest});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint roomPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xffe3f2fd); // Fill color
    final Paint roomBorderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xff1976d2); // Border color

    final Paint foodPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xfffff3e0);
    final Paint foodBorderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xfff57c00);

    final Paint libraryOfficePaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xffe8f5e8);
    final Paint libraryOfficeBorderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xff388e3c);

    final Paint officeSpecificPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xfffce4ec);
    final Paint officeSpecificBorderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xffc2185b);

    final Paint highlightPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.yellow[100]!;
    final Paint highlightBorderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.yellow[400]!;

    void drawRoom(
      String roomId,
      String roomName,
      Rect rect,
      Paint fill,
      Paint border,
    ) {
      bool isHighlighted =
          findRequest != null &&
          (roomName.toLowerCase().contains(findRequest!.toLowerCase()) ||
              roomId.toLowerCase() == findRequest!.toLowerCase());

      canvas.drawRect(rect, isHighlighted ? highlightPaint : fill);
      canvas.drawRect(rect, isHighlighted ? highlightBorderPaint : border);

      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: roomName,
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 12, // Adjusted for Flutter text scale
            fontWeight: FontWeight.w500,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(minWidth: rect.width, maxWidth: rect.width);
      textPainter.paint(
        canvas,
        Offset(rect.left, rect.center.dy - textPainter.height / 2),
      );
    }

    // Building A Rooms
    drawRoom(
      '7',
      '7',
      const Rect.fromLTWH(50, 20, 100, 40),
      roomPaint,
      roomBorderPaint,
    );
    drawRoom(
      '6',
      '6',
      const Rect.fromLTWH(80, 80, 50, 40),
      roomPaint,
      roomBorderPaint,
    );
    drawRoom(
      '8',
      '8',
      const Rect.fromLTWH(30, 80, 40, 60),
      roomPaint,
      roomBorderPaint,
    );
    drawRoom(
      '5',
      '5',
      const Rect.fromLTWH(140, 80, 40, 60),
      roomPaint,
      roomBorderPaint,
    );
    drawRoom(
      '9',
      '9',
      const Rect.fromLTWH(20, 160, 60, 80),
      roomPaint,
      roomBorderPaint,
    );
    drawRoom(
      '2',
      '2',
      const Rect.fromLTWH(90, 160, 60, 60),
      roomPaint,
      roomBorderPaint,
    );
    drawRoom(
      '4',
      '4',
      const Rect.fromLTWH(160, 140, 50, 80),
      roomPaint,
      roomBorderPaint,
    );
    drawRoom(
      '1',
      '1',
      const Rect.fromLTWH(90, 240, 40, 80),
      roomPaint,
      roomBorderPaint,
    );
    drawRoom(
      '3',
      '3',
      const Rect.fromLTWH(140, 240, 60, 100),
      roomPaint,
      roomBorderPaint,
    );
    drawRoom(
      '10',
      '10',
      const Rect.fromLTWH(20, 260, 50, 80),
      roomPaint,
      roomBorderPaint,
    );
    drawRoom(
      'food',
      'โรงอาหาร',
      const Rect.fromLTWH(90, 340, 60, 30),
      foodPaint,
      foodBorderPaint,
    );
    drawRoom(
      '12',
      '12',
      const Rect.fromLTWH(220, 360, 40, 120),
      roomPaint,
      roomBorderPaint,
    );
    drawRoom(
      '11',
      '11',
      const Rect.fromLTWH(20, 360, 120, 60),
      roomPaint,
      roomBorderPaint,
    );
    drawRoom(
      'library',
      'ห้องสมุด',
      const Rect.fromLTWH(280, 480, 60, 40),
      libraryOfficePaint,
      libraryOfficeBorderPaint,
    );
    drawRoom(
      'office',
      'สำนักงาน',
      const Rect.fromLTWH(350, 480, 40, 40),
      officeSpecificPaint,
      officeSpecificBorderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is FloorPlanAPainter &&
        oldDelegate.findRequest != findRequest;
  }
}

// CustomPainter สำหรับวาดผังอาคาร B
class FloorPlanBPainter extends CustomPainter {
  final String? findRequest;

  FloorPlanBPainter({this.findRequest});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint roomPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xffe3f2fd);
    final Paint roomBorderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xff1976d2);

    final Paint lobbyPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xffe8f5e8);
    final Paint lobbyBorderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xff388e3c);

    final Paint highlightPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.yellow[100]!;
    final Paint highlightBorderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.yellow[400]!;

    void drawRoom(
      String roomId,
      String roomName,
      Rect rect,
      Paint fill,
      Paint border,
    ) {
      bool isHighlighted =
          findRequest != null &&
          (roomName.toLowerCase().contains(findRequest!.toLowerCase()) ||
              roomId.toLowerCase() == findRequest!.toLowerCase());

      canvas.drawRect(rect, isHighlighted ? highlightPaint : fill);
      canvas.drawRect(rect, isHighlighted ? highlightBorderPaint : border);

      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: roomName,
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(minWidth: rect.width, maxWidth: rect.width);
      textPainter.paint(
        canvas,
        Offset(rect.left, rect.center.dy - textPainter.height / 2),
      );
    }

    // Building B Rooms
    drawRoom(
      '28',
      '28',
      const Rect.fromLTWH(20, 20, 50, 30),
      roomPaint,
      roomBorderPaint,
    );
    drawRoom(
      '19',
      '19',
      const Rect.fromLTWH(20, 60, 40, 50),
      roomPaint,
      roomBorderPaint,
    );
    drawRoom(
      '20',
      '20',
      const Rect.fromLTWH(70, 60, 60, 30),
      roomPaint,
      roomBorderPaint,
    );
    drawRoom(
      '22',
      '22',
      const Rect.fromLTWH(140, 40, 40, 70),
      roomPaint,
      roomBorderPaint,
    );
    drawRoom(
      '24',
      '24',
      const Rect.fromLTWH(190, 20, 60, 50),
      roomPaint,
      roomBorderPaint,
    );
    drawRoom(
      '26',
      '26',
      const Rect.fromLTWH(270, 40, 40, 40),
      roomPaint,
      roomBorderPaint,
    );
    drawRoom(
      '27',
      '27',
      const Rect.fromLTWH(190, 80, 80, 40),
      roomPaint,
      roomBorderPaint,
    );
    drawRoom(
      '17',
      '17',
      const Rect.fromLTWH(20, 130, 60, 40),
      roomPaint,
      roomBorderPaint,
    );
    drawRoom(
      '18',
      '18',
      const Rect.fromLTWH(90, 130, 80, 60),
      roomPaint,
      roomBorderPaint,
    );
    drawRoom(
      '31',
      '31',
      const Rect.fromLTWH(290, 120, 40, 50),
      roomPaint,
      roomBorderPaint,
    );
    drawRoom(
      '29',
      '29',
      const Rect.fromLTWH(220, 140, 60, 40),
      roomPaint,
      roomBorderPaint,
    );
    drawRoom(
      '15',
      '15',
      const Rect.fromLTWH(20, 190, 40, 40),
      roomPaint,
      roomBorderPaint,
    );
    drawRoom(
      '16',
      '16',
      const Rect.fromLTWH(70, 200, 40, 30),
      roomPaint,
      roomBorderPaint,
    );
    drawRoom(
      '30',
      '30',
      const Rect.fromLTWH(220, 190, 60, 50),
      roomPaint,
      roomBorderPaint,
    );
    drawRoom(
      'lobby',
      'สนาม',
      const Rect.fromLTWH(120, 250, 100, 60),
      lobbyPaint,
      lobbyBorderPaint,
    );
    drawRoom(
      '33',
      '33',
      const Rect.fromLTWH(120, 320, 60, 20),
      roomPaint,
      roomBorderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is FloorPlanBPainter &&
        oldDelegate.findRequest != findRequest;
  }
}

class CampusNavigation extends StatefulWidget {
  // สำหรับ mobile app, คุณสามารถส่ง findRequest ผ่าน constructor ได้
  // เช่น Navigator.push(context, MaterialPageRoute(builder: (context) => CampusNavigation(findRequest: 'ห้อง 15')));
  final String? initialFindRequest;

  const CampusNavigation({super.key, this.initialFindRequest});

  @override
  State<CampusNavigation> createState() => _CampusNavigationState();
}

class _CampusNavigationState extends State<CampusNavigation> {
  String currentView = 'map'; // 'map' or 'building'
  String? selectedBuilding; // 'A', 'B', or null
  String findRequest = '';
  bool showPopup = false;

  @override
  void initState() {
    super.initState();
    // ใช้ initialFindRequest จาก constructor สำหรับ mobile app
    if (widget.initialFindRequest != null &&
        widget.initialFindRequest!.isNotEmpty) {
      findRequest = widget.initialFindRequest!;
      _processFindRequest(findRequest);
    }
  }

  // แยก Logic สำหรับการประมวลผล findRequest
  void _processFindRequest(String request) {
    setState(() {
      findRequest = request;
    });

    // Auto-detect which building contains the requested room
    buildingData.forEach((buildingKey, building) {
      final room = building.rooms.firstWhere(
        (r) =>
            r.name.toLowerCase().contains(request.toLowerCase()) ||
            r.id.toString().toLowerCase() == request.toLowerCase(),
        orElse:
            () => Room(
              id: '',
              name: '',
              type: '',
            ), // Return a dummy room if not found
      );
      if (room.id != '') {
        // Check if a real room was found
        setState(() {
          selectedBuilding = buildingKey;
          currentView = 'building';
        });
        return; // Exit forEach once found
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Equivalent to bg-gray-50
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0), // Equivalent to p-4
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 60), // Space for the floating button
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 768,
                      ), // max-w-4xl mx-auto
                      child: Column(
                        children: [
                          // Header Section
                          Container(
                            margin: const EdgeInsets.only(bottom: 24), // mb-6
                            child: Column(
                              children: [
                                Text(
                                  'ระบบนำทางมหาวิทยาลัย',
                                  style: TextStyle(
                                    fontSize: 28, // text-3xl
                                    fontWeight: FontWeight.bold, // font-bold
                                    color: Colors.grey[800], // text-gray-800
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8), // mb-2
                                Text(
                                  currentView == 'map'
                                      ? 'แผนที่ภาพรวม'
                                      : 'ผังอาคารแยกตามชั้น',
                                  style: TextStyle(
                                    color: Colors.grey[600], // text-gray-600
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          // Main Content based on currentView
                          if (currentView == 'map')
                            _MapView()
                          else // currentView === 'building'
                            Column(
                              children: [
                                _BuildingSelector(
                                  selectedBuilding: selectedBuilding,
                                  onSelectBuilding: (buildingKey) {
                                    setState(() {
                                      selectedBuilding = buildingKey;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16), // space-y-4

                                if (selectedBuilding == 'A')
                                  _FloorPlanA(findRequest: findRequest)
                                else if (selectedBuilding == 'B')
                                  _FloorPlanB(findRequest: findRequest)
                                else // !selectedBuilding
                                  Container(
                                    padding: const EdgeInsets.all(32), // p-8
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        8,
                                      ), // rounded-lg
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
                                        ), // Building icon
                                        const SizedBox(height: 16), // mb-4
                                        Text(
                                          'กรุณาเลือกอาคารที่ต้องการดู',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Room List (only for building view)
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
          // View Selector (fixed position)
          Positioned(
            top: 16, // top-4
            right: 16, // right-4
            child: _ViewSelector(
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

// --- Sub-Widgets (Same as before) ---

class _ViewSelector extends StatelessWidget {
  final String currentView;
  final bool showPopup;
  final VoidCallback onTogglePopup;
  final ValueChanged<String> onSelectView;

  const _ViewSelector({
    required this.currentView,
    required this.showPopup,
    required this.onTogglePopup,
    required this.onSelectView,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton(
          onPressed: onTogglePopup,
          backgroundColor: Colors.blue[600], // bg-blue-600
          hoverColor: Colors.blue[700], // hover:bg-blue-700
          foregroundColor: Colors.white, // text-white
          elevation: 6, // shadow-lg
          child: const Icon(Icons.navigation), // Navigation icon
        ),
        if (showPopup)
          Container(
            margin: const EdgeInsets.only(
              top: 16,
            ), // top-16 right-0 (offset from button)
            width: 192, // min-w-48 (48 * 4 = 192)
            padding: const EdgeInsets.all(16), // p-4
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8), // rounded-lg
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(color: Colors.grey[200]!), // border
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'เลือกมุมมอง',
                      style: TextStyle(
                        fontWeight: FontWeight.w600, // font-semibold
                        color: Colors.grey[800], // text-gray-800
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey[400],
                      ), // X icon
                      onPressed: onTogglePopup,
                      splashRadius: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12), // mb-3
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPopupOption(
                      icon: Icons.map, // Map icon
                      text: 'แผนที่มหาวิทยาลัย',
                      isSelected: currentView == 'map',
                      onTap: () => onSelectView('map'),
                    ),
                    const SizedBox(height: 8), // space-y-2
                    _buildPopupOption(
                      icon: Icons.apartment, // Building icon
                      text: 'ภายในอาคาร',
                      isSelected: currentView == 'building',
                      onTap: () => onSelectView('building'),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPopupOption({
    required IconData icon,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity, // w-full
        padding: const EdgeInsets.all(12), // p-3
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8), // rounded-lg
          border: Border.all(
            color:
                isSelected
                    ? Colors.blue[300]!
                    : Colors.transparent, // border-2 border-blue-300
            width: isSelected ? 2 : 0,
          ),
          color:
              isSelected
                  ? Colors.blue[100]
                  : Colors.grey[50], // bg-blue-100 or bg-gray-50
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ]
                  : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.blue[700] : Colors.grey[700],
            ), // Icon color
            const SizedBox(width: 12), // gap-3
            Text(
              text,
              style: TextStyle(
                color:
                    isSelected
                        ? Colors.blue[700]
                        : Colors.grey[700], // text color
                fontWeight: FontWeight.w500, // font-medium
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuildingSelector extends StatelessWidget {
  final String? selectedBuilding;
  final ValueChanged<String> onSelectBuilding;

  const _BuildingSelector({
    required this.selectedBuilding,
    required this.onSelectBuilding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16), // p-4
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8), // rounded-lg
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'เลือกอาคาร',
            style: TextStyle(
              fontSize: 18, // text-lg
              fontWeight: FontWeight.w600, // font-semibold
              color: Colors.grey[800], // text-gray-800
            ),
          ),
          const SizedBox(height: 12), // mb-3
          Row(
            mainAxisAlignment: MainAxisAlignment.start, // flex gap-2
            children:
                buildingData.keys.map((buildingKey) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0), // gap-2
                    child: ElevatedButton(
                      onPressed: () => onSelectBuilding(buildingKey),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            selectedBuilding == buildingKey
                                ? Colors.blue[600] // bg-blue-600
                                : Colors.grey[100], // bg-gray-100
                        foregroundColor:
                            selectedBuilding == buildingKey
                                ? Colors
                                    .white // text-white
                                : Colors.grey[700], // text-gray-700
                        shadowColor:
                            selectedBuilding == buildingKey
                                ? Colors.blue[300] // shadow-md
                                : Colors.transparent,
                        elevation: selectedBuilding == buildingKey ? 4 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8), // rounded-lg
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ), // px-4 py-2
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ), // font-medium
                      ),
                      child: Text(buildingData[buildingKey]!.name),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}

class _FloorPlanA extends StatelessWidget {
  final String? findRequest;
  const _FloorPlanA({this.findRequest});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32), // p-8
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8), // rounded-lg
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
          Text(
            'อาคาร A - ผังอาคาร',
            style: TextStyle(
              fontSize: 20, // text-xl
              fontWeight: FontWeight.bold, // font-bold
              color: Colors.grey[800], // text-gray-800
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16), // mb-4
          Container(
            width: double.infinity, // w-full
            height: 384, // h-96 (96 * 4 = 384)
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey[300]!,
              ), // border border-gray-300
              borderRadius: BorderRadius.circular(8), // rounded
            ),
            child: CustomPaint(
              painter: FloorPlanAPainter(findRequest: findRequest),
            ),
          ),
          if (findRequest != null && findRequest!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 16), // mt-4
              padding: const EdgeInsets.all(12), // p-3
              decoration: BoxDecoration(
                color: Colors.yellow[100], // bg-yellow-100
                borderRadius: BorderRadius.circular(8), // rounded-lg
              ),
              child: Text(
                '🔍 กำลังค้นหา: ${findRequest!}',
                style: TextStyle(
                  fontSize: 14, // text-sm
                  color: Colors.yellow[800], // text-yellow-800
                  fontWeight: FontWeight.w600, // font-semibold for the span
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FloorPlanB extends StatelessWidget {
  final String? findRequest;
  const _FloorPlanB({this.findRequest});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            'อาคาร B - ผังอาคาร',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 320, // h-80 (80 * 4 = 320)
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomPaint(
              painter: FloorPlanBPainter(findRequest: findRequest),
            ),
          ),
          if (findRequest != null && findRequest!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '🔍 กำลังค้นหา: ${findRequest!}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.yellow[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32), // p-8
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8), // rounded-lg
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
          Text(
            'แผนที่มหาวิทยาลัย',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16), // mb-4
          Container(
            height: 384, // h-96
            decoration: BoxDecoration(
              color: Colors.green[100], // bg-green-100
              borderRadius: BorderRadius.circular(8), // rounded-lg
              border: Border.all(
                color: Colors.green[300]!,
                width: 2,
              ), // border-2 border-green-300
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 64,
                    color: Colors.green[600],
                  ), // Map icon
                  const SizedBox(height: 16), // mb-4
                  Text(
                    'แผนที่ภาพรวมมหาวิทยาลัย',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8), // mt-2
                  Text(
                    'คลิกที่ปุ่ม Navigation เพื่อเลือกดูภายในอาคาร',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
