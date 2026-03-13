import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project01/models/post.dart';
import 'package:project01/services/notifications_service.dart';
import 'package:project01/utils/category_utils.dart';
import 'dart:async';

class RealtimeNotificationService {
  static StreamSubscription<QuerySnapshot>? _subscription;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Set<String> _processedPostIds = {};
  static DateTime? _lastCheckTime;

  /// เริ่มฟังการเปลี่ยนแปลงของโพสต์ใหม่
  static Future<void> startListening(BuildContext context) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      debugPrint('❌ No current user ID found');
      return;
    }

    debugPrint('🔔 Starting notification listener for user: $currentUserId');

    await stopListening();
    _processedPostIds.clear();

    try {
      // 🆕 1. เช็คโพสต์เก่าทั้งหมดก่อน (Initial Check)
      await _performInitialCheck(context, currentUserId);

      // 🆕 2. ตั้งค่า listener สำหรับโพสต์ใหม่ (ไม่จำกัด time window)
      _lastCheckTime = DateTime.now();

      _subscription = _firestore
          .collection('lost_found_items')
          .where('userId', isNotEqualTo: currentUserId)
          .where('status', isEqualTo: 'active')
          .orderBy('userId')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
            (snapshot) async {
              debugPrint('📦 Received ${snapshot.docChanges.length} changes');

              for (var change in snapshot.docChanges) {
                if (change.type == DocumentChangeType.added) {
                  final docId = change.doc.id;

                  // ป้องกันการประมวลผลซ้ำ
                  if (_processedPostIds.contains(docId)) {
                    debugPrint('⏭️ Already processed: $docId');
                    continue;
                  }

                  try {
                    final data = change.doc.data()!;
                    final createdAt =
                        (data['createdAt'] as Timestamp?)?.toDate();

                    // เช็คว่าเป็นโพสต์ที่สร้างหลังจาก listener เริ่มหรือไม่
                    if (createdAt != null && _lastCheckTime != null) {
                      if (createdAt.isBefore(_lastCheckTime!)) {
                        debugPrint('⏭️ Old post, skipping: $docId');
                        _processedPostIds.add(docId);
                        continue;
                      }
                    }

                    final newPost = Post.fromJson({...data, 'id': docId});
                    debugPrint('✨ New post: ${newPost.title} (ID: $docId)');

                    _processedPostIds.add(docId);
                    await _checkAndNotify(context, newPost, currentUserId);
                  } catch (e) {
                    debugPrint('❌ Error parsing post $docId: $e');
                  }
                }
              }
            },
            onError: (error) {
              debugPrint("❌ Realtime Notification Error: $error");
            },
          );

      debugPrint('✅ Notification listener started successfully');
    } catch (e) {
      debugPrint('❌ Error starting listener: $e');
    }
  }

  /// 🆕 เช็คโพสต์เก่าทั้งหมดในระบบกับโพสต์ของ user
  static Future<void> _performInitialCheck(
    BuildContext context,
    String userId,
  ) async {
    debugPrint('🔍 Performing initial check for existing posts...');

    try {
      // 1. ดึงโพสต์ทั้งหมดของ user
      final userPosts = await _getUserPosts(userId);
      if (userPosts.isEmpty) {
        debugPrint('⏭️ User has no posts to check');
        return;
      }

      debugPrint('📝 User has ${userPosts.length} posts');

      // 2. ดึงโพสต์ทั้งหมดของคนอื่นในระบบ
      final otherPostsSnapshot =
          await _firestore
              .collection('lost_found_items')
              .where('userId', isNotEqualTo: userId)
              .where('status', isEqualTo: 'active')
              .orderBy('userId')
              .orderBy('createdAt', descending: true)
              .limit(100) // จำกัดเพื่อไม่ให้โหลดหนักเกิน
              .get();

      debugPrint('📦 Found ${otherPostsSnapshot.docs.length} other posts');

      // 3. เช็คแต่ละโพสต์ของ user กับโพสต์ทั้งหมด
      for (var userPost in userPosts) {
        double bestMatch = 0.0;
        Post? matchingPost;
        List<String> matchReasons = [];

        for (var doc in otherPostsSnapshot.docs) {
          try {
            final otherPost = Post.fromJson({...doc.data(), 'id': doc.id});

            // ข้ามถ้าเป็นโพสต์เดียวกัน
            if (otherPost.id == userPost.id) continue;

            final similarity = _calculatePostSimilarity(userPost, otherPost);

            if (similarity > bestMatch) {
              bestMatch = similarity;
              matchingPost = otherPost;
              matchReasons = _getPostMatchReasons(userPost, otherPost);
            }
          } catch (e) {
            debugPrint('❌ Error processing other post: $e');
          }
        }

        // บันทึกการแจ้งเตือนถ้าพบความคล้าย >= 60%
        if (bestMatch >= 0.6 && matchingPost != null) {
          debugPrint(
            '🎯 Initial match found: ${(bestMatch * 100).toStringAsFixed(1)}%',
          );

          // เช็คว่ามี notification นี้อยู่แล้วหรือไม่
          final existingNotif = await _checkExistingNotification(
            userId,
            matchingPost.id,
            userPost.id,
          );

          if (!existingNotif) {
            await _saveNotificationToFirestore(
              userId: userId,
              newPost: matchingPost,
              matchScore: bestMatch,
              matchReasons: matchReasons,
              relatedPost: userPost,
            );
            await _saveNotificationToFirestore(
              userId: matchingPost.userId, // แจ้งเขา (เจ้าของโพสต์ที่เราไปเจอ)
              newPost: userPost, // ส่งโพสต์ของเราไปให้เขาดู
              matchScore: bestMatch,
              matchReasons: matchReasons,
              relatedPost: matchingPost, // อ้างอิงโพสต์ของเขา
            );

            // แสดง snackbar ถ้า context ยังใช้งานได้
            if (context.mounted) {
              _showInAppNotification(context, matchingPost, bestMatch);
            }
          } else {
            debugPrint('⏭️ Notification already exists, skipping');
          }

          // เพิ่ม ID เข้า processed set
          _processedPostIds.add(matchingPost.id);
        }
      }

      debugPrint('✅ Initial check completed');
    } catch (e) {
      debugPrint('❌ Error in initial check: $e');
    }
  }

  /// 🆕 เช็คว่ามี notification ซ้ำหรือไม่
  static Future<bool> _checkExistingNotification(
    String userId,
    String postId,
    String relatedPostId,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .where('type', isEqualTo: 'smart_match')
              .where('postId', isEqualTo: postId)
              .where('relatedPostId', isEqualTo: relatedPostId)
              .limit(1)
              .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking existing notification: $e');
      return false;
    }
  }

  static Future<void> _checkAndNotify(
    BuildContext context,
    Post newPost,
    String userId,
  ) async {
    debugPrint('🔍 Checking matches for post: ${newPost.title}');

    List<Post> userPosts = await _getUserPosts(userId);
    debugPrint('📝 User has ${userPosts.length} posts to compare');

    if (userPosts.isEmpty) {
      debugPrint('⏭️ No user posts to compare');
      return;
    }

    double bestMatch = 0.0;
    Post? matchingUserPost;
    List<String> matchReasons = [];

    for (var userPost in userPosts) {
      if (userPost.id == newPost.id) continue;

      double similarity = _calculatePostSimilarity(userPost, newPost);
      debugPrint(
        '📊 Similarity with "${userPost.title}": ${(similarity * 100).toStringAsFixed(1)}%',
      );

      if (similarity > bestMatch) {
        bestMatch = similarity;
        matchingUserPost = userPost;
        matchReasons = _getPostMatchReasons(userPost, newPost);
      }
    }

    debugPrint('🎯 Best match: ${(bestMatch * 100).toStringAsFixed(1)}%');

    if (bestMatch >= 0.6 && matchingUserPost != null) {
      debugPrint('✅ Match found! Sending notification...');

      // เช็คว่ามี notification ซ้ำหรือไม่
      final exists = await _checkExistingNotification(
        userId,
        newPost.id,
        matchingUserPost.id,
      );

      if (!exists) {
        await _saveNotificationToFirestore(
          userId: userId,
          newPost: newPost,
          matchScore: bestMatch,
          matchReasons: matchReasons,
          relatedPost: matchingUserPost,
        );

        if (context.mounted) {
          _showInAppNotification(context, newPost, bestMatch);
        }
      } else {
        debugPrint('⏭️ Notification already exists');
      }
    } else {
      debugPrint('⏭️ No sufficient match (threshold: 60%)');
    }
  }

  static Future<void> _saveNotificationToFirestore({
    required String userId,
    required Post newPost,
    required Post relatedPost,
    required double matchScore,
    required List<String> matchReasons,
  }) async {
    try {
      await NotificationService.createSmartMatchNotification(
        targetUserId: userId,
        matchedPost: newPost,
        relatedPost: relatedPost,
        matchScore: matchScore,
        matchReasons: matchReasons,
      );
      debugPrint('💾 Notification saved to Firestore');
    } catch (e) {
      debugPrint('❌ Error saving notification: $e');
    }
  }

  static void _showInAppNotification(
    BuildContext context,
    Post post,
    double matchScore,
  ) {
    final matchPercentage = (matchScore * 100).round();
    debugPrint('📱 Showing notification: $matchPercentage% match');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              post.isLostItem ? Icons.search : Icons.find_in_page,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'พบของที่ตรงกับคุณ $matchPercentage%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    post.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: matchScore >= 0.7 ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'ดู',
          textColor: Colors.white,
          onPressed: () {
            Navigator.pushNamed(context, '/smart-notifications');
          },
        ),
      ),
    );
  }

  static Future<List<Post>> _getUserPosts(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('lost_found_items')
              .where('userId', isEqualTo: userId)
              .where('status', isEqualTo: 'active')
              .orderBy('createdAt', descending: true)
              .get();

      final posts =
          snapshot.docs
              .map((doc) => Post.fromJson({...doc.data(), 'id': doc.id}))
              .toList();

      debugPrint('📚 Retrieved ${posts.length} user posts');
      return posts;
    } catch (e) {
      debugPrint('❌ Error getting user posts: $e');
      return [];
    }
  }

  static double _calculatePostSimilarity(Post userPost, Post otherPost) {
    double score = 0.0;

    // ประเภทตรงข้าม (Lost vs Found) - 35%
    if (userPost.isLostItem != otherPost.isLostItem) {
      score += 0.35;
    }

    // หมวดหมู่เดียวกัน - 20%
    if (userPost.category == otherPost.category) {
      score += 0.20;
    }

    // อาคารเดียวกัน - 15%
    if (userPost.building == otherPost.building) {
      score += 0.15;
    }

    // สถานที่ - 15%
    if (userPost.location.isNotEmpty && otherPost.location.isNotEmpty) {
      if (userPost.location.toLowerCase() == otherPost.location.toLowerCase()) {
        score += 0.15;
      } else {
        double locationSimilarity = _calculateTextSimilarity(
          userPost.location,
          otherPost.location,
        );
        score += locationSimilarity * 0.10;
      }
    }

    // ชื่อเรื่อง - 10%
    double titleSimilarity = _calculateTextSimilarity(
      userPost.title,
      otherPost.title,
    );
    score += titleSimilarity * 0.10;

    // คำอธิบาย - 5%
    double descSimilarity = _calculateTextSimilarity(
      userPost.description,
      otherPost.description,
    );
    score += descSimilarity * 0.05;

    return score;
  }

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

  static List<String> _extractKeywords(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'[\s,.-]+'))
        .where((word) => word.length > 2)
        .toList();
  }

  static String _getCategoryName(String categoryId) {
    return CategoryUtils.getCategoryName(categoryId);
  }

  static List<String> _getPostMatchReasons(Post userPost, Post otherPost) {
    List<String> reasons = [];

    if (userPost.isLostItem != otherPost.isLostItem) {
      String userType = userPost.isLostItem ? 'หาของ' : 'เจอของ';
      String otherType = otherPost.isLostItem ? 'หาของ' : 'เจอของ';
      reasons.add('คุณเคย$userType และมีคนอื่น$otherType');
    }

    if (userPost.category == otherPost.category) {
      reasons.add('หมวดหมู่เดียวกัน: ${_getCategoryName(otherPost.category)}');
    }

    if (userPost.building == otherPost.building) {
      reasons.add('อาคารเดียวกัน: ${otherPost.building}');
    }

    if (userPost.location.isNotEmpty && otherPost.location.isNotEmpty) {
      if (userPost.location.toLowerCase() == otherPost.location.toLowerCase()) {
        reasons.add('สถานที่เดียวกัน: ${otherPost.location}');
      }
    }

    return reasons;
  }

  static Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
    _lastCheckTime = null;
    debugPrint('🛑 Notification listener stopped');
  }

  static void clearProcessedIds() {
    _processedPostIds.clear();
    _lastCheckTime = null;
    debugPrint('🧹 Cleared processed post IDs');
  }

  /// 🆕 Manual refresh - เรียกเมื่อต้องการเช็คโพสต์ใหม่อีกครั้ง
  static Future<void> refreshCheck(BuildContext context) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    debugPrint('🔄 Manual refresh check...');
    await _performInitialCheck(context, currentUserId);
  }
}
