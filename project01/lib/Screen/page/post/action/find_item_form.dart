import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:project01/services/post_count_service.dart';

class FindItemForm extends StatefulWidget {
  const FindItemForm({super.key});

  @override
  State<FindItemForm> createState() => _FindItemFormState();
}

class _FindItemFormState extends State<FindItemForm> {
  final _formKey = GlobalKey<FormState>();
  File? _imageFile;
  int? selectedCategory;
  String? selectedBuilding;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController detailController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'แจ้งพบของ',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
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
                      // ใช้สีจาก Theme แทนการกำหนดสีตายตัว
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.2),
                      ),
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
                      controller: dateController,
                      readOnly: true,
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Colors.green, // ใช้สีเขียวตามธีม
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            dateController.text = DateFormat(
                              'dd/MM/yyyy',
                            ).format(picked);
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'วันที่พบ',
                        hintText: 'เลือกวันที่',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'กรุณาเลือกวันที่'
                                  : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: timeController,
                readOnly: true,
                onTap: () async {
                  TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      timeController.text = picked.format(context);
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'เวลาที่พบโดยประมาณ',
                  hintText: 'เลือกเวลา',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.access_time),
                ),
                validator:
                    (value) => value?.isEmpty ?? true ? 'กรุณาเลือกเวลา' : null,
              ),
              const SizedBox(height: 20),

              // Contact information
              TextFormField(
                controller: contactController,
                decoration: const InputDecoration(
                  labelText: 'ช่องทางการติดต่อ',
                  hintText: 'เบอร์โทร หรือ ID Line',
                  prefixIcon: Icon(Icons.contact_phone),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกช่องทางการติดต่อ';
                  }
                  final phoneRegex = RegExp(r'^[0-9]{10}$');
                  if (!phoneRegex.hasMatch(value) && !value.contains('line')) {
                    return 'กรุณากรอกเบอร์โทร 10 หลัก หรือ ID Line';
                  }
                  return null;
                },
                style: const TextStyle(fontSize: 16, color: Colors.black87),
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
                          ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'กำลังบันทึก...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          )
                          : const Text(
                            'บันทึกการแจ้งพบของ',
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // ยืนยันก่อนบันทึก
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('ยืนยันการบันทึก'),
            content: const Text(
              'คุณต้องการบันทึกข้อมูลการแจ้งพบของใช่หรือไม่?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('ยกเลิก'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('ยืนยัน'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    if (selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณาเลือกประเภทสิ่งของ')));
      return;
    }

    setState(() => isLoading = true);

    try {
      String? imageUrl;

      // อัปโหลดรูปถ้ามี
      if (_imageFile != null) {
        try {
          final ref = FirebaseStorage.instance
              .ref()
              .child('found_items')
              .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

          await ref.putFile(_imageFile!); // อัปโหลดรูป
          imageUrl = await ref.getDownloadURL(); // รับ URL ของรูป
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('อัปโหลดรูปไม่สำเร็จ: $e')));
          setState(() => isLoading = false);
          return; // หยุดโพสต์ถ้าอัปโหลดไม่สำเร็จ
        }
      }

      // สร้างโพสต์ใน Firestore
      final post = {
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'userName':
            FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous',
        'title': titleController.text,
        'description': detailController.text,
        'imageUrl': imageUrl ?? '', // ใส่ URL หรือว่าง
        'location': locationController.text,
        'building': selectedBuilding,
        'category': selectedCategory?.toString(),
        'createdAt': FieldValue.serverTimestamp(),
        'isLostItem': false,
        'status': 'open',
        'contact': contactController.text,
      };

      await FirebaseFirestore.instance.collection('lost_found_items').add(post);

      // อัปเดทจำนวนโพสต์
      if (FirebaseAuth.instance.currentUser?.uid != null) {
        await PostCountService.updatePostCount(
          FirebaseAuth.instance.currentUser!.uid,
          false,
        );
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    dateController.dispose();
    detailController.dispose();
    locationController.dispose();
    contactController.dispose();
    timeController.dispose();
    super.dispose();
  }
}
