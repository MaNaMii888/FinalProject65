import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:project01/models/post.dart';
import 'package:project01/services/notifications_service.dart';

/// Smart Matching Service for Post Similarity Detection
/// แนวทาง Hybrid: Background Processing + Smart Caching
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
      // ถ้าโพสต์ใหม่เป็น "หาของ" (lost) → หาใน "พบของ" (found)
      // ถ้าโพสต์ใหม่เป็น "พบของ" (found) → หาใน "หาของ" (lost)
      final oppositeType = !newPost.isLostItem;

      // ค้นหาโพสต์ที่อาจตรงกัน โดยใช้เงื่อนไขพื้นฐาน
      Query query = _firestore
          .collection('lost_found_items')
          .where('isLostItem', isEqualTo: oppositeType)
          .where('userId', isNotEqualTo: excludeUserId)
          .where('status', isEqualTo: 'active'); // เฉพาะโพสต์ที่ยังคงใช้งาน

      // เพิ่มเงื่อนไขเพื่อความแม่นยำ
      if (newPost.category.isNotEmpty) {
        query = query.where('category', isEqualTo: newPost.category);
      }

      final snapshot =
          await query
              .orderBy('createdAt', descending: true)
              .limit(50) // จำกัดเพื่อประสิทธิภาพ
              .get();

      final oppositePosts =
          snapshot.docs
              .map(
                (doc) => Post.fromJson({
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id,
                }),
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
      final matchScore = _calculatePostSimilarity(existingPost, newPost);

      debugPrint(
        '🎯 Match score between "${newPost.title}" and "${existingPost.title}": ${(matchScore * 100).round()}%',
      );

      // ส่งการแจ้งเตือนหากคะแนนสูงพอ (เกณฑ์ 60%)
      if (matchScore >= 0.6) {
        debugPrint('✅ Match found! Sending notifications to both users...');

        // แจ้งเตือนไปยังเจ้าของโพสต์เดิม
        await _sendMatchNotification(
          userId: existingPost.userId,
          newPost: newPost,
          matchingPost: existingPost,
          matchScore: matchScore,
        );
        debugPrint('   ✓ Notified existing post owner: ${existingPost.userId}');

        // แจ้งเตือนไปยังเจ้าของโพสต์ใหม่ด้วย
        await _sendMatchNotification(
          userId: newPost.userId,
          newPost: existingPost,
          matchingPost: newPost,
          matchScore: matchScore,
        );
        debugPrint('   ✓ Notified new post owner: ${newPost.userId}');

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

      debugPrint('✅ Saved match record: ${(matchScore * 100).round()}%');
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

      // คำนวณ match score
      double bestMatchScore = 0.0;
      Post? bestMatchPost;

      for (var userPost in profile.userPosts) {
        double score = _calculatePostSimilarity(userPost, newPost);
        if (score > bestMatchScore) {
          bestMatchScore = score;
          bestMatchPost = userPost;
        }
      }

      // ส่ง notification หากคะแนนสูงกว่า threshold (เกณฑ์ 60%)
      if (bestMatchScore >= 0.6 && bestMatchPost != null) {
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
              .limit(50) // จำกัดจำนวนเพื่อประสิทธิภาพ
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

  /// คำนวณความคล้ายคลึงระหว่างโพสต์
  static double _calculatePostSimilarity(Post userPost, Post newPost) {
    double score = 0.0;

    // 1. ประเภทตรงข้าม (Lost vs Found) - 40%
    if (userPost.isLostItem != newPost.isLostItem) {
      score += 0.4;
    }

    // 2. หมวดหมู่เดียวกัน - 10%
    if (userPost.category == newPost.category) {
      score += 0.1;
    }

    // 3. อาคารเดียวกัน - 10%
    if (userPost.building == newPost.building) {
      score += 0.1;
    }

    // 4. ความคล้ายคลึงของคำ - 20%
    double textSimilarity = _calculateTextSimilarity(
      '${userPost.title} ${userPost.description}',
      '${newPost.title} ${newPost.description}',
    );
    score += textSimilarity * 0.2;

    return score;
  }

  /// คำนวณความคล้ายคลึงของข้อความ
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
      (matchScore * 100).round();

      // กำหนดข้อความตามประเภทของการแมช

      if (newPost.isLostItem && !matchingPost.isLostItem) {
        // โพสต์ใหม่ = หาของ, โพสต์เดิม = พบของ
      } else if (!newPost.isLostItem && matchingPost.isLostItem) {
        // โพสต์ใหม่ = พบของ, โพสต์เดิม = หาของ
      } else {
        // กรณีอื่นๆ (ไม่น่าจะเกิดขึ้น)
      }

      // สร้างเหตุผลการจับคู่เพื่อช่วยผู้ใช้เข้าใจ
      final reasons = _getPostMatchReasons(matchingPost, newPost);

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
  static List<String> _getPostMatchReasons(Post userPost, Post otherPost) {
    final List<String> reasons = [];

    if (userPost.isLostItem != otherPost.isLostItem) {
      reasons.add('ประเภทตรงข้าม (หาของ/เจอของ)');
    }
    if (userPost.category == otherPost.category) {
      reasons.add('หมวดหมู่เดียวกัน');
    }
    if (userPost.building == otherPost.building &&
        userPost.building.isNotEmpty) {
      reasons.add('อาคารเดียวกัน: อาคาร ${otherPost.building}');
    }

    final textSim = _calculateTextSimilarity(
      '${userPost.title} ${userPost.description}',
      '${otherPost.title} ${otherPost.description}',
    );
    if (textSim >= 0.3) {
      reasons.add('ข้อความคล้ายกัน');
    }

    return reasons;
  }

  /// อัพเดท user activity (เรียกเมื่อเปิดแอพ)
  static Future<void> updateUserActivity(String userId) async {
    try {
      await _firestore.collection('user_activity').doc(userId).set({
        'userId': userId,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ Error updating user activity: $e');
    }
  }

  /// ล้าง cache (เรียกเมื่อจำเป็น)
  static void clearCache() {
    _userProfileCache.clear();
  }

  /// Background processing สำหรับโพสต์ที่ยังไม่ได้ประมวลผล
  /// (สามารถเรียกด้วย Timer หรือ Firebase Functions)
  static Future<void> processQueuedMatches() async {
    try {
      final unprocessedPosts =
          await _firestore
              .collection('post_matching_queue')
              .where('processed', isEqualTo: false)
              .orderBy('createdAt')
              .limit(10)
              .get();

      for (var doc in unprocessedPosts.docs) {
        final data = doc.data();

        // ประมวลผลแบบ comprehensive
        await _processComprehensiveMatching(data);

        // มาร์คว่าประมวลผลแล้ว
        await doc.reference.update({'processed': true});
      }
    } catch (e) {
      debugPrint('❌ Error in processQueuedMatches: $e');
    }
  }

  /// ประมวลผลแบบครอบคลุม (สำหรับ background)
  static Future<void> _processComprehensiveMatching(
    Map<String, dynamic> postData,
  ) async {
    // TODO: ใช้สำหรับ background processing
    // สามารถใช้ ML หรือ advanced algorithms ได้
    debugPrint(
      '🔄 Processing comprehensive matching for ${postData['postTitle']}',
    );
  }
}

/// Model สำหรับเก็บข้อมูล user matching profile
class UserMatchingProfile {
  final String userId;
  final List<Post> userPosts;
  final DateTime lastUpdated;

  UserMatchingProfile({
    required this.userId,
    required this.userPosts,
    required this.lastUpdated,
  });

  // ตรวจสอบว่า cache หมดอายุหรือยัง (30 นาที)
  bool get isExpired {
    return DateTime.now().difference(lastUpdated).inMinutes > 30;
  }
}
