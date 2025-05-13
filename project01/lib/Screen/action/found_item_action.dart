import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class FoundItemActionPage extends StatefulWidget {
  const FoundItemActionPage({super.key});

  @override
  State<FoundItemActionPage> createState() => _FoundItemActionPageState();
}

class _FoundItemActionPageState extends State<FoundItemActionPage> {
  final _formKey = GlobalKey<FormState>();
  File? _imageFile;
  int? selectedCategory;
  String? selectedBuilding;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController detailController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  bool isLoading = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แจ้งเจอของ'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        _imageFile != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(_imageFile!, fit: BoxFit.cover),
                            )
                            : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 50),
                                Text('เพิ่มรูปภาพ'),
                              ],
                            ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title field
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อสิ่งของที่พบ',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value?.isEmpty ?? true ? 'กรุณากรอกชื่อสิ่งของ' : null,
              ),
              const SizedBox(height: 20),

              // Category selection
              const Text('ประเภทสิ่งของ'),
              Wrap(
                spacing: 8,
                children: [
                  _buildCategoryChip('ของใช้ส่วนตัว', 1),
                  _buildCategoryChip('เอกสาร/บัตร', 2),
                  _buildCategoryChip('อุปกรณ์การเรียน', 3),
                  _buildCategoryChip('ของมีค่าอื่นๆ', 4),
                ],
              ),
              const SizedBox(height: 20),

              // Location details
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'อาคารที่พบ',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: '1', child: Text('อาคาร 1')),
                        DropdownMenuItem(value: '2', child: Text('อาคาร 2')),
                        DropdownMenuItem(value: '3', child: Text('อาคาร 3')),
                      ],
                      value: selectedBuilding,
                      onChanged:
                          (value) => setState(() => selectedBuilding = value),
                      validator:
                          (value) => value == null ? 'กรุณาเลือกอาคาร' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'ห้องที่พบ',
                        hintText: '2102',
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (value) =>
                              value?.isEmpty ?? true ? 'กรุณากรอกห้อง' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Additional details
              TextFormField(
                controller: detailController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'รายละเอียดเพิ่มเติม',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value?.isEmpty ?? true ? 'กรุณากรอกรายละเอียด' : null,
              ),
              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child:
                      isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'บันทึก',
                            style: TextStyle(color: Colors.white),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, int value) {
    return ChoiceChip(
      label: Text(label),
      selected: selectedCategory == value,
      onSelected: (bool selected) {
        setState(() {
          selectedCategory = selected ? value : null;
        });
      },
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => isLoading = true);
      try {
        // TODO: Implement form submission
        // Upload image
        // Save data to database

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')));
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      } finally {
        setState(() => isLoading = false);
      }
    }
  }
}
