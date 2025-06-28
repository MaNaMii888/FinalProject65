import 'package:flutter/material.dart';
import 'package:project01/Screen/page/map/mapmodel/building_data.dart';

class BuildingSelector extends StatelessWidget {
  final String? selectedBuilding;
  final ValueChanged<String> onSelectBuilding;

  const BuildingSelector({
    super.key,
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
