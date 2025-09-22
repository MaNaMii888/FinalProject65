import 'package:flutter/material.dart';

class PostActionButtons extends StatelessWidget {
  final VoidCallback? onLostPress;
  final VoidCallback? onFoundPress;

  const PostActionButtons({super.key, this.onLostPress, this.onFoundPress});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withOpacity(0.1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: onLostPress,
                  icon: const Icon(Icons.help_outline),
                  label: const Text('แจ้งหาของหาย'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: onFoundPress,
                  icon: const Icon(Icons.search),
                  label: const Text('แจ้งพบของหาย'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
