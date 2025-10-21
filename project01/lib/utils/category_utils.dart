// category_utils.dart
// Utility class สำหรับจัดการข้อมูลหมวดหมู่สิ่งของ

class CategoryUtils {
  // แปลงรหัสหมวดหมู่เป็นชื่อ
  static String getCategoryName(String categoryId) {
    switch (categoryId) {
      case '1':
        return 'ของใช้ส่วนตัว';
      case '2':
        return 'เอกสาร/บัตร';
      case '3':
        return 'อุปกรณ์การเรียน';
      case '4':
        return 'ของมีค่าอื่นๆ';
      default:
        return categoryId.isEmpty ? 'ไม่ระบุ' : categoryId;
    }
  }

  // แมปหมวดหมู่ทั้งหมด (รหัส: ชื่อ)
  static const Map<String, String> categoryMap = {
    '1': 'ของใช้ส่วนตัว',
    '2': 'เอกสาร/บัตร',
    '3': 'อุปกรณ์การเรียน',
    '4': 'ของมีค่าอื่นๆ',
  };

  // รายการหมวดหมู่ทั้งหมด (สำหรับ dropdown)
  static List<Map<String, String>> get categoryList {
    return categoryMap.entries
        .map((entry) => {'id': entry.key, 'name': entry.value})
        .toList();
  }

  // ตรวจสอบว่ารหัสหมวดหมู่ถูกต้องหรือไม่
  static bool isValidCategoryId(String categoryId) {
    return categoryMap.containsKey(categoryId);
  }
}
