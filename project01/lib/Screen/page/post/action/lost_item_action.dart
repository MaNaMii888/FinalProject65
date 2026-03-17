import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project01/widgets/branded_loading.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:project01/Screen/page/notification/realtime_notification_service.dart';
import 'package:project01/services/post_count_service.dart';
import 'package:project01/utils/image_compressor.dart';
import 'package:project01/services/log_service.dart';
import 'package:project01/services/ai_tagging_service.dart';
import 'package:project01/utils/category_utils.dart';

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
      // เพื่อความเสถียร ให้คัดลอกเนื้อหาไฟล์ไปยังโฟลเดอร์ซัพพอร์ตของแอปก่อน
      final bytes = await image.readAsBytes();
      final supportDir = await getApplicationSupportDirectory();
      final safeName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
      final safePath = path.join(supportDir.path, safeName);
      final file = File(safePath);
      await file.writeAsBytes(bytes, flush: true);

      // ตรวจสอบว่าไฟล์ถูกเขียนสำเร็จและมีอยู่จริง
      if (!await file.exists()) {
        throw Exception('ไม่สามารถบันทึกไฟล์รูปภาพชั่วคราวได้');
      }

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
    final File? compressed = await ImageCompressor.compressImage(
      imageFile,
      quality: 75,
    );
    return compressed ?? imageFile;
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

      if (!await imageFile.exists()) {
        debugPrint('❌ [UPLOAD] ไฟล์ต้นฉบับไม่มีอยู่จริง: ${imageFile.path}');
        throw Exception('ไม่พบไฟล์รูปภาพ กรุณาลองเลือกรูปใหม่อีกครั้ง');
      }

      debugPrint(
        '🔥 [UPLOAD] ขนาดไฟล์ต้นฉบับ: ${await imageFile.length()} bytes',
      );

      // บีบอัดรูปก่อนอัพโหลด
      debugPrint('🔧 [UPLOAD] เริ่มบีบอัดรูปภาพ...');
      final compressed = await compressImage(imageFile);

      // ใช้ path เดิมที่เคยทำงานได้: images/[userId]/lost_found_...
      final fileName =
          'lost_found_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'images/${user.uid}/$fileName';

      debugPrint('📁 [UPLOAD] ไฟล์: $storagePath');
      final ref = FirebaseStorage.instance.ref().child(storagePath);

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

          final uploadTask = ref.putFile(compressed);

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

              final uploadTask = ref.putData(fileBytes);

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
      rethrow; // Rethrow เพื่อให้ _submitForm แจ้งเตือน user ได้ตรงจุด
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
  String? selectedCategory;
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
    'สนาม',
  ];

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

  Future<bool> _checkDailyPostLimit() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return false;

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

      // ใช้ Query แบบ server-side เพื่อลดการดึงข้อมูลและเพิ่มความเร็ว
      final snapshot =
          await FirebaseFirestore.instance
              .collection('lost_found_items')
              .where('userId', isEqualTo: user.uid)
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .where(
                'createdAt',
                isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
              )
              .get();

      final todayPostCount = snapshot.docs.length;
      debugPrint('📊 Today post count (Server-side): $todayPostCount/5');
      return todayPostCount < 5;
    } catch (e) {
      debugPrint('❌ Error checking daily post limit: $e');
      return true; // ถ้าเกิดข้อผิดพลาด ให้โพสต์ได้
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

    // ตรวจสอบจำนวนโพสต์ต่อวัน
    final canPost = await _checkDailyPostLimit();
    if (!canPost) {
      _showError('คุณโพสต์ครบ 5 โพสต์ต่อวันแล้ว กรุณาลองใหม่พรุ่งนี้');
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

      // 🧠 เรียก Gemini AI เพื่อสร้าง Tags
      setState(() => uploadProgress = 0.90);
      debugPrint('🧠 Generating AI Tags...');
      final List<String> aiTags = await AiTaggingService.generateTags(
        title: titleController.text.trim(),
        description: detailController.text.trim(),
        category: CategoryUtils.getCategoryName(selectedCategory!),
      );
      debugPrint('🧠 AI Tags generated: $aiTags');

      final post = {
        'userId': AuthService.currentUser!.uid,
        'userEmail': AuthService.currentUser!.email,
        'title': titleController.text.trim(),
        'category': selectedCategory,
        'categoryName': CategoryUtils.getCategoryName(selectedCategory!),
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
        'aiTags': aiTags, // บันทึก AI Tags ลง Firestore
      };

      final docRef = await FirebaseFirestore.instance
          .collection('lost_found_items')
          .add(post);

      // เพิ่ม ID จริงเข้าไปใน post data
      post['id'] = docRef.id;
      debugPrint('✅ Created new post with ID: ${docRef.id}');

      // เรียก Smart Matching Service สำหรับโพสต์หาของ
      debugPrint('🚀 Starting smart matching for new lost post...');

      if (mounted) {
        // สั่งให้ระบบแจ้งเตือนทำงานทันที เพื่อจับคู่โพสต์นี้กับคนอื่น
        await Future.delayed(const Duration(seconds: 1));
        await RealtimeNotificationService.refreshCheck(context);
      }
      // อัพเดทจำนวนโพสต์ของผู้ใช้
      await PostCountService.updatePostCount(
        AuthService.currentUser!.uid,
        true, // isLostItem = true สำหรับ lost item
      );

      // บันทึก log การสร้างโพสต์
      await LogService().logPostCreate(
        userId: AuthService.currentUser!.uid,
        userName: AuthService.currentUser!.email?.split('@')[0] ?? 'Unknown',
        postId: docRef.id,
        postTitle: titleController.text.trim(),
        isLostItem: true,
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
      // 🧹 ลบไฟล์ชั่วคราวเสมอไม่ว่าจะสำเร็จหรือไม่
      try {
        if (_imageFile != null && await _imageFile!.exists()) {
          debugPrint('🧹 [CLEANUP] กำลังลบไฟล์ชั่วคราว: ${_imageFile!.path}');
          await _imageFile!.delete();
          _imageFile = null;
        }
      } catch (e) {
        debugPrint('⚠️ [CLEANUP] ไม่สามารถลบไฟล์ได้: $e');
      }
    }
  }

  List<String> _generateSearchKeywords() {
    final keywords = <String>[];
    keywords.add(titleController.text.trim().toLowerCase());
    keywords.add(
      CategoryUtils.getCategoryName(selectedCategory!).toLowerCase(),
    );
    keywords.add(selectedBuilding!.toLowerCase());
    keywords.add(roomController.text.trim().toLowerCase());
    final detailWords = detailController.text.trim().toLowerCase().split(' ');
    keywords.addAll(detailWords.where((word) => word.length > 2));
    return keywords.toSet().toList();
  }

  Future<bool> _showConfirmationDialog() async {
    final theme = Theme.of(context);

    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                backgroundColor: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),

                title: Text(
                  'ยืนยันการบันทึก',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                content: Text(
                  'คุณต้องการบันทึกข้อมูลการแจ้งของหายนี้หรือไม่?',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.85),
                    fontSize: 15,
                  ),
                ),

                actionsPadding: const EdgeInsets.only(bottom: 10, right: 15),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'ยกเลิก',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                    ),
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
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onprimaryColor = Theme.of(context).colorScheme.onPrimary;

    return WillPopScope(
      onWillPop: () async {
        if (isLoading) {
          _showError('กรุณารอให้การอัปโหลดเสร็จสิ้น');
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: Text('แจ้งของหาย', style: TextStyle(color: onprimaryColor)),
          backgroundColor: secondaryColor,
          iconTheme: IconThemeData(color: onprimaryColor),
          elevation: 0,
        ),
        body: Theme(
          data: Theme.of(context).copyWith(
            // ✅ ตั้งค่า TextField ทั้งหมด
            inputDecorationTheme: InputDecorationTheme(
              labelStyle: TextStyle(color: secondaryColor),
              hintStyle: TextStyle(color: secondaryColor.withOpacity(0.6)),
              prefixIconColor: Theme.of(context).colorScheme.secondary,
              suffixIconColor: Theme.of(context).colorScheme.secondary,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: onprimaryColor, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.secondary,
                  width: 2,
                ),
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
              cursorColor: secondaryColor,
              selectionColor: secondaryColor.withOpacity(0.3),
              selectionHandleColor: secondaryColor,
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
                            color: secondaryColor, // ✅ กรอบสี onPrimary
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
                                        color: surfaceColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '(ไม่เกิน 5MB)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: surfaceColor.withOpacity(0.7),
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
                    style: TextStyle(color: onprimaryColor, fontSize: 16),
                    decoration: const InputDecoration(
                      labelText: 'ชื่อสิ่งของที่หาย',
                      prefixIcon: Icon(Icons.inventory),
                    ),
                    validator: ValidationService.validateTitle,
                  ),
                  const SizedBox(height: 20),

                  // ✅ ประเภทสิ่งของ
                  Text(
                    'ประเภทสิ่งของ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
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
                          decoration: InputDecoration(
                            labelText: 'อาคารที่หาย',
                            prefixIcon: Icon(Icons.business),
                          ),
                          style: TextStyle(color: surfaceColor, fontSize: 16),
                          dropdownColor: Theme.of(context).colorScheme.surface,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          items:
                              buildings
                                  .map(
                                    (building) => DropdownMenuItem(
                                      value: building,
                                      child: Text(
                                        building,
                                        style: TextStyle(color: onprimaryColor),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          initialValue: selectedBuilding,
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
                          style: TextStyle(color: onprimaryColor, fontSize: 16),
                          decoration: const InputDecoration(
                            labelText: 'ห้องที่หาย',
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
                    style: TextStyle(color: onprimaryColor, fontSize: 16),
                    decoration: const InputDecoration(
                      labelText: 'ช่องทางการติดต่อ',
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
                    style: TextStyle(color: onprimaryColor, fontSize: 16),
                    decoration: const InputDecoration(
                      labelText: 'รายละเอียดเพิ่มเติม',
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
                            backgroundColor: secondaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 32,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            shadowColor: secondaryColor.withOpacity(0.4),
                            minimumSize: const Size(double.infinity, 56),
                          ),
                          icon:
                              isLoading
                                  ? const BrandedLoading(size: 20)
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

          // 💡 จุดที่เพิ่ม: กำหนด Theme ให้กับ DatePicker
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary:
                      Theme.of(context)
                          .colorScheme
                          .secondary, // ✅ สี Header และวงกลมวันที่เลือก
                  onPrimary:
                      Theme.of(
                        context,
                      ).colorScheme.onPrimary, // ✅ สีตัวอักษรบน Header
                  onSurface:
                      Theme.of(
                        context,
                      ).colorScheme.surface, // ✅ สีของตัวอักษรวันที่
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor:
                        Theme.of(
                          context,
                        ).colorScheme.surface, // ✅ สีปุ่ม 'ยกเลิก', 'ตกลง'
                  ),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            dateController.text = DateFormat('dd/MM/yyyy').format(picked);
          });
        }
      },
      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
      decoration: InputDecoration(
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
          // 💡 จุดที่เพิ่ม: กำหนด Theme ให้กับ TimePicker
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(alwaysUse24HourFormat: true),
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: Theme.of(context).colorScheme.secondary,
                    onPrimary: Colors.white,
                    onSurface: Colors.black87,
                  ),
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
                child: child!,
              ),
            );
          },
        );
        if (picked != null) {
          setState(() {
            timeController.text = MaterialLocalizations.of(
              context,
            ).formatTimeOfDay(picked, alwaysUse24HourFormat: true);
          });
        }
      },
      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
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
    final categoryEntries = CategoryUtils.categoryMap.entries.toList();
    List<Widget> rows = [];
    for (int i = 0; i < categoryEntries.length; i += 2) {
      rows.add(
        Row(
          children: [
            _buildRadioTile(categoryEntries[i].value, categoryEntries[i].key),
            if (i + 1 < categoryEntries.length)
              _buildRadioTile(
                categoryEntries[i + 1].value,
                categoryEntries[i + 1].key,
              )
            else
              const Expanded(child: SizedBox()),
          ],
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildRadioTile(String title, String value) {
    final primaryColor = Theme.of(context).colorScheme.onPrimary;

    return Expanded(
      child: RadioListTile<String>(
        title: Text(
          title,
          style: TextStyle(
            color: primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        value: value,
        groupValue: selectedCategory,
        activeColor: primaryColor,
        fillColor: WidgetStateProperty.all(primaryColor),
        onChanged:
            isLoading ? null : (val) => setState(() => selectedCategory = val),
        contentPadding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
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
