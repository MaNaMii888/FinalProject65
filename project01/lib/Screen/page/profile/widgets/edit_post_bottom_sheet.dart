import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project01/widgets/branded_loading.dart';
import 'package:project01/models/post.dart';
import 'package:project01/utils/category_utils.dart';
import 'package:project01/services/log_service.dart';

class EditPostBottomSheet extends StatefulWidget {
  final Post post;

  const EditPostBottomSheet({super.key, required this.post});

  @override
  State<EditPostBottomSheet> createState() => _EditPostBottomSheetState();
}

class _EditPostBottomSheetState extends State<EditPostBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _buildingController;
  late TextEditingController _contactController;
  late String _selectedCategory;
  late String _selectedStatus;
  bool _isLoading = false;

  static const List<String> buildings = [
    'อาคาร 1',
    'อาคาร 2',
    'อาคาร 3',
    'อาคาร 4',
    'อาคาร 5',
    'อาคาร 6',
    'อาคาร 7',
    'อาคาร 8',
    'อาคาร 9',
    'อาคาร 10',
    'อาคาร 11',
    'อาคาร 12',
    'อาคาร 15',
    'อาคาร 16',
    'อาคาร 17',
    'อาคาร 18',
    'อาคาร 19',
    'อาคาร 20',
    'อาคาร 22',
    'อาคาร 24',
    'อาคาร 26',
    'อาคาร 27',
    'อาคาร 28',
    'อาคาร 29',
    'อาคาร 30',
    'อาคาร 31',
    'อาคาร 33',
    'โรงอาหาร',
    'ห้องสมุด',
    'สำนักงาน',
    'สนาม',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post.title);
    _descriptionController = TextEditingController(
      text: widget.post.description,
    );
    _locationController = TextEditingController(text: widget.post.location);
    _buildingController = TextEditingController(text: widget.post.building);
    _contactController = TextEditingController(text: widget.post.contact);
    _selectedCategory = widget.post.category;
    _selectedStatus = widget.post.status ?? 'active';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _buildingController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _updatePost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('lost_found_items')
          .doc(widget.post.id)
          .update({
            'title': _titleController.text.trim(),
            'description': _descriptionController.text.trim(),
            'location': _locationController.text.trim(),
            'building': _buildingController.text.trim(),
            'contact': _contactController.text.trim(),
            'category': _selectedCategory,
            'status': _selectedStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // บันทึก log การแก้ไขโพสต์
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await LogService().logPostUpdate(
          userId: currentUser.uid,
          userName: currentUser.email?.split('@')[0] ?? 'Unknown',
          postId: widget.post.id,
          postTitle: _titleController.text.trim(),
        );

        // ถ้ามีการเปลี่ยนสถานะ ให้บันทึก log แยก
        if (_selectedStatus != widget.post.status) {
          await LogService().logPostStatusChange(
            userId: currentUser.uid,
            userName: currentUser.email?.split('@')[0] ?? 'Unknown',
            postId: widget.post.id,
            postTitle: _titleController.text.trim(),
            oldStatus: widget.post.status ?? 'active',
            newStatus: _selectedStatus,
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger != null) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('แก้ไขโพสต์เรียบร้อยแล้ว'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger != null) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Text(
                'แก้ไขโพสต์',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(
            color: theme.colorScheme.onSurface.withOpacity(0.15),
            thickness: 1,
          ),
          const SizedBox(height: 16),

          // Form
          Flexible(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: _inputStyle('หัวข้อ *', Icons.title),
                      validator:
                          (value) =>
                              value!.trim().isEmpty ? 'กรุณาใส่หัวข้อ' : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: _inputStyle('รายละเอียด', Icons.description),
                    ),
                    const SizedBox(height: 16),

                    // Category
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: _inputStyle(
                        'ประเภทสิ่งของ *',
                        Icons.category,
                      ),
                      items:
                          CategoryUtils.categoryMap.entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v!),
                      validator:
                          (v) => v == null ? 'กรุณาเลือกประเภทสิ่งของ' : null,
                    ),
                    const SizedBox(height: 16),

                    // Building
                    DropdownButtonFormField<String>(
                      initialValue:
                          buildings.contains(_buildingController.text)
                              ? _buildingController.text
                              : null,
                      decoration: _inputStyle('อาคาร *', Icons.business),
                      items:
                          buildings
                              .map(
                                (b) =>
                                    DropdownMenuItem(value: b, child: Text(b)),
                              )
                              .toList(),
                      onChanged: (v) => _buildingController.text = v ?? '',
                      validator: (v) => v == null ? 'กรุณาเลือกอาคาร' : null,
                    ),
                    const SizedBox(height: 16),

                    // Location
                    TextFormField(
                      controller: _locationController,
                      decoration: _inputStyle(
                        'สถานที่ *',
                        Icons.location_on,
                        hint: 'เช่น ห้อง 301, ชั้น 2',
                      ),
                      validator:
                          (value) =>
                              value!.trim().isEmpty ? 'กรุณาใส่สถานที่' : null,
                    ),
                    const SizedBox(height: 16),

                    // Contact
                    TextFormField(
                      controller: _contactController,
                      decoration: _inputStyle(
                        'ช่องทางติดต่อ *',
                        Icons.contact_phone,
                        hint: 'เบอร์โทร หรือ LINE ID',
                      ),
                      validator:
                          (value) =>
                              value!.trim().isEmpty
                                  ? 'กรุณาใส่ช่องทางติดต่อ'
                                  : null,
                    ),
                    const SizedBox(height: 16),

                    // Status
                    DropdownButtonFormField<String>(
                      initialValue: _selectedStatus,
                      decoration: _inputStyle('สถานะ *', Icons.info_outline),
                      items: const [
                        DropdownMenuItem(
                          value: 'active',
                          child: Text('ยังไม่พบเจ้าของ'),
                        ),
                        DropdownMenuItem(
                          value: 'found_owner',
                          child: Text('เจอเจ้าของแล้ว'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _selectedStatus = v!),
                      validator: (v) => v == null ? 'กรุณาเลือกสถานะ' : null,
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.3,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'ยกเลิก',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updatePost,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.secondary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child:
                                 _isLoading
                                     ? const BrandedLoading(size: 20)
                                     : const Text('บันทึก'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 Helper: Field Style
  InputDecoration _inputStyle(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.blueAccent, width: 1.8),
      ),
    );
  }
}
