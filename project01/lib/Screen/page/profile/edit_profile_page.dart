import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:typed_data';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  File? _imageFile;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('แก้ไขโปรไฟล์'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: isLoading ? null : () => Navigator.pop(context),
          ),
          actions: [
            if (!isLoading)
              TextButton(onPressed: _saveProfile, child: const Text('บันทึก'))
            else
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('กำลังโหลดข้อมูล...'),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'เกิดข้อผิดพลาด',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {}); // refresh
                      },
                      child: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              );
            }

            final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_nameController.text != (data['name'] ?? user?.displayName)) {
                _nameController.text = data['name'] ?? user?.displayName ?? '';
              }
              if (_phoneController.text != data['phone']) {
                _phoneController.text = data['phone'] ?? '';
              }
            });

            return Stack(
              children: [
                Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildProfileImage(data),
                      const SizedBox(height: 24),
                      _buildNameField(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                if (isLoading)
                  Container(
                    color: Colors.black12,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileImage(Map<String, dynamic> data) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage:
                _imageFile != null
                    ? FileImage(_imageFile!)
                    : (data['profileUrl']?.isNotEmpty == true ||
                        user?.photoURL?.isNotEmpty == true)
                    ? CachedNetworkImageProvider(
                      data['profileUrl'] ?? user!.photoURL!,
                    )
                    : null,
            child:
                (_imageFile == null &&
                        data['profileUrl'] == null &&
                        user?.photoURL == null)
                    ? const Icon(Icons.person, size: 50, color: Colors.grey)
                    : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).primaryColor,
              child: IconButton(
                icon: const Icon(Icons.camera_alt, size: 18),
                onPressed: _pickImage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'ชื่อ',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'กรุณากรอกชื่อ';
        }
        return null;
      },
    );
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (image != null) {
        // อ่าน bytes แล้วเขียนไฟล์ใหม่ไปยัง temporary directory ของแอป
        final bytes = await image.readAsBytes();
        final tempDir = await getTemporaryDirectory();
        final safeName =
            '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
        final safePath = path.join(tempDir.path, safeName);
        final file = File(safePath);
        await file.writeAsBytes(bytes, flush: true);

        setState(() {
          _imageFile = file;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ไม่สามารถเลือกรูปภาพได้: $e')));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      String? photoURL = user?.photoURL;

      if (_imageFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${user!.uid}.jpg');

        // metadata
        final ext = path.extension(_imageFile!.path).toLowerCase();
        final contentType = ext == '.png' ? 'image/png' : 'image/jpeg';
        final metadata = SettableMetadata(contentType: contentType);

        // Upload with retries and fallback to putData
        Uint8List? fileBytes;
        const int maxAttempts = 3;
        for (int attempt = 1; attempt <= maxAttempts; attempt++) {
          try {
            final uploadTask = ref.putFile(_imageFile!, metadata);

            // wait with timeout
            final snapshot = await uploadTask.timeout(
              const Duration(minutes: 2),
              onTimeout: () {
                uploadTask.cancel();
                throw Exception('การอัพโหลดใช้เวลานานเกินไป');
              },
            );

            photoURL = await snapshot.ref.getDownloadURL();
            break;
          } catch (e) {
            debugPrint('Profile upload attempt $attempt failed: $e');
            if (attempt == maxAttempts) {
              // fallback to putData
              try {
                fileBytes ??= Uint8List.fromList(
                  await _imageFile!.readAsBytes(),
                );
                final uploadTask = ref.putData(fileBytes, metadata);
                final snapshot = await uploadTask.timeout(
                  const Duration(minutes: 2),
                  onTimeout: () {
                    uploadTask.cancel();
                    throw Exception('การอัพโหลดใช้เวลานานเกินไป (putData)');
                  },
                );
                photoURL = await snapshot.ref.getDownloadURL();
                break;
              } catch (fallbackError) {
                debugPrint('Profile fallback putData failed: $fallbackError');
                rethrow;
              }
            } else {
              await Future.delayed(Duration(seconds: attempt * 2));
            }
          }
        }
      }

      final updatedData = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'profileUrl': photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update(updatedData);

      await user?.updateDisplayName(_nameController.text);
      if (photoURL != null) {
        await user?.updatePhotoURL(photoURL);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกข้อมูลสำเร็จ'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // Defensive handling for a known Pigeon/platform-channel cast issue
      final errStr = e.toString();
      if (errStr.contains('PigeonUser') || errStr.contains('List<Object')) {
        debugPrint(
          'Detected Pigeon/list cast error during profile save: $errStr',
        );
        // Try a lightweight recovery: reload current user and sign out to clear plugin state
        try {
          await FirebaseAuth.instance.currentUser?.reload();
          // attempt programmatic sign-out to clear any plugin-side cached state
          await FirebaseAuth.instance.signOut();
        } catch (clearError) {
          debugPrint('Error while attempting to clear auth state: $clearError');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'เกิดปัญหาชั่วคราวกับระบบเชื่อมต่อ (Pigeon). กรุณาออกจากระบบ แล้วเข้าสู่ระบบใหม่ แล้วลองอัพเดตรูปอีกครั้ง',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
