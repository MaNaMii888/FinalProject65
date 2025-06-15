// campus_navigation.dart
import 'package:flutter/material.dart';
import 'package:project01/Screen/page/map/mapmodel/building_data.dart'; // Make sure this path is correct

// CustomPainter สำหรับวาดผังอาคาร A
class FloorPlanAPainter extends CustomPainter {
  // Add constants for configuration
  static const double ORIGINAL_SVG_HEIGHT = 500.0;
  static const double FONT_SIZE = 12.0;
  static const double STROKE_WIDTH = 2.0;
  static const double HIGHLIGHT_STROKE_WIDTH = 3.0;

  final String? findRequest; // สำหรับไฮไลท์ห้องที่ค้นหา

  FloorPlanAPainter({this.findRequest});

  /// Draw a room on the canvas with specified parameters
  void _drawRoom(
    Canvas canvas,
    Rect originalRect, // รับ Rect ที่เป็นค่าพิกัดเดิมจาก SVG
    String roomId,
    String roomName,
    Paint fill,
    Paint border,
    double scaleFactor, // เพิ่ม scaleFactor
    Paint highlightPaint, // เพิ่ม Paint สำหรับ Highlight
    Paint highlightBorderPaint, // เพิ่ม Paint สำหรับ Highlight Border
    String? highlightRequest, // ไม่ shadow ชื่อ findRequest
  ) {
    bool isHighlighted =
        highlightRequest != null &&
        (roomName.toLowerCase().contains(highlightRequest.toLowerCase()) ||
            roomId.toLowerCase() == highlightRequest.toLowerCase());

    // Apply scaling to the rectangle coordinates
    final Rect scaledRect = Rect.fromLTWH(
      originalRect.left * scaleFactor,
      originalRect.top * scaleFactor,
      originalRect.width * scaleFactor,
      originalRect.height * scaleFactor,
    );

    canvas.drawRect(scaledRect, isHighlighted ? highlightPaint : fill);
    canvas.drawRect(scaledRect, isHighlighted ? highlightBorderPaint : border);

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: roomName,
        style: TextStyle(
          color: Colors.grey[800],
          fontSize: FONT_SIZE * scaleFactor, // Scale font size as well
          fontWeight: FontWeight.w500,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: scaledRect.width, maxWidth: scaledRect.width);
    textPainter.paint(
      canvas,
      Offset(scaledRect.left, scaledRect.center.dy - textPainter.height / 2),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Paint roomPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xffe3f2fd); // Fill color
    final Paint roomBorderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = STROKE_WIDTH
          ..color = const Color(0xff1976d2); // Border color

    final Paint foodPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xfffff3e0);
    final Paint foodBorderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = STROKE_WIDTH
          ..color = const Color(0xfff57c00);
    final Paint highlightPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.yellow[100]!;
    final Paint highlightBorderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = HIGHLIGHT_STROKE_WIDTH
          ..color = Colors.yellow[400]!;

    // กำหนด scaleFactor: ใช้ความสูงของ Canvas (size.height) เทียบกับความสูงต้นฉบับของ SVG (600)
    final double scaleFactor = size.height / ORIGINAL_SVG_HEIGHT;

