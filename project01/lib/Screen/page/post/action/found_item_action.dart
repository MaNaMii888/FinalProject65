import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:project01/services/post_count_service.dart';
import 'package:project01/services/smart_matching_service.dart';

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
  final TextEditingController roomController = TextEditingController();
  bool isLoading = false;
  bool agreedToTerms = false;
  double uploadProgress = 0.0;

  static const Map<int, String> categories = {
    1: "ของใช้ส่วนตัว",
    2: "เอกสาร/บัตร", 
    3: "อุปกรณ์การเรียน",
    4: "ของมีค่าอื่นๆ",
  };

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
                        DropdownMenuItem(value: 'อาคาร 1', child: Text('อาคาร 1')),
                        DropdownMenuItem(value: 'อาคาร 2', child: Text('อาคาร 2')),
                        DropdownMenuItem(value: 'อาคาร 3', child: Text('อาคาร 3')),
                        DropdownMenuItem(value: 'อาคาร 4', child: Text('อาคาร 4')),
                        DropdownMenuItem(value: 'อาคาร 5', child: Text('อาคาร 5')),
                        DropdownMenuItem(value: 'อาคาร 6', child: Text('อาคาร 6')),
                        DropdownMenuItem(value: 'อาคาร 7', child: Text('อาคาร 7')),
                        DropdownMenuItem(value: 'อาคาร 8', child: Text('อาคาร 8')),
                        DropdownMenuItem(value: 'อาคาร 9', child: Text('อาคาร 9')),
                        DropdownMenuItem(value: 'อาคาร 10', child: Text('อาคาร 10')),
                        DropdownMenuItem(value: 'อาคาร 11', child: Text('อาคาร 11')),
                        DropdownMenuItem(value: 'อาคาร 12', child: Text('อาคาร 12')),
                        DropdownMenuItem(value: 'อาคาร 15', child: Text('อาคาร 15')),
                        DropdownMenuItem(value: 'อาคาร 16', child: Text('อาคาร 16')),
                        DropdownMenuItem(value: 'อาคาร 17', child: Text('อาคาร 17')),
                        DropdownMenuItem(value: 'อาคาร 18', child: Text('อาคาร 18')),
                        DropdownMenuItem(value: 'อาคาร 19', child: Text('อาคาร 19')),
                        DropdownMenuItem(value: 'อาคาร 20', child: Text('อาคาร 20')),
                        DropdownMenuItem(value: 'อาคาร 22', child: Text('อาคาร 22')),
                        DropdownMenuItem(value: 'อาคาร 24', child: Text('อาคาร 24')),
                        DropdownMenuItem(value: 'อาคาร 26', child: Text('อาคาร 26')),
                        DropdownMenuItem(value: 'อาคาร 27', child: Text('อาคาร 27')),
                        DropdownMenuItem(value: 'อาคาร 28', child: Text('อาคาร 28')),
                        DropdownMenuItem(value: 'อาคาร 29', child: Text('อาคาร 29')),
                        DropdownMenuItem(value: 'อาคาร 30', child: Text('อาคาร 30')),
                        DropdownMenuItem(value: 'อาคาร 31', child: Text('อาคาร 31')),
                        DropdownMenuItem(value: 'อาคาร 33', child: Text('อาคาร 33')),
                        DropdownMenuItem(value: 'โรงอาหาร', child: Text('โรงอาหาร')),
                        DropdownMenuItem(value: 'ห้องสมุด', child: Text('ห้องสมุด')),
                        DropdownMenuItem(value: 'สำนักงาน', child: Text('สำนักงาน')),
                        DropdownMenuItem(value: 'สนาม', child: Text('สนาม')),
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
                      controller: roomController,
                      decoration: const InputDecoration(
                        labelText: 'ห้องที่พบ *',
                        hintText: '2102',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.room),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอกห้อง';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Contact field
              TextFormField(
                controller: contactController,
                decoration: const InputDecoration(
                  labelText: 'ช่องทางการติดต่อ *',
                  hintText: 'เบอร์โทร 10 หลัก หรือ @lineID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.contact_phone),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกช่องทางการติดต่อ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Additional details
              TextFormField(
                controller: detailController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'รายละเอียดเพิ่มเติม *',
                  hintText: 'ระบุลักษณะเฉพาะของสิ่งของ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกรายละเอียด';
                  }
                  if (value.trim().length < 10) {
                    return 'รายละเอียดต้องมีอย่างน้อย 10 ตัวอักษร';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Terms checkbox
              CheckboxListTile(
                title: const Text('ยอมรับเงื่อนไขและนโยบายความเป็นส่วนตัว *'),
                value: agreedToTerms,
                onChanged: isLoading ? null : (value) => setState(() => agreedToTerms = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    if (isLoading && uploadProgress > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: LinearProgressIndicator(
                          value: uploadProgress,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green[400]!),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isLoading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text('กำลังบันทึก...'),
                              ],
                            )
                          : const Text('บันทึกการแจ้งเจอของ'),
                    ),
                  ],
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
    if (!_formKey.currentState!.validate()) {
      _showError('กรุณากรอกข้อมูลให้ครบถ้วน');
      return;
    }
    if (selectedCategory == null) {
      _showError('กรุณาเลือกประเภทสิ่งของ');
      return;
    }
    if (!agreedToTerms) {
      _showError('กรุณายอมรับเงื่อนไขและนโยบายความเป็นส่วนตัว');
      return;
    }

    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() {
      isLoading = true;
      uploadProgress = 0.0;
    });

    try {
      // ตรวจสอบการ login
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('กรุณาเข้าสู่ระบบก่อน');
        return;
      }

      String? imageUrl;
      if (_imageFile != null) {
        setState(() => uploadProgress = 0.2);
        imageUrl = await _uploadImageToFirebase(_imageFile!);
        setState(() => uploadProgress = 0.8);
      }

      final post = {
        'userId': user.uid,
        'userEmail': user.email,
        'title': titleController.text.trim(),
        'category': selectedCategory.toString(),
        'categoryName': categories[selectedCategory!],
        'building': selectedBuilding,
        'room': roomController.text.trim(),
        'contact': contactController.text.trim(),
        'detail': detailController.text.trim(),
        'isLostItem': false, // false สำหรับ found item
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl ?? '',
        'searchKeywords': _generateSearchKeywords(),
      };

      await FirebaseFirestore.instance.collection('lost_found_items').add(post);

      // เรียก Smart Matching Service
      await SmartMatchingService.processNewPost(post);

      // อัพเดทจำนวนโพสต์ของผู้ใช้
      await PostCountService.updatePostCount(user.uid, false);

      setState(() => uploadProgress = 1.0);

      if (mounted) {
        _showSuccess('บันทึกข้อมูลสำเร็จ');
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Submit error: $e');
      _showError('เกิดข้อผิดพลาด: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          uploadProgress = 0.0;
        });
      }
    }
  }

  List<String> _generateSearchKeywords() {
    final keywords = <String>[];
    keywords.add(titleController.text.trim().toLowerCase());
    keywords.add(categories[selectedCategory!]!.toLowerCase());
    keywords.add(selectedBuilding!.toLowerCase());
    keywords.add(roomController.text.trim().toLowerCase());
    final detailWords = detailController.text.trim().toLowerCase().split(' ');
    keywords.addAll(detailWords.where((word) => word.length > 2));
    return keywords.toSet().toList();
  }

  Future<String?> _uploadImageToFirebase(File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final ref = FirebaseStorage.instance.ref('found_items/$fileName');
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Image upload error: $e');
      return null;
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('ยืนยันการบันทึก'),
            content: const Text('คุณต้องการบันทึกข้อมูลการแจ้งเจอของนี้หรือไม่?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('ยืนยัน'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    dateController.dispose();
    detailController.dispose();
    contactController.dispose();
    roomController.dispose();
    super.dispose();
  }
}
