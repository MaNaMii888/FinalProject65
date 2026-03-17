import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiTaggingService {
  // API Key ของ Gemini (Google AI Studio) ที่ผู้ใช้ให้มา
  static const String _apiKey = 'AIzaSyCGv2-6qdbtO4eexGkLYbfDaz7ueOupkms';

  /// ฟังก์ชันส่งคำอธิบาย(และ/หรือรูปภาพ) ไปให้ Gemini วิเคราะห์และคืนค่าเป็นรายการ Keyword (Tags)
  static Future<List<String>> generateTags({
    required String title,
    required String description,
    required String category,
  }) async {
    try {
      // 1. สร้างโมเดลของ Gemini (ใช้ flash เพราะเร็วและประหยัด)
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);

      // 2. ออกแบบ Prompt สั่งให้ AI ทำงานเป็นระบบ Tagging แบบเจาะลึก
      final prompt = '''
      วิเคราะห์ข้อมูลโพสต์หาของหาย/เจอของ ต่อไปนี้เพื่อสร้าง Smart Tags สำหรับระบบจับคู่:
      ชื่อเรื่อง: $title
      รายละเอียด: $description
      หมวดหมู่: $category

      งานของคุณคือสกัดคีย์เวิร์ด (tags) ที่สำคัญที่สุดในรูปแบบ JSON รายการเดียว (Flat Array) โดยต้องครอบคลุม:
      1. canonical_name: ชื่อเรียกมาตรฐานของสิ่งของ (เช่น "iphone 15 pro", "กระเป๋าสตางค์")
      2. synonyms_bilingual: คำเรียกอื่นๆ ทั้งภาษาไทยและอังกฤษ (เช่น "wallet", "เป๋าตัง", "notebook", "สมุด")
      3. attributes: สี (color), ยี่ห้อ (brand), ขนาด (size), ลักษณะเด่น (distinctive_features)
      4. category_context: บริบทการใช้งาน

      กฎการตอบกลับ:
      - ส่งกลับเฉพาะ array ของ string ในรูปแบบ JSON เท่านั้น (เช่น ["iphone", "ไอโฟน", "สีดำ", "เคสใส"])
      - ห้ามมีหัวข้อหรือคำอธิบายใดๆ
      - คัดเฉพาะคำที่เป็น Keywords สำคัญจริงๆ
      ''';

      // 3. ส่งคำสั่งไปยัง AI
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        // 4. แปลงคำตอบ JSON String ให้กลายเป็น List<String>
        final String rawJson =
            response.text!
                .replaceAll('```json', '')
                .replaceAll('```', '')
                .trim();
        final List<dynamic> decoded = jsonDecode(rawJson);
        return decoded.map((e) => e.toString().toLowerCase()).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error generating AI tags: $e');
      return [];
    }
  }
}
