import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project01/widgets/branded_loading.dart';
import 'dart:io';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  File? _image;
  final picker = ImagePicker();
  bool isLoading = false;
  bool isSaving = false;
  String? currentProfileUrl;

  // Track initial values to detect changes
  String _initialName = '';
  bool _hasImageChanged = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['name'] ?? '';
        _initialName = _nameController.text;
        currentProfileUrl = data['profileUrl'];
      }
    }
    setState(() => isLoading = false);
  }

  Future<void> _getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _hasImageChanged = true;
      });
    }
  }

  bool _checkHasChanges() {
    return _nameController.text != _initialName || _hasImageChanged;
  }

  Future<bool> _onWillPop() async {
    if (!_checkHasChanges() || isSaving) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ละทิ้งการแก้ไข?'),
        content: const Text('คุณมีการแก้ไขที่ยังไม่ได้บันทึก ต้องการออกจากหน้านี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ออกจากหน้านี้'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('แก้ไขโปรไฟล์', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () async {
              if (await _onWillPop()) {
                if (mounted) Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            if (!isLoading)
              TextButton(
                onPressed: isSaving ? null : _saveProfile,
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: BrandedLoading(size: 20),
                      )
                    : const Text('บันทึก', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        body: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.surface.withOpacity(0.95),
                colorScheme.surface.withBlue(35).withAlpha(255),
              ],
            ),
          ),
          child: isLoading
              ? const BrandedLoading()
              : Stack(
                  children: [
                    SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              const SizedBox(height: 10),
                              Center(
                                child: GestureDetector(
                                  onTap: _getImage,
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.3),
                                              blurRadius: 15,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                          border: Border.all(
                                            color: colorScheme.primary.withOpacity(0.5),
                                            width: 3,
                                          ),
                                        ),
                                        child: CircleAvatar(
                                          radius: 65,
                                          backgroundColor: colorScheme.surfaceVariant,
                                          backgroundImage: _image != null
                                              ? FileImage(_image!)
                                              : (currentProfileUrl != null
                                                  ? NetworkImage(currentProfileUrl!)
                                                  : null) as ImageProvider?,
                                          child: _image == null && currentProfileUrl == null
                                              ? Icon(Icons.person, size: 70, color: colorScheme.onSurfaceVariant)
                                              : null,
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.2),
                                                blurRadius: 5,
                                                spreadRadius: 1,
                                              )
                                            ],
                                          ),
                                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 48),
                              _buildTextField(
                                controller: _nameController,
                                label: 'ชื่อ-นามสกุล',
                                icon: Icons.person_outline,
                                validator: (value) => value == null || value.isEmpty ? 'กรุณากรอกชื่อ' : null,
                              ),
                              const SizedBox(height: 40),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: isSaving ? null : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: isSaving
                                      ? const BrandedLoading(size: 24)
                                      : const Text(
                                          'บันทึกการเปลี่ยนแปลง',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: TextButton(
                                  onPressed: () async {
                                    if (await _onWillPop()) {
                                      if (mounted) Navigator.of(context).pop();
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                                    ),
                                  ),
                                  child: const Text(
                                    'ยกเลิก',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (isSaving)
                      Container(
                        color: Colors.black45,
                        child: const BrandedLoading(),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 16),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      String? profileUrl = currentProfileUrl;

      if (_image != null) {
        final ref = FirebaseStorage.instance.ref().child('profile_images').child('${user.uid}.jpg');
        await ref.putFile(_image!);
        profileUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'profileUrl': profileUrl,
      });

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }
}
