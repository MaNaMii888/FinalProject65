import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:project01/services/post_count_service.dart';

// ----------------- Service Classes -----------------
class AuthService {
  static User? get currentUser => FirebaseAuth.instance.currentUser;
  static bool get isLoggedIn => currentUser != null;

  static Future<void> requireAuth(BuildContext context) async {
    if (!isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/login');
      throw Exception('User not authenticated');
    }
  }
}

class ValidationService {
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณากรอกชื่อสิ่งของ';
    }
    if (value.trim().length < 2) {
      return 'ชื่อสิ่งของต้องมีอย่างน้อย 2 ตัวอักษร';
    }
    if (value.trim().length > 100) {
      return 'ชื่อสิ่งของต้องไม่เกิน 100 ตัวอักษร';
    }
    return null;
  }

  static String? validateContact(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณากรอกช่องทางการติดต่อ';
    }
    if (RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
      return null;
    }
    if (RegExp(r'^@[\w\d_.-]{1,20}$').hasMatch(value.trim())) {
      return null;
    }
    return 'กรุณากรอกเบอร์โทร 10 หลัก หรือ Line ID ที่ขึ้นต้นด้วย @';
  }

  static String? validateDetail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณากรอกรายละเอียด';
    }
    if (value.trim().length < 10) {
      return 'รายละเอียดต้องมีอย่างน้อย 10 ตัวอักษร';
    }
    if (value.trim().length > 500) {
      return 'รายละเอียดต้องไม่เกิน 500 ตัวอักษร';
    }
    return null;
  }

  static String? validateRoom(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณากรอกห้อง';
    }
    if (!RegExp(r'^[A-Za-z0-9\-\/]{1,10}$').hasMatch(value.trim())) {
      return 'รูปแบบห้องไม่ถูกต้อง (เช่น 2102, A-101)';
    }
    return null;
  }
}

class ImageService {
  static const int maxFileSizeInBytes = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedExtensions = ['.jpg', '.jpeg', '.png'];

  static Future<File?> pickAndValidateImage(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image == null) return null;
      final file = File(image.path);

      // ตรวจสอบขนาดไฟล์
      final fileSize = await file.length();
      if (fileSize > maxFileSizeInBytes) {
        _showError(context, 'ขนาดไฟล์ต้องไม่เกิน 5MB');
        return null;
      }
      // ตรวจสอบนามสกุลไฟล์
      final extension = path.extension(image.path).toLowerCase();
      if (!allowedExtensions.contains(extension)) {
        _showError(context, 'รองรับเฉพาะไฟล์ .jpg, .jpeg, .png เท่านั้น');
        return null;
      }
      return file;
    } catch (e) {
      _showError(context, 'ไม่สามารถเลือกรูปภาพได้: $e');
      return null;
    }
  }

  static Future<File> compressImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image != null) {
      final resized = img.copyResize(image, width: 800);
      final compressedBytes = img.encodeJpg(resized, quality: 70);
      final compressedFile = File('${imageFile.path}_compressed.jpg');
      await compressedFile.writeAsBytes(compressedBytes);
      return compressedFile;
    }
    return imageFile;
  }

  static Future<String?> uploadImageToFirebase(
    File imageFile,
    String folder,
  ) async {
    try {
      final compressed = await compressImage(imageFile);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(compressed.path)}';
      final ref = FirebaseStorage.instance.ref('$folder/$fileName');
      final uploadTask = ref.putFile(compressed);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Image upload error: $e');
      return null;
    }
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ----------------- LostItemForm -----------------
class LostItemForm extends StatefulWidget {
  const LostItemForm({super.key});

  @override
  State<LostItemForm> createState() => _LostItemFormState();
}

class _LostItemFormState extends State<LostItemForm> {
  final _formKey = GlobalKey<FormState>();
  File? _imageFile;
  int? selectedCategory;
  String? selectedBuilding;
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController detailController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController roomController = TextEditingController();
  bool isLoading = false;
  bool agreedToTerms = false;
  double uploadProgress = 0.0;

