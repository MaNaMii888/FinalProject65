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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            buildingData.keys.map((buildingKey) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ElevatedButton(
                    onPressed: () => onSelectBuilding(buildingKey),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          selectedBuilding == buildingKey
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surface,
                      foregroundColor:
                          selectedBuilding == buildingKey
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
                      shadowColor:
                          selectedBuilding == buildingKey
                              ? Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.2)
                              : Colors.transparent,
                      elevation: selectedBuilding == buildingKey ? 4 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    child: Text(buildingData[buildingKey]!.name),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
