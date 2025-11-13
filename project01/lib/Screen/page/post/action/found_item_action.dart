import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:project01/services/post_count_service.dart';
import 'package:project01/services/smart_matching_service.dart';

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

      if (image == null) {
        // ผู้ใช้ยกเลิกการเลือกรูป
        return null;
      }

      // บางระบบ (เช่น Android) จะคืน path แบบ scaled_... ที่ระบบอาจลบได้เร็ว
      // เพื่อความเสถียร ให้คัดลอกเนื้อหาไฟล์ไปยังโฟลเดอร์ชั่วคราวของแอปก่อน
      final bytes = await image.readAsBytes();
      final tempDir = await getTemporaryDirectory();
      final safeName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
      final safePath = path.join(tempDir.path, safeName);
      final file = File(safePath);
      await file.writeAsBytes(bytes, flush: true);

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
    try {
      debugPrint('🖼️ [COMPRESS] เริ่มบีบอัดรูปภาพ...');

      final bytes = await imageFile.readAsBytes();
      final originalSizeMB = (bytes.length / 1024 / 1024);
      debugPrint(
        '🖼️ [COMPRESS] ขนาดต้นฉบับ: ${originalSizeMB.toStringAsFixed(2)} MB',
      );

      final image = img.decodeImage(bytes);
      if (image != null) {
        debugPrint(
          '🖼️ [COMPRESS] ขนาดต้นฉบับ: ${image.width}x${image.height}',
        );

        // คำนวณขนาดที่เหมาะสม
        int targetWidth = 600;
        if (image.width > 2000) targetWidth = 500;
        if (image.width > 4000) targetWidth = 400;

        final resized = img.copyResize(image, width: targetWidth);
        debugPrint(
          '🖼️ [COMPRESS] ขนาดใหม่: ${resized.width}x${resized.height}',
        );

        // บีบอัดแบบ progressive
        int quality = 60;
        List<int> compressedBytes;

        do {
          compressedBytes = img.encodeJpg(resized, quality: quality);
          debugPrint(
            '🖼️ [COMPRESS] Quality $quality%: ${(compressedBytes.length / 1024).toStringAsFixed(1)} KB',
          );

          if (compressedBytes.length <= 500 * 1024) break; // เป้าหมาย 500KB

          quality -= 10;
        } while (quality >= 20);

        final compressedSizeMB = (compressedBytes.length / 1024 / 1024);
        debugPrint(
          '✅ [COMPRESS] เสร็จสิ้น: ${compressedSizeMB.toStringAsFixed(2)} MB (Quality: $quality%)',
        );

        final compressedFile = File('${imageFile.path}_compressed.jpg');
        await compressedFile.writeAsBytes(compressedBytes);
        return compressedFile;
      }
    } catch (e) {
      debugPrint('💥 [COMPRESS] ข้อผิดพลาด: $e');
    }
    return imageFile;
  }

  static Future<String?> uploadImageToFirebase(
    File imageFile,
    String folder, {
    Function(double)? onProgress,
  }) async {
    try {
      debugPrint('� [UPLOAD] เริ่มกระบวนการอัพโหลด...');

      // ตรวจสอบ Authentication ก่อน (จำเป็นสำหรับ Storage Rules)
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('❌ [UPLOAD] ผู้ใช้ไม่ได้เข้าสู่ระบบ');
        throw Exception('กรุณาเข้าสู่ระบบก่อนอัพโหลดรูปภาพ');
      }

      // ตรวจสอบ ID Token ยังใช้ได้อยู่หรือไม่
      try {
        await user.getIdToken(true); // force refresh token
        debugPrint('✅ [UPLOAD] Authentication Token ใช้ได้: ${user.email}');
      } catch (e) {
        debugPrint('❌ [UPLOAD] Token หมดอายุ: $e');
        throw Exception('โปรดเข้าสู่ระบบใหม่');
      }

      debugPrint(
        '🔥 [UPLOAD] ขนาดไฟล์ต้นฉบับ: ${imageFile.lengthSync()} bytes',
      );

      // บีบอัดรูปก่อนอัพโหลด
      debugPrint('🔧 [UPLOAD] เริ่มบีบอัดรูปภาพ...');
      final compressed = await compressImage(imageFile);

      // สร้าง path ที่เฉพาะเจาะจงสำหรับ user
      final fileName =
          'lost_found_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'images/${user.uid}/$fileName'; // จัดกลุ่มตาม user ID

      debugPrint('📁 [UPLOAD] ไฟล์: $storagePath');
      final ref = FirebaseStorage.instance.ref().child(storagePath);

      // กำหนด metadata ที่ชัดเจน
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'max-age=3600',
        customMetadata: {
          'uploadedBy': user.email ?? 'unknown',
          'uploadedAt': DateTime.now().toIso8601String(),
          'originalSize': imageFile.lengthSync().toString(),
        },
      );

      // อัพโหลดด้วย retry logic และ fallback เป็น putData หาก putFile ล้ม
      String? downloadURL;
      final int maxAttempts = 3;

      // Prepare bytes for potential putData fallback (lazy read)
      Uint8List? fileBytes;

      for (int attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          debugPrint(
            '🚀 [UPLOAD] ความพยายามที่ $attempt/$maxAttempts (method=putFile)',
          );

          final uploadTask = ref.putFile(compressed, metadata);

          // ติดตาม progress การอัพโหลด
          if (onProgress != null) {
            uploadTask.snapshotEvents.listen(
              (snapshot) {
                if (snapshot.totalBytes > 0) {
                  final progress =
                      snapshot.bytesTransferred / snapshot.totalBytes;
                  debugPrint(
                    '📊 [UPLOAD] ความคืบหน้า (putFile): ${(progress * 100).toStringAsFixed(1)}%',
                  );
                  onProgress(progress);
                }
              },
              onError: (error) {
                debugPrint(
                  '❌ [UPLOAD] ข้อผิดพลาดระหว่างอัพโหลด (putFile): $error',
                );
              },
            );
          }

          final snapshot = await uploadTask.timeout(
            Duration(minutes: 2),
            onTimeout: () {
              debugPrint(
                '⏰ [UPLOAD] หมดเวลารอ (putFile) ความพยายามที่ $attempt',
              );
              uploadTask.cancel();
              throw Exception('การอัพโหลดใช้เวลานานเกินไป (putFile)');
            },
          );

          downloadURL = await snapshot.ref.getDownloadURL();
          debugPrint('✅ [UPLOAD] putFile สำเร็จที่ความพยายาม $attempt');
          debugPrint('🔗 [UPLOAD] URL: $downloadURL');
          break;
        } catch (e, st) {
          debugPrint('💥 [UPLOAD] putFile ความพยายามที่ $attempt ล้มเหลว: $e');
          debugPrint('💥 [UPLOAD] stack: $st');

          // Last attempt -> try fallback to putData if possible
          if (attempt == maxAttempts) {
            try {
              debugPrint(
                '🔁 [UPLOAD] พยายาม fallback -> putData (อ่าน bytes และอัพโหลด)',
              );
              fileBytes ??= Uint8List.fromList(await compressed.readAsBytes());

              final uploadTask = ref.putData(fileBytes, metadata);

              if (onProgress != null) {
                uploadTask.snapshotEvents.listen(
                  (s) {
                    if (s.totalBytes > 0) {
                      final progress = s.bytesTransferred / s.totalBytes;
                      debugPrint(
                        '📊 [UPLOAD] ความคืบหน้า (putData): ${(progress * 100).toStringAsFixed(1)}%',
                      );
                      onProgress(progress);
                    }
                  },
                  onError: (error) {
                    debugPrint(
                      '❌ [UPLOAD] ข้อผิดพลาดระหว่างอัพโหลด (putData): $error',
                    );
                  },
                );
              }

              final snapshot = await uploadTask.timeout(
                Duration(minutes: 2),
                onTimeout: () {
                  debugPrint('⏰ [UPLOAD] หมดเวลารอ (putData)');
                  uploadTask.cancel();
                  throw Exception('การอัพโหลดใช้เวลานานเกินไป (putData)');
                },
              );

              downloadURL = await snapshot.ref.getDownloadURL();
              debugPrint('✅ [UPLOAD] putData สำเร็จ (fallback)');
            } catch (fallbackError, fallbackSt) {
              debugPrint(
                '💥 [UPLOAD] fallback putData ล้มเหลว: $fallbackError',
              );
              debugPrint('💥 [UPLOAD] fallback stack: $fallbackSt');
              throw Exception(
                'การอัพโหลดล้มเหลว (ทั้ง putFile และ putData): $fallbackError',
              );
            }
          } else {
            // รอสักครู่ก่อน retry
            await Future.delayed(Duration(seconds: attempt * 2));
          }
        }
      }

      return downloadURL;
    } catch (e) {
      debugPrint('💥 [UPLOAD] ข้อผิดพลาดขั้นสุดท้าย: $e');
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
        setState(() {
          uploadProgress = 0.1;
        });
        imageUrl = await ImageService.uploadImageToFirebase(
          _imageFile!,
          'lost_items',
          onProgress: (progress) {
            setState(() {
              // ปรับ progress จาก 0.1-0.8 สำหรับการอัพโหลด
              uploadProgress = 0.1 + (progress * 0.7);
            });
          },
        );
        if (imageUrl == null) {
          throw Exception('ไม่สามารถอัพโหลดรูปภาพได้');
        }
        setState(() => uploadProgress = 0.85);
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

      // เรียก Smart Matching Service สำหรับโพสต์หาของ
      await SmartMatchingService.processNewPost(post);

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
    final primaryColor = Theme.of(context).colorScheme.onPrimary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return WillPopScope(
      onWillPop: () async {
        if (isLoading) {
          _showError('กรุณารอให้การอัปโหลดเสร็จสิ้น');
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primary,
        appBar: AppBar(
          title: Text(
            'แจ้งของหาย',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          backgroundColor: surfaceColor,
          iconTheme: IconThemeData(color: primaryColor),
          elevation: 0,
        ),
        body: Theme(
          data: Theme.of(context).copyWith(
            // ✅ ตั้งค่า TextField ทั้งหมด
            inputDecorationTheme: InputDecorationTheme(
              labelStyle: TextStyle(color: primaryColor),
              hintStyle: TextStyle(color: primaryColor.withOpacity(0.6)),
              prefixIconColor: primaryColor,
              suffixIconColor: primaryColor,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: primaryColor, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: primaryColor, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.red, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              errorStyle: const TextStyle(color: Colors.red),
            ),
            // ✅ ตั้งค่าสีเคอร์เซอร์
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: primaryColor,
              selectionColor: primaryColor.withOpacity(0.3),
              selectionHandleColor: primaryColor,
            ),
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ กรอบเพิ่มรูป
                  Center(
                    child: GestureDetector(
                      onTap: isLoading ? null : _pickImage,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: secondaryColor.withOpacity(
                            0.5,
                          ), // ✅ พื้นหลัง secondary opacity 0.5
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: primaryColor, // ✅ กรอบสี onPrimary
                            width: 2,
                          ),
                        ),
                        child:
                            _imageFile != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _imageFile!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 50,
                                      color:
                                          surfaceColor, // ✅ ไอคอนสีตามพื้นหลัง
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'เพิ่มรูปภาพ',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '(ไม่เกิน 5MB)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: primaryColor.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ✅ ชื่อสิ่งของ
                  TextFormField(
                    controller: titleController,
                    enabled: !isLoading,
                    style: TextStyle(color: primaryColor, fontSize: 16),
                    decoration: const InputDecoration(
                      labelText: 'ชื่อสิ่งของที่หาย *',
                      prefixIcon: Icon(Icons.inventory),
                    ),
                    validator: ValidationService.validateTitle,
                  ),
                  const SizedBox(height: 20),

                  // ✅ ประเภทสิ่งของ
                  Text(
                    'ประเภทสิ่งของ *',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCategoryRadios(),
                  const SizedBox(height: 20),

                  // ✅ อาคารและห้อง
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'อาคารที่หาย *',
                            prefixIcon: Icon(Icons.business),
                          ),
                          style: TextStyle(color: primaryColor, fontSize: 16),
                          dropdownColor: Theme.of(context).colorScheme.primary,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: primaryColor,
                          ),
                          items:
                              buildings
                                  .map(
                                    (building) => DropdownMenuItem(
                                      value: building,
                                      child: Text(
                                        building,
                                        style: TextStyle(color: primaryColor),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          value: selectedBuilding,
                          validator:
                              (value) =>
                                  value == null ? 'กรุณาเลือกอาคาร' : null,
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
                          style: TextStyle(color: primaryColor, fontSize: 16),
                          decoration: const InputDecoration(
                            labelText: 'ห้องที่หาย *',
                            hintText: '2102',
                            prefixIcon: Icon(Icons.room),
                          ),
                          validator: ValidationService.validateRoom,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ✅ ช่องทางติดต่อ
                  TextFormField(
                    controller: contactController,
                    enabled: !isLoading,
                    style: TextStyle(color: primaryColor, fontSize: 16),
                    decoration: const InputDecoration(
                      labelText: 'ช่องทางการติดต่อ *',
                      hintText: 'เบอร์โทร 10 หลัก หรือ @lineID',
                      prefixIcon: Icon(Icons.contact_phone),
                    ),
                    validator: ValidationService.validateContact,
                  ),
                  const SizedBox(height: 20),

                  // ✅ วันที่และเวลา
                  Row(
                    children: [
                      Expanded(child: _buildDateField()),
                      const SizedBox(width: 10),
                      Expanded(child: _buildTimeField()),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ✅ รายละเอียด
                  TextFormField(
                    controller: detailController,
                    enabled: !isLoading,
                    maxLines: 3,
                    style: TextStyle(color: primaryColor, fontSize: 16),
                    decoration: const InputDecoration(
                      labelText: 'รายละเอียดเพิ่มเติม *',
                      hintText:
                          'ระบุลักษณะเฉพาะของสิ่งของ (อย่างน้อย 10 ตัวอักษร)',
                      prefixIcon: Icon(Icons.description),
                      alignLabelWithHint: true,
                    ),
                    validator: ValidationService.validateDetail,
                  ),
                  const SizedBox(height: 20),

                  // ✅ ปุ่มบันทึก
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
                                surfaceColor,
                              ),
                            ),
                          ),
                        ElevatedButton.icon(
                          onPressed: isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: surfaceColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 32,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            shadowColor: surfaceColor.withOpacity(0.4),
                            minimumSize: const Size(double.infinity, 56),
                          ),
                          icon:
                              isLoading
                                  ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Icon(
                                    Icons.check_circle_outline,
                                    size: 24,
                                  ),
                          label: Text(
                            isLoading
                                ? 'กำลังบันทึก...'
                                : 'บันทึกการแจ้งของหาย',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
        setState(() {
          uploadProgress = 0.1;
        });
        imageUrl = await ImageService.uploadImageToFirebase(
          _imageFile!,
          'found_items',
          onProgress: (progress) {
            setState(() {
              // ปรับ progress จาก 0.1-0.8 สำหรับการอัพโหลด
              uploadProgress = 0.1 + (progress * 0.7);
            });
          },
        );
        if (imageUrl == null) {
          throw Exception('ไม่สามารถอัพโหลดรูปภาพได้');
        }
        setState(() => uploadProgress = 0.85);
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

      // เรียก Smart Matching Service สำหรับโพสต์เจอของ
      await SmartMatchingService.processNewPost(post);

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
          title: const Text(
            'แจ้งเจอของ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF4CAF50), // เขียวสด Material Design
          elevation: 2,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
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
                      ElevatedButton.icon(
                        onPressed: isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 32,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          shadowColor: Colors.green.withOpacity(0.4),
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        icon:
                            isLoading
                                ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Icon(
                                  Icons.check_circle_outline,
                                  size: 24,
                                ), // ✅ ไอคอนเช็ค
                        label: Text(
                          isLoading ? 'กำลังบันทึก...' : 'บันทึกการแจ้งเจอของ',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
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