    // Building A Rooms - ใช้ _drawRoom พร้อม scaleFactor
    _drawRoom(
      canvas,
      const Rect.fromLTWH(150, 20, 100, 40),
      '7',
      '7',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
      findRequest,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(160, 80, 80, 60),
      '6',
      '6',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
      findRequest,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(30, 80, 40, 60),
      '8',
      '8',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
      findRequest,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(340, 80, 40, 60),
      '5',
      '5',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
      findRequest,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(20, 160, 60, 80),
      '9',
      '9',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
      findRequest,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(160, 160, 80, 60),
      '2',
      '2',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
      findRequest,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(340, 150, 40, 80),
      '4',
      '4',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
      findRequest,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(160, 240, 80, 60),
      '1',
      '1',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
      findRequest,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(340, 240, 40, 80),
      '3',
      '3',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
      findRequest,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(20, 260, 50, 80),
      '10',
      '10',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
      findRequest,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(160, 305, 80, 60),
      'food',
      'โรงอาหาร',
      foodPaint,
      foodBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
      findRequest,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(340, 360, 40, 120),
      '12',
      '12',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
      findRequest,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(10, 360, 60, 120),
      '11',
      '11',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
      findRequest,
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

  /// Draw a room on the canvas with specified parameters
  void _drawRoom(
    Canvas canvas,
    Rect originalRect,
    String roomId,
    String roomName,
    Paint fill,
    Paint border,
    double scaleFactor,
    Paint highlightPaint,
    Paint highlightBorderPaint,
  ) {
    bool isHighlighted =
        findRequest != null &&
        (roomName.toLowerCase().contains(findRequest!.toLowerCase()) ||
            roomId.toLowerCase() == findRequest!.toLowerCase());

    final Rect scaledRect = Rect.fromLTWH(
      originalRect.left * scaleFactor,
      originalRect.top * scaleFactor,
      originalRect.width * scaleFactor,
      originalRect.height * scaleFactor,
    );

    canvas.drawRect(scaledRect, isHighlighted ? highlightPaint : fill);
    canvas.drawRect(scaledRect, isHighlighted ? highlightBorderPaint : border);

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: roomName,
        style: TextStyle(
          color: Colors.grey[800],
          fontSize: 12 * scaleFactor, // Scale font size as well
          fontWeight: FontWeight.w500,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: scaledRect.width, maxWidth: scaledRect.width);
    textPainter.paint(
      canvas,
      Offset(scaledRect.left, scaledRect.center.dy - textPainter.height / 2),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Paints
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

    // กำหนด scaleFactor: ใช้ความสูงของ Canvas (size.height) เทียบกับความสูงต้นฉบับของ SVG (350)
    final double scaleFactor =
        size.height / 350.0; // Original SVG viewBox height for Building B

    // Building B Rooms - ใช้ _drawRoom พร้อม scaleFactor
    _drawRoom(
      canvas,
      const Rect.fromLTWH(20, 20, 50, 30),
      '28',
      '28',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(20, 60, 40, 50),
      '19',
      '19',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(70, 60, 60, 30),
      '20',
      '20',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(140, 40, 40, 70),
      '22',
      '22',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(190, 20, 60, 50),
      '24',
      '24',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(270, 40, 40, 40),
      '26',
      '26',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(190, 80, 80, 40),
      '27',
      '27',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(20, 130, 60, 40),
      '17',
      '17',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(90, 130, 80, 60),
      '18',
      '18',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(290, 120, 40, 50),
      '31',
      '31',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(220, 140, 60, 40),
      '29',
      '29',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(20, 190, 40, 40),
      '15',
      '15',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(70, 200, 40, 30),
      '16',
      '16',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(220, 190, 60, 50),
      '30',
      '30',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(120, 250, 100, 60),
      'lobby',
      'สนาม',
      lobbyPaint,
      lobbyBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(120, 320, 60, 20),
      '33',
      '33',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is FloorPlanBPainter &&
        oldDelegate.findRequest != findRequest;
  }
}

// ... keep existing code (CampusNavigation and other widget classes remain the same)

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
                            _MapView()
                          else
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
                                const SizedBox(height: 16),

                                if (selectedBuilding == 'A')
                                  _FloorPlanA(findRequest: findRequest)
                                else if (selectedBuilding == 'B')
                                  _FloorPlanB(findRequest: findRequest)
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

// ... keep existing code (all other widget classes remain exactly the same)

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
          backgroundColor: Colors.blue[600],
          hoverColor: Colors.blue[700],
          foregroundColor: Colors.white,
          elevation: 6,
          child: const Icon(Icons.navigation),
        ),
        if (showPopup)
          Container(
            margin: const EdgeInsets.only(top: 16),
            width: 192,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(color: Colors.grey[200]!),
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
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey[400],
                      ),
                      onPressed: onTogglePopup,
                      splashRadius: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPopupOption(
                      icon: Icons.map,
                      text: 'แผนที่มหาวิทยาลัย',
                      isSelected: currentView == 'map',
                      onTap: () => onSelectView('map'),
                    ),
                    const SizedBox(height: 8),
                    _buildPopupOption(
                      icon: Icons.apartment,
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
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue[300]! : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
          color: isSelected ? Colors.blue[100] : Colors.grey[50],
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
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.blue[700] : Colors.grey[700],
                fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'เลือกอาคาร',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children:
                buildingData.keys.map((buildingKey) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ElevatedButton(
                      onPressed: () => onSelectBuilding(buildingKey),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            selectedBuilding == buildingKey
                                ? Colors.blue[600]
                                : Colors.grey[100],
                        foregroundColor:
                            selectedBuilding == buildingKey
                                ? Colors.white
                                : Colors.grey[700],
                        shadowColor:
                            selectedBuilding == buildingKey
                                ? Colors.blue[300]
                                : Colors.transparent,
                        elevation: selectedBuilding == buildingKey ? 4 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w500),
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
            'อาคาร A - ผังอาคาร',
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
            height: 384,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomPaint(
              painter: FloorPlanAPainter(findRequest: findRequest),
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
                '🔍 กำลังค้นหา: $findRequest',
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
            height: 320,
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
                '🔍 กำลังค้นหา: $findRequest',
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
            'แผนที่มหาวิทยาลัย',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            height: 384,
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[300]!, width: 2),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 64, color: Colors.green[600]),
                  const SizedBox(height: 16),
                  Text(
                    'แผนที่ภาพรวมมหาวิทยาลัย',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
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