  static const List<String> buildings = ['อาคาร 1', 'อาคาร 2', 'อาคาร 3'];
  static const Map<int, String> categories = {
    1: "ของใช้ส่วนตัว",
    2: "เอกสาร/บัตร",
    3: "อุปกรณ์การเรียน",
    4: "ของมีค่าอื่นๆ",
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await AuthService.requireAuth(context);
      } catch (e) {
        return;
      }
    });
  }

  Future<void> _pickImage() async {
    final image = await ImageService.pickAndValidateImage(context);
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
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
      await AuthService.requireAuth(context);

      String? imageUrl;
      if (_imageFile != null) {
        setState(() => uploadProgress = 0.2);
        imageUrl = await ImageService.uploadImageToFirebase(
          _imageFile!,
          'lost_items',
        );
        setState(() => uploadProgress = 0.8);
      }

      final post = {
        'userId': AuthService.currentUser!.uid,
        'userEmail': AuthService.currentUser!.email,
        'title': titleController.text.trim(),
        'category': selectedCategory.toString(),
        'categoryName': categories[selectedCategory!],
        'building': selectedBuilding,
        'room': roomController.text.trim(),
        'date': dateController.text,
        'time': timeController.text,
        'contact': contactController.text.trim(),
        'detail': detailController.text.trim(),
        'isLostItem': true,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl ?? '',
        'searchKeywords': _generateSearchKeywords(),
      };

      await FirebaseFirestore.instance.collection('lost_found_items').add(post);

      // อัพเดทจำนวนโพสต์ของผู้ใช้
      await PostCountService.updatePostCount(
        AuthService.currentUser!.uid,
        true, // isLostItem = true สำหรับ lost item
      );

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

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('ยืนยันการบันทึก'),
                content: const Text(
                  'คุณต้องการบันทึกข้อมูลการแจ้งของหายนี้หรือไม่?',
                ),
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
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (isLoading) {
          _showError('กรุณารอให้การอัปโหลดเสร็จสิ้น');
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('แจ้งของหาย'),
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
                Center(
                  child: GestureDetector(
                    onTap: isLoading ? null : _pickImage,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              _imageFile != null ? Colors.green : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child:
                          _imageFile != null
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  _imageFile!,
                                  fit: BoxFit.cover,
                                ),
                              )
                              : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 50),
                                  Text('เพิ่มรูปภาพ'),
                                  Text(
                                    '(ไม่เกิน 5MB)',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: titleController,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อสิ่งของที่หาย *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  validator: ValidationService.validateTitle,
                ),
                const SizedBox(height: 20),
                const Text(
                  'ประเภทสิ่งของ *',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                _buildCategoryRadios(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'อาคารที่หาย *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        items:
                            buildings
                                .map(
                                  (building) => DropdownMenuItem(
                                    value: building,
                                    child: Text(building),
                                  ),
                                )
                                .toList(),
                        value: selectedBuilding,
                        validator:
                            (value) => value == null ? 'กรุณาเลือกอาคาร' : null,
                        onChanged:
                            isLoading
                                ? null
                                : (value) =>
                                    setState(() => selectedBuilding = value),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: roomController,
                        enabled: !isLoading,
                        decoration: const InputDecoration(
                          labelText: 'ห้องที่หาย *',
                          hintText: '2102',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.room),
                        ),
                        validator: ValidationService.validateRoom,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: contactController,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: 'ช่องทางการติดต่อ *',
                    hintText: 'เบอร์โทร 10 หลัก หรือ @lineID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.contact_phone),
                  ),
                  validator: ValidationService.validateContact,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildDateField()),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTimeField()),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: detailController,
                  enabled: !isLoading,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'รายละเอียดเพิ่มเติม *',
                    hintText:
                        'ระบุลักษณะเฉพาะของสิ่งของ (อย่างน้อย 10 ตัวอักษร)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: ValidationService.validateDetail,
                ),
                const SizedBox(height: 20),
                CheckboxListTile(
                  title: const Text('ยอมรับเงื่อนไขและนโยบายความเป็นส่วนตัว *'),
                  value: agreedToTerms,
                  onChanged:
                      isLoading
                          ? null
                          : (value) =>
                              setState(() => agreedToTerms = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 20),
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.red[400]!,
                            ),
                          ),
                        ),
                      ElevatedButton(
                        onPressed: isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[400],
                          foregroundColor: Colors.white,
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text('กำลังบันทึก...'),
                                  ],
                                )
                                : const Text('บันทึกการแจ้งของหาย'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: dateController,
      enabled: !isLoading,
      readOnly: true,
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            dateController.text = DateFormat('dd/MM/yyyy').format(picked);
          });
        }
      },
      decoration: const InputDecoration(
        labelText: 'วันที่หาย *',
        hintText: 'เลือกวันที่',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today),
      ),
      validator: (value) => value?.isEmpty ?? true ? 'กรุณาเลือกวันที่' : null,
    );
  }

  Widget _buildTimeField() {
    return TextFormField(
      controller: timeController,
      enabled: !isLoading,
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
        labelText: 'เวลาที่หาย *',
        hintText: 'เลือกเวลา',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.access_time),
      ),
      validator: (value) => value?.isEmpty ?? true ? 'กรุณาเลือกเวลา' : null,
    );
  }

  Widget _buildCategoryRadios() {
    return Column(
      children: [
        Row(
          children: [
            _buildRadioTile("ของใช้ส่วนตัว", 1),
            _buildRadioTile("เอกสาร/บัตร", 2),
          ],
        ),
        Row(
          children: [
            _buildRadioTile("อุปกรณ์การเรียน", 3),
            _buildRadioTile("ของมีค่าอื่นๆ", 4),
          ],
        ),
      ],
    );
  }

  Widget _buildRadioTile(String title, int value) {
    return Expanded(
      child: RadioListTile(
        title: Text(title),
        value: value,
        groupValue: selectedCategory,
        onChanged:
            isLoading
                ? null
                : (value) => setState(() => selectedCategory = value as int?),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    dateController.dispose();
    timeController.dispose();
    detailController.dispose();
    contactController.dispose();
    roomController.dispose();
    super.dispose();
  }
}

// ----------------- FindItemActionPage (UI) -----------------
class FindItemActionPage extends StatelessWidget {
  final VoidCallback? onLostPress;
  final VoidCallback? onFoundPress;

  const FindItemActionPage({super.key, this.onLostPress, this.onFoundPress});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(onPressed: onLostPress, child: const Text('Lost')),
        ElevatedButton(onPressed: onFoundPress, child: const Text('Found')),
      ],
    );
  }
}

