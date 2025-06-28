import 'package:flutter/material.dart';

class ViewSelector extends StatelessWidget {
  final String currentView;
  final bool showPopup;
  final VoidCallback onTogglePopup;
  final ValueChanged<String> onSelectView;

  const ViewSelector({
    super.key,
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
