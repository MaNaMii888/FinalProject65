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

      // 2. ออกแบบ Prompt สั่งให้ AI ทำงานเป็นระบบ Tagging
      final prompt = '''
      วิเคราะห์ข้อมูลโพสต์หาของหาย/เจอของ ต่อไปนี้:
      ชื่อเรื่อง: $title
      รายละเอียด: $description
      หมวดหมู่: $category

      งานของคุณคือ:
      สกัดคีย์เวิร์ด (tags) ที่สำคัญที่สุดเกี่ยวกับสิ่งของนี้เพื่อใช้ในระบบค้นหาและจับคู่
      - ให้คีย์เวิร์ดครอบคลุมทั้ง ลักษณะ, สี, ยี่ห้อ, ประเภทสิ่งของ
      - รวมคำที่มีความหมายเหมือนกัน (synonyms) เช่น ถ้าเป็นกระเป๋าเงิน ให้รวมคำว่า "wallet", "เป๋าตัง" ด้วย
      - ส่งกลับเฉพาะ array ของ string ในรูปแบบ JSON เท่านั้น ห้ามตอบอธิบายใดๆ เพิ่มเติม
      ตัวอย่างคำตอบ: ["wallet", "กระเป๋าตัง", "กระเป๋าเงิน", "สีดำ", "ใบสั้น"]
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
