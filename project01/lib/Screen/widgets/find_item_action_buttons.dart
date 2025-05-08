import 'package:flutter/material.dart';

class PostActionButtons extends StatelessWidget {
  final VoidCallback? onLostPress;
  final VoidCallback? onFoundPress;

  const PostActionButtons({super.key, this.onLostPress, this.onFoundPress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton(
            onPressed: onLostPress,
            icon: Icons.help_outline,
            label: 'แจ้งของหาย',
            backgroundColor: Colors.amber[100],
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            onPressed: onFoundPress,
            icon: Icons.search,
            label: 'แจ้งเจอของ',
            backgroundColor: Colors.white,
            borderColor: Colors.amber[100],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    VoidCallback? onPressed,
    required IconData icon,
    required String label,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side:
              borderColor != null
                  ? BorderSide(color: borderColor)
                  : BorderSide.none,
        ),
        elevation: 2,
      ),
    );
  }
}

class LostItemPostPage extends StatefulWidget {
  const LostItemPostPage({super.key});

  @override
  State<LostItemPostPage> createState() => _LostItemPostPageState();
}

class _LostItemPostPageState extends State<LostItemPostPage> {
  int? selectedCategory;
  String? selectedBuilding;
  final TextEditingController dateController = TextEditingController();
  final TextEditingController detailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('แจ้งของหาย')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: IconButton(
                onPressed: () {
                  // TODO: Implement image picker
                },
                icon: const Icon(Icons.add_photo_alternate, size: 100),
              ),
            ),
            const SizedBox(height: 20),
            const Text('ประเภทสิ่งของ'),
            _buildCategoryRadios(),
            const SizedBox(height: 20),
            _buildLocationAndDateFields(),
            const SizedBox(height: 20),
            TextField(
              controller: detailController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'รายละเอียด',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSubmit,
                child: const Text('บันทึก'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRadios() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: RadioListTile(
                title: const Text("ของใช้ส่วนตัว"),
                value: 1,
                groupValue: selectedCategory,
                onChanged: (value) => setState(() => selectedCategory = value),
              ),
            ),
            Expanded(
              child: RadioListTile(
                title: const Text("เอกสาร/บัตร"),
                value: 2,
                groupValue: selectedCategory,
                onChanged: (value) => setState(() => selectedCategory = value),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: RadioListTile(
                title: const Text("อุปกรณ์การเรียน"),
                value: 3,
                groupValue: selectedCategory,
                onChanged: (value) => setState(() => selectedCategory = value),
              ),
            ),
            Expanded(
              child: RadioListTile(
                title: const Text("ของมีค่าอื่นๆ"),
                value: 4,
                groupValue: selectedCategory,
                onChanged: (value) => setState(() => selectedCategory = value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationAndDateFields() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'อาคาร'),
            items: const [
              DropdownMenuItem(value: '1', child: Text('อาคาร 1')),
              DropdownMenuItem(value: '2', child: Text('อาคาร 2')),
              DropdownMenuItem(value: '3', child: Text('อาคาร 3')),
            ],
            value: selectedBuilding,
            onChanged: (value) => setState(() => selectedBuilding = value),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: dateController,
            decoration: const InputDecoration(
              labelText: 'วันที่',
              hintText: '8/5/2568',
            ),
          ),
        ),
      ],
    );
  }

  void _handleSubmit() {
    // TODO: Implement form submission
    print('ประเภท: $selectedCategory');
    print('อาคาร: $selectedBuilding');
    print('วันที่: ${dateController.text}');
    print('รายละเอียด: ${detailController.text}');
  }
}
