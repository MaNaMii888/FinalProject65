import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:project01/models/post.dart';
import 'package:project01/services/notifications_service.dart';
import 'package:project01/Screen/page/map/mapmodel/building_data.dart';

class SmartMatchingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // เก็บ cache ของการวิเคราะห์ผู้ใช้ชั่วคราว
  static final Map<String, UserMatchingProfile> _userProfileCache = {};

  /// เรียกทุกครั้งที่มีการโพสต์ใหม่
  static Future<void> processNewPost(Map<String, dynamic> newPostData) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      debugPrint('🔍 Processing new post for matching...');

      // ตรวจสอบว่ามี ID หรือไม่
      if (!newPostData.containsKey('id') ||
          newPostData['id'] == null ||
          newPostData['id'] == 'temp') {
        debugPrint('❌ Error: newPostData does not contain a valid ID');
        return;
      }

      // 1. แปลงข้อมูลเป็น Post object
      final newPost = Post.fromJson(newPostData);
      debugPrint(
        '📝 Processing post ID: ${newPost.id}, title: ${newPost.title}',
      );

      // 2. หาผู้ใช้ที่อาจสนใจ (แบบ batch)
      await _findPotentialMatches(newPost, currentUserId);
    } catch (e) {
      debugPrint('❌ Error in processNewPost: $e');
    }
  }

  /// หาผู้ใช้ที่อาจสนใจโพสต์ใหม่
  static Future<void> _findPotentialMatches(
    Post newPost,
    String excludeUserId,
  ) async {
    try {
      // เก็บข้อมูลการ match ลง collection พิเศษ
      final matchingData = {
        'postId': newPost.id,
        'postUserId': excludeUserId,
        'postTitle': newPost.title,
        'postCategory': newPost.category,
        'postBuilding': newPost.building,
        'postType': newPost.isLostItem ? 'lost' : 'found',
        'searchableText':
            '${newPost.title} ${newPost.description}'.toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
        'processed': false, // จะใช้ตอน background processing
      };

      // บันทึกลง "post_matching_queue" สำหรับประมวลผลทีหลัง
      await _firestore.collection('post_matching_queue').add(matchingData);

      // === การแมชแบบสองทาง ===

      // 1. หาผู้ใช้ที่อาจสนใจโพสต์นี้ (แบบเดิม)
      await _processImmediateMatching(newPost, excludeUserId);

      // 2. หาโพสต์ประเภทตรงข้ามที่มีอยู่แล้ว (ใหม่!)
      await _checkExistingOppositePosts(newPost, excludeUserId);
    } catch (e) {
      debugPrint('❌ Error in _findPotentialMatches: $e');
    }
  }

  /// ประมวลผลทันทีสำหรับผู้ใช้ที่ active
  static Future<void> _processImmediateMatching(
    Post newPost,
    String excludeUserId,
  ) async {
    try {
      // หาผู้ใช้ที่เปิดแอพอยู่ใน 1 ชั่วโมงที่ผ่านมา
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));

      final activeUsers =
          await _firestore
              .collection('user_activity')
              .where(
                'lastActive',
                isGreaterThan: Timestamp.fromDate(oneHourAgo),
              )
              .where('userId', isNotEqualTo: excludeUserId)
              .limit(20) // จำกัดเพื่อประสิทธิภาพ
              .get();

      for (var userDoc in activeUsers.docs) {
        final userId = userDoc.data()['userId'] as String;
        await _checkUserPostMatch(userId, newPost);
      }
    } catch (e) {
      debugPrint('❌ Error in _processImmediateMatching: $e');
    }
  }

  /// ตรวจสอบโพสต์ประเภทตรงข้ามที่มีอยู่แล้ว
  static Future<void> _checkExistingOppositePosts(
    Post newPost,
    String excludeUserId,
  ) async {
    try {
      debugPrint('🔍 Checking existing opposite posts...');

      // หาโพสต์ประเภทตรงข้าม
      final oppositeType = !newPost.isLostItem;

      // ค้นหาโพสต์ที่อาจตรงกัน
      final snapshot =
          await _firestore
              .collection('lost_found_items')
              .where('isLostItem', isEqualTo: oppositeType)
              .limit(100)
              .get();

      // กรองข้อมูลใน client side
      final oppositePosts =
          snapshot.docs
              .map((doc) => Post.fromJson({...doc.data(), 'id': doc.id}))
              .where(
                (post) =>
                    post.userId != excludeUserId && (post.status == 'active'),
              )
              .toList();

      debugPrint('📊 Found ${oppositePosts.length} opposite posts to check');

      // ตรวจสอบความเข้ากันได้แต่ละโพสต์
      for (var oppositePost in oppositePosts) {
        await _checkPostCompatibility(newPost, oppositePost, excludeUserId);
      }
    } catch (e) {
      debugPrint('❌ Error in _checkExistingOppositePosts: $e');
    }
  }

  /// ตรวจสอบความเข้ากันได้ระหว่างโพสต์ใหม่กับโพสต์ที่มีอยู่
  static Future<void> _checkPostCompatibility(
    Post newPost,
    Post existingPost,
    String newPostUserId,
  ) async {
    try {
      // คำนวณคะแนนความคล้ายคลึง
      final matchScore = calculatePostSimilarity(existingPost, newPost);

      debugPrint(
        '🎯 Match score between "${newPost.title}" and "${existingPost.title}": ${(matchScore * 100).round()}%',
      );

      // ส่งการแจ้งเตือนหากคะแนนสูงพอ (เกณฑ์ 55%)
      if (matchScore >= 0.55) {
        debugPrint('✅ Match found! Sending notifications to both users...');

        // แจ้งเตือนไปยังเจ้าของโพสต์เดิม
        await _sendMatchNotification(
          userId: existingPost.userId,
          newPost: newPost,
          matchingPost: existingPost,
          matchScore: matchScore,
        );

        // แจ้งเตือนไปยังเจ้าของโพสต์ใหม่ด้วย
        await _sendMatchNotification(
          userId: newPost.userId,
          newPost: existingPost,
          matchingPost: newPost,
          matchScore: matchScore,
        );

        // บันทึกการแมชลงใน Firebase เพื่อไว้ติดตาม
        await _saveMatchRecord(newPost, existingPost, matchScore);
      }
    } catch (e) {
      debugPrint('❌ Error in _checkPostCompatibility: $e');
    }
  }

  /// บันทึกประวัติการแมช
  static Future<void> _saveMatchRecord(
    Post newPost,
    Post existingPost,
    double matchScore,
  ) async {
    try {
      await _firestore.collection('post_matches').add({
        'newPostId': newPost.id,
        'newPostUserId': newPost.userId,
        'newPostTitle': newPost.title,
        'newPostType': newPost.isLostItem ? 'lost' : 'found',
        'existingPostId': existingPost.id,
        'existingPostUserId': existingPost.userId,
        'existingPostTitle': existingPost.title,
        'existingPostType': existingPost.isLostItem ? 'lost' : 'found',
        'matchScore': matchScore,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, contacted, resolved
      });
    } catch (e) {
      debugPrint('❌ Error saving match record: $e');
    }
  }

  /// ตรวจสอบโพสต์ของผู้ใช้คนหนึ่งกับโพสต์ใหม่
  static Future<void> _checkUserPostMatch(String userId, Post newPost) async {
    try {
      // หา profile ของผู้ใช้ (ใช้ cache ถ้ามี)
      UserMatchingProfile? profile = _userProfileCache[userId];

      if (profile == null) {
        profile = await _getUserMatchingProfile(userId);
        _userProfileCache[userId] = profile;
      }

      // คำนวณ match score (เทียบกับโพสต์ทั้งหมดของผู้ใช้นี้)
      double bestMatchScore = 0.0;
      Post? bestMatchPost;

      for (var userPost in profile.userPosts) {
        double score = calculatePostSimilarity(userPost, newPost);
        if (score > bestMatchScore) {
          bestMatchScore = score;
          bestMatchPost = userPost;
        }
      }

      // ส่ง notification หากคะแนนสูงกว่า threshold
      if (bestMatchScore >= 0.55 && bestMatchPost != null) {
        await _sendMatchNotification(
          userId: userId,
          newPost: newPost,
          matchingPost: bestMatchPost,
          matchScore: bestMatchScore,
        );
      }
    } catch (e) {
      debugPrint('❌ Error in _checkUserPostMatch: $e');
    }
  }

  /// ดึง profile การ match ของผู้ใช้
  static Future<UserMatchingProfile> _getUserMatchingProfile(
    String userId,
  ) async {
    try {
      final userPosts =
          await _firestore
              .collection('lost_found_items')
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .limit(50)
              .get();

      final posts =
          userPosts.docs
              .map((doc) => Post.fromJson({...doc.data(), 'id': doc.id}))
              .toList();

      return UserMatchingProfile(
        userId: userId,
        userPosts: posts,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error getting user profile: $e');
      return UserMatchingProfile(
        userId: userId,
        userPosts: [],
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// คำนวณความคล้ายคลึงระหว่างโพสต์ (เวอร์ชันปรับปรุงตามน้ำหนักใหม่)
  static double calculatePostSimilarity(Post userPost, Post newPost) {
    // 0. ประเภทตรงข้ามเท่านั้นที่จะ Match กัน - ถ้าประเภทเดียวกันให้คะแนน 0
    if (userPost.isLostItem == newPost.isLostItem) {
      return 0.0;
    }

    double score = 0.0;
    String t1 = userPost.title.toLowerCase().trim();
    String t2 = newPost.title.toLowerCase().trim();

    // 1. Token Overlap Score (40%) - ใกล้เคียง Jaccard แต่ใช้ Overlap Coefficient (เน้นคำสั้นในคำยาว)
    double overlapSim = _overlapCoefficient(t1, t2);
    double titleOverlapScore = overlapSim * 0.40;
    score += titleOverlapScore;

    // 2. Substring Bonus (20%) - คำสั้นเป็นซับสตริงของคำยาว
    double substringBonus = (t1.contains(t2) || t2.contains(t1)) ? 0.20 : 0.0;
    score += substringBonus;

    // 3. Dice Coefficient (15%) - ป้องกันคำที่พิมพ์คล้ายกันแต่ไม่ใช่แบบ substring
    double diceSim = _diceCoefficient(t1, t2);
    double titleDiceScore = diceSim * 0.15;
    score += titleDiceScore;

    double titleScore = titleOverlapScore + substringBonus + titleDiceScore;

    // 4. AI Semantic Context (25%)
    if (userPost.aiTags != null &&
        userPost.aiTags!.isNotEmpty &&
        newPost.aiTags != null &&
        newPost.aiTags!.isNotEmpty) {
      int commonTags =
          userPost.aiTags!.where((tag) => newPost.aiTags!.contains(tag)).length;
      int minTags = userPost.aiTags!.length < newPost.aiTags!.length
          ? userPost.aiTags!.length
          : newPost.aiTags!.length;
      double tagSim = minTags > 0 ? commonTags / minTags : 0.0;
      score += tagSim * 0.25;
    } else {
      // Fallback: description similarity
      double descSim = _calculateTextSimilarity(userPost.description, newPost.description);
      score += descSim * 0.25;
    }

    // ถ้าคะแนน Item Match (Title + Data) ต่ำกว่าเกณฑ์ แปลว่าของคนละชนิดกันแน่นอน (ตัด False Positive)
    // แต่ถ้าคะแนนของ Title ค่อนข้างคล้ายกันมากๆ (>= 35%) ก็ยังเก็บไว้บวกคะแนน context เพิ่มได้
    if (score < 0.45 && titleScore < 0.35) {
      return 0.0;
    }

    // --- Bonus Context Score --- (สามารถช่วยดันให้คะแนนดีขึ้นถ้าของชนิดเดียวกัน)
    // อาคารและสถานที่หลัก (10%)
    final parent1 = getParentBuilding(userPost.building);
    final parent2 = getParentBuilding(newPost.building);
    if (parent1 == parent2 && parent1.isNotEmpty) {
      score += 0.10;
    }

    // ห้อง/ชั้นใกล้เคียง (5%)
    double roomSim = _diceCoefficient(userPost.location, newPost.location);
    if (roomSim > 0.3) {
      score += 0.05;
    }

    // หมวดหมู่เดียวกัน (10%)
    if (userPost.category == newPost.category && userPost.category.isNotEmpty) {
      score += 0.10;
    }

    return score > 1.0 ? 1.0 : score;
  }

  /// คำนวณ Overlap Coefficient (ดีสำหรับหาคำที่ซ่อนอยู่ในอีกคำ)
  static double _overlapCoefficient(String s1, String s2) {
    String str1 = s1.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    String str2 = s2.replaceAll(RegExp(r'\s+'), '').toLowerCase();

    if (str1 == str2) return 1.0;
    if (str1.length < 2 || str2.length < 2) return 0.0;

    Set<String> getBigrams(String s) {
      Set<String> bigrams = {};
      for (int i = 0; i < s.length - 1; i++) {
        bigrams.add(s.substring(i, i + 2));
      }
      return bigrams;
    }

    Set<String> bigrams1 = getBigrams(str1);
    Set<String> bigrams2 = getBigrams(str2);

    int intersection = bigrams1.where((b) => bigrams2.contains(b)).length;
    int minLen = bigrams1.length < bigrams2.length ? bigrams1.length : bigrams2.length;
    return minLen > 0 ? intersection / minLen : 0.0;
  }

  /// คำนวณ Sorensen-Dice coefficient สำหรับความคล้ายคลึงของข้อความ (ดีสำหรับภาษาไทย)

  static double _diceCoefficient(String s1, String s2) {
    String str1 = s1.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    String str2 = s2.replaceAll(RegExp(r'\s+'), '').toLowerCase();

    if (str1 == str2) return 1.0;
    if (str1.length < 2 || str2.length < 2) return 0.0;

    Set<String> getBigrams(String s) {
      Set<String> bigrams = {};
      for (int i = 0; i < s.length - 1; i++) {
        bigrams.add(s.substring(i, i + 2));
      }
      return bigrams;
    }

    Set<String> bigrams1 = getBigrams(str1);
    Set<String> bigrams2 = getBigrams(str2);

    int intersection = bigrams1.where((b) => bigrams2.contains(b)).length;
    return (2.0 * intersection) / (bigrams1.length + bigrams2.length);
  }

  /// คำนวณความคล้ายคลึงของข้อความแบบ Keyword base (Fallback)
  static double _calculateTextSimilarity(String text1, String text2) {
    if (text1.isEmpty || text2.isEmpty) return 0.0;

    List<String> words1 = _extractKeywords(text1);
    List<String> words2 = _extractKeywords(text2);

    if (words1.isEmpty || words2.isEmpty) return 0.0;

    int commonWords = 0;
    for (String word1 in words1) {
      for (String word2 in words2) {
        if (word1.toLowerCase() == word2.toLowerCase()) {
          commonWords++;
          break;
        }
      }
    }

    int totalUniqueWords = words1.toSet().union(words2.toSet()).length;
    return totalUniqueWords > 0 ? commonWords / totalUniqueWords : 0.0;
  }

  /// แยกคำสำคัญ
  static List<String> _extractKeywords(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'[\s,.-]+'))
        .where((word) => word.length > 2)
        .toList();
  }

  /// ส่ง notification เมื่อพบ match
  static Future<void> _sendMatchNotification({
    required String userId,
    required Post newPost,
    required Post matchingPost,
    required double matchScore,
  }) async {
    try {
      // สร้างเหตุผลการจับคู่เพื่อช่วยผู้ใช้เข้าใจ
      final reasons = getPostMatchReasons(matchingPost, newPost);

      await NotificationService.createSmartMatchNotification(
        targetUserId: userId,
        matchedPost: newPost,
        relatedPost: matchingPost,
        matchScore: matchScore,
        matchReasons: reasons,
      );

      debugPrint('✅ Sent smart match notification to user $userId');
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
    }
  }

  /// อธิบายเหตุผลการจับคู่แบบย่อเพื่อแสดงใน UI
  static List<String> getPostMatchReasons(Post userPost, Post otherPost) {
    final List<String> reasons = [];
    String t1 = userPost.title.toLowerCase().trim();
    String t2 = otherPost.title.toLowerCase().trim();

    // 1. Token/Substring (Name)
    double overlapSim = _overlapCoefficient(t1, t2);
    if (overlapSim > 0.4) {
      int percent = (overlapSim * 40).round();
      reasons.add('✓ ชื่อสิ่งของตรงกัน: ${otherPost.title} (+$percent%)');
    }

    if (t1.contains(t2) || t2.contains(t1)) {
      reasons.add('✓ สิ่งของชนิดเดียวกันเป๊ะ (+20%)');
    }

    // 2. อาคารและสถานที่
    final parentUser = getParentBuilding(userPost.building);
    final parentOther = getParentBuilding(otherPost.building);
    if (parentUser == parentOther && parentUser.isNotEmpty) {
      reasons.add('✓ อาคารเดียวกัน: $parentUser (+10%)');
    }

    double roomSim = _diceCoefficient(userPost.location, otherPost.location);
    if (roomSim > 0.3) {
      reasons.add('✓ ระบุสถานที่ใกล้เคียงกัน (+5%)');
    }

    // 3. AI Semantic Tags
    if (userPost.aiTags != null &&
        userPost.aiTags!.isNotEmpty &&
        otherPost.aiTags != null &&
        otherPost.aiTags!.isNotEmpty) {
      int commonTags =
          userPost.aiTags!.where((tag) => otherPost.aiTags!.contains(tag)).length;
      int minTags = userPost.aiTags!.length < otherPost.aiTags!.length
          ? userPost.aiTags!.length
          : otherPost.aiTags!.length;
      double tagSim = minTags > 0 ? commonTags / minTags : 0.0;
      if (tagSim > 0.0) {
        int percent = (tagSim * 25).round();
        reasons.add('🧠 AI ตรวจพบคุณสมบัติที่ตรงกัน (+$percent%)');
      }
    }

    // 4. หมวดหมู่ (Category)
    if (userPost.category == otherPost.category && userPost.category.isNotEmpty) {
      reasons.add('✓ หมวดหมู่เดียวกัน (+10%)');
    }

    return reasons;
  }

  /// อัพเดท user activity (เรียกเมื่อเปิดแอพ)
  static Future<void> updateUserActivity(String userId) async {
    if (userId.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Quiet fail
    }
  }
}

class UserMatchingProfile {
  final String userId;
  final List<Post> userPosts;
  final DateTime lastUpdated;

  UserMatchingProfile({
    required this.userId,
    required this.userPosts,
    required this.lastUpdated,
  });
}