// ----------------- FindItemForm (แจ้งเจอของ) -----------------
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
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController detailController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController roomController = TextEditingController();
  bool isLoading = false;
  bool agreedToTerms = false;
  double uploadProgress = 0.0;

  static const List<String> buildings = ['อาคาร 1', 'อาคาร 2', 'อาคาร 3'];
  static const Map<int, String> categories = {
    1: "ของใช้ส่วนตัว",
    2: "เอกสาร/บัตร",
    3: "อุปกรณ์การเรียน",
    4: "ของมีค่าอื่นๆ",
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await AuthService.requireAuth(context);
      } catch (e) {
        return;
      }
    });
  }

  Future<void> _pickImage() async {
    final image = await ImageService.pickAndValidateImage(context);
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
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
      await AuthService.requireAuth(context);

      String? imageUrl;
      if (_imageFile != null) {
        setState(() => uploadProgress = 0.2);
        imageUrl = await ImageService.uploadImageToFirebase(
          _imageFile!,
          'found_items',
        );
        setState(() => uploadProgress = 0.8);
      }

      final post = {
        'userId': AuthService.currentUser!.uid,
        'userEmail': AuthService.currentUser!.email,
        'title': titleController.text.trim(),
        'category': selectedCategory.toString(),
        'categoryName': categories[selectedCategory!],
        'building': selectedBuilding,
        'room': roomController.text.trim(),
        'date': dateController.text,
        'time': timeController.text,
        'contact': contactController.text.trim(),
        'detail': detailController.text.trim(),
        'isLostItem': false,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl ?? '',
        'searchKeywords': _generateSearchKeywords(),
      };

      await FirebaseFirestore.instance.collection('lost_found_items').add(post);

      // อัพเดทจำนวนโพสต์ของผู้ใช้
      await PostCountService.updatePostCount(
        AuthService.currentUser!.uid,
        false, // isLostItem = false สำหรับ found item
      );

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

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('ยืนยันการบันทึก'),
                content: const Text(
                  'คุณต้องการบันทึกข้อมูลการแจ้งเจอของนี้หรือไม่?',
                ),
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
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (isLoading) {
          _showError('กรุณารอให้การอัปโหลดเสร็จสิ้น');
          return false;
        }
        return true;
      },
      child: Scaffold(
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
                Center(
                  child: GestureDetector(
                    onTap: isLoading ? null : _pickImage,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              _imageFile != null ? Colors.green : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child:
                          _imageFile != null
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  _imageFile!,
                                  fit: BoxFit.cover,
                                ),
                              )
                              : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 50),
                                  Text('เพิ่มรูปภาพ'),
                                  Text(
                                    '(ไม่เกิน 5MB)',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: titleController,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อสิ่งของที่พบ *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  validator: ValidationService.validateTitle,
                ),
                const SizedBox(height: 20),
                const Text(
                  'ประเภทสิ่งของ *',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                _buildCategoryRadios(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'อาคารที่พบ *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        items:
                            buildings
                                .map(
                                  (building) => DropdownMenuItem(
                                    value: building,
                                    child: Text(building),
                                  ),
                                )
                                .toList(),
                        value: selectedBuilding,
                        validator:
                            (value) => value == null ? 'กรุณาเลือกอาคาร' : null,
                        onChanged:
                            isLoading
                                ? null
                                : (value) =>
                                    setState(() => selectedBuilding = value),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: roomController,
                        enabled: !isLoading,
                        decoration: const InputDecoration(
                          labelText: 'ห้องที่พบ *',
                          hintText: '2102',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.room),
                        ),
                        validator: ValidationService.validateRoom,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: contactController,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: 'ช่องทางการติดต่อ *',
                    hintText: 'เบอร์โทร 10 หลัก หรือ @lineID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.contact_phone),
                  ),
                  validator: ValidationService.validateContact,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildDateField()),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTimeField()),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: detailController,
                  enabled: !isLoading,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'รายละเอียดเพิ่มเติม *',
                    hintText:
                        'ระบุลักษณะเฉพาะของสิ่งของ (อย่างน้อย 10 ตัวอักษร)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: ValidationService.validateDetail,
                ),
                const SizedBox(height: 20),
                CheckboxListTile(
                  title: const Text('ยอมรับเงื่อนไขและนโยบายความเป็นส่วนตัว *'),
                  value: agreedToTerms,
                  onChanged:
                      isLoading
                          ? null
                          : (value) =>
                              setState(() => agreedToTerms = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 20),
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.green[400]!,
                            ),
                          ),
                        ),
                      ElevatedButton(
                        onPressed: isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[400],
                          foregroundColor: Colors.white,
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
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
      ),
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: dateController,
      enabled: !isLoading,
      readOnly: true,
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            dateController.text = DateFormat('dd/MM/yyyy').format(picked);
          });
        }
      },
      decoration: const InputDecoration(
        labelText: 'วันที่พบ *',
        hintText: 'เลือกวันที่',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today),
      ),
      validator: (value) => value?.isEmpty ?? true ? 'กรุณาเลือกวันที่' : null,
    );
  }

  Widget _buildTimeField() {
    return TextFormField(
      controller: timeController,
      enabled: !isLoading,
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
        labelText: 'เวลาที่พบ *',
        hintText: 'เลือกเวลา',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.access_time),
      ),
      validator: (value) => value?.isEmpty ?? true ? 'กรุณาเลือกเวลา' : null,
    );
  }

  Widget _buildCategoryRadios() {
    return Column(
      children: [
        Row(
          children: [
            _buildRadioTile("ของใช้ส่วนตัว", 1),
            _buildRadioTile("เอกสาร/บัตร", 2),
          ],
        ),
        Row(
          children: [
            _buildRadioTile("อุปกรณ์การเรียน", 3),
            _buildRadioTile("ของมีค่าอื่นๆ", 4),
          ],
        ),
      ],
    );
  }

  Widget _buildRadioTile(String title, int value) {
    return Expanded(
      child: RadioListTile(
        title: Text(title),
        value: value,
        groupValue: selectedCategory,
        onChanged:
            isLoading
                ? null
                : (value) => setState(() => selectedCategory = value as int?),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    dateController.dispose();
    timeController.dispose();
    detailController.dispose();
    contactController.dispose();
    roomController.dispose();
    super.dispose();
  }
}
