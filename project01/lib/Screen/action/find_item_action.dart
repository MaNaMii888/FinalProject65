import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';

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
  final TextEditingController detailController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController locationDetailController =
      TextEditingController();
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        // TODO: Implement form submission logic
        // Upload image if exists
        // Save form data to database

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อสิ่งของที่หาย',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value?.isEmpty ?? true ? 'กรุณากรอกชื่อสิ่งของ' : null,
              ),
              const SizedBox(height: 20),
              const Text('ประเภทสิ่งของ'),
              _buildCategoryRadios(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'อาคารที่หาย',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: '1', child: Text('อาคาร 1')),
                        DropdownMenuItem(value: '2', child: Text('อาคาร 2')),
                        DropdownMenuItem(value: '3', child: Text('อาคาร 3')),
                      ],
                      value: selectedBuilding,
                      validator:
                          (value) => value == null ? 'กรุณาเลือกอาคาร' : null,
                      onChanged:
                          (value) => setState(() => selectedBuilding = value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'ห้องที่หาย',
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
              TextFormField(
                controller: contactController,
                decoration: const InputDecoration(
                  labelText: 'ช่องทางการติดต่อ',
                  hintText: 'เบอร์โทร/ID Line',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value?.isEmpty ?? true
                            ? 'กรุณากรอกช่องทางการติดต่อ'
                            : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: dateController,
                readOnly: true, // ป้องกันการพิมพ์โดยตรง
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(), // จำกัดไม่ให้เลือกวันในอนาคต
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: Theme.of(context).primaryColor,
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
                  labelText:
                      'วันที่หาย', // หรือ 'วันที่หาย' สำหรับ LostItemForm
                  hintText: 'เลือกวันที่',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today), // เพิ่มไอคอนปฏิทิน
                ),
                validator:
                    (value) =>
                        value?.isEmpty ?? true ? 'กรุณาเลือกวันที่' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: detailController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'รายละเอียดเพิ่มเติม',
                  hintText: 'ระบุลักษณะเฉพาะของสิ่งของ',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value?.isEmpty ?? true ? 'กรุณากรอกรายละเอียด' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child:
                      isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'บันทึกการแจ้งของหาย',
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
        onChanged: (value) => setState(() => selectedCategory = value),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    dateController.dispose();
    detailController.dispose();
    contactController.dispose();
    locationDetailController.dispose();
    super.dispose();
  }
}

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
  final TextEditingController detailController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController locationDetailController =
      TextEditingController();
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        // TODO: Implement form submission logic
        // Upload image if exists
        // Save form data to database

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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // จัดการการกดปุ่มย้อนกลับ
        Navigator.of(context).pop();
        return true;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: AppBar(
            title: const Text('แจ้งเจอของ'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            elevation: 0,
            centerTitle: true,
          ),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                  child: Image.file(
                                    _imageFile!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : const Icon(
                                  Icons.add_photo_alternate,
                                  size: 50,
                                ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อสิ่งของที่พบ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกชื่อสิ่งของ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('ประเภทสิ่งของ'),
                  _buildCategoryRadios(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'อาคาร',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: '1',
                              child: Text('อาคาร 1'),
                            ),
                            DropdownMenuItem(
                              value: '2',
                              child: Text('อาคาร 2'),
                            ),
                            DropdownMenuItem(
                              value: '3',
                              child: Text('อาคาร 3'),
                            ),
                          ],
                          value: selectedBuilding,
                          validator: (value) {
                            if (value == null) {
                              return 'กรุณาเลือกอาคาร';
                            }
                            return null;
                          },
                          onChanged:
                              (value) =>
                                  setState(() => selectedBuilding = value),
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณากรอกห้อง';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: contactController,
                    decoration: const InputDecoration(
                      labelText: 'ช่องทางการติดต่อ',
                      hintText: 'เบอร์โทร/ID Line',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกช่องทางการติดต่อ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: dateController,
                    readOnly: true, // ป้องกันการพิมพ์โดยตรง
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(), // จำกัดไม่ให้เลือกวันในอนาคต
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: Theme.of(context).primaryColor,
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
                      labelText:
                          'วันที่พบ', // หรือ 'วันที่หาย' สำหรับ LostItemForm
                      hintText: 'เลือกวันที่',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(
                        Icons.calendar_today,
                      ), // เพิ่มไอคอนปฏิทิน
                    ),
                    validator:
                        (value) =>
                            value?.isEmpty ?? true ? 'กรุณาเลือกวันที่' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: detailController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'รายละเอียดเพิ่มเติม',
                      hintText: 'ระบุลักษณะเฉพาะของสิ่งของ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกรายละเอียด';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[400],
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child:
                          isLoading
                              ? const CircularProgressIndicator()
                              : const Text('บันทึกการแจ้งเจอของ'),
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
        onChanged: (value) => setState(() => selectedCategory = value),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    dateController.dispose();
    detailController.dispose();
    contactController.dispose();
    locationDetailController.dispose();
    super.dispose();
  }
}
