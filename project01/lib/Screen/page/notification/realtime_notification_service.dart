import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project01/models/post.dart';
import 'dart:async';

class RealtimeNotificationService {
  static StreamSubscription<QuerySnapshot>? _subscription;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // เริ่มฟังการเปลี่ยนแปลงของโพสต์ใหม่
  static Future<void> startListening(BuildContext context) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    // ดึงโพสต์ของผู้ใช้ปัจจุบัน
    final userPosts = await _getUserPosts(currentUserId);
    if (userPosts.isEmpty) return;

    // ฟังโพสต์ใหม่ที่ถูกสร้างหลังจากตอนนี้
    _subscription = _firestore
        .collection('lost_found_items')
        .where('userId', isNotEqualTo: currentUserId)
        .where('createdAt', isGreaterThan: DateTime.now())
        .snapshots()
        .listen((snapshot) async {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final newPost = Post.fromJson({
                ...change.doc.data()!,
                'id': change.doc.id,
              });

              // ตรวจสอบความคล้ายกัน
              await _checkAndNotify(context, newPost, userPosts, currentUserId);
            }
          }
        });
  }

  static Future<void> _checkAndNotify(
    BuildContext context,
    Post newPost,
    List<Post> userPosts,
    String userId,
  ) async {
    double bestMatch = 0.0;
    Post? matchingUserPost;
    List<String> matchReasons = [];

    for (var userPost in userPosts) {
      double similarity = _calculatePostSimilarity(userPost, newPost);
      if (similarity > bestMatch) {
        bestMatch = similarity;
        matchingUserPost = userPost;
        matchReasons = _getPostMatchReasons(userPost, newPost);
      }
    }

    // ถ้าพบความคล้ายกันมากกว่า 70% แจ้งเตือน
    if (bestMatch >= 0.7 && matchingUserPost != null) {
      // บันทึกการแจ้งเตือนลง Firestore
      await _saveNotificationToFirestore(
        userId: userId,
        newPost: newPost,
        matchScore: bestMatch,
        matchReasons: matchReasons,
        relatedPostId: matchingUserPost.id,
      );

      // แสดง Snackbar แจ้งเตือน
      if (context.mounted) {
        _showInAppNotification(context, newPost, bestMatch);
      }
    }
  }

  static Future<void> _saveNotificationToFirestore({
    required String userId,
    required Post newPost,
    required double matchScore,
    required List<String> matchReasons,
    required String relatedPostId,
  }) async {
    try {
      await _firestore.collection('smart_notifications').add({
        'userId': userId,
        'postId': newPost.id,
        'postTitle': newPost.title,
        'postType': newPost.isLostItem ? 'lost' : 'found',
        'matchScore': matchScore,
        'matchReasons': matchReasons,
        'relatedPostId': relatedPostId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving notification: $e');
    }
  }

  static void _showInAppNotification(
    BuildContext context,
    Post post,
    double matchScore,
  ) {
    final matchPercentage = (matchScore * 100).round();

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
            // Navigate to notification screen
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
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => Post.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting user posts: $e');
      return [];
    }
  }

  // ฟังก์ชันคำนวณความคล้าย (คัดลอกมาจาก smart_notification_screen.dart)
  static double _calculatePostSimilarity(Post userPost, Post otherPost) {
    double score = 0.0;

    if (userPost.isLostItem != otherPost.isLostItem) {
      score += 0.35;
    }

    if (userPost.category == otherPost.category) {
      score += 0.20;
    }

    if (userPost.building == otherPost.building) {
      score += 0.15;
    }

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

    double titleSimilarity = _calculateTextSimilarity(
      userPost.title,
      otherPost.title,
    );
    score += titleSimilarity * 0.10;

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
    switch (categoryId) {
      case '1': return 'ของใช้ส่วนตัว';
      case '2': return 'เอกสาร/บัตร';
      case '3': return 'อุปกรณ์การเรียน';
      case '4': return 'ของมีค่าอื่นๆ';
      default: return categoryId.isEmpty ? 'ไม่ระบุ' : categoryId;
    }
}
  static List<String> _getPostMatchReasons(Post userPost, Post otherPost) {
    List<String> reasons = [];

    if (userPost.isLostItem != otherPost.isLostItem) {
      String userType = userPost.isLostItem ? 'หาของ' : 'เจอของ';
      String otherType = otherPost.isLostItem ? 'หาของ' : 'เจอของ';
      reasons.add('คุณเคย$userType และมีคนอื่น$otherType');
    }

    if (userPost.category == otherPost.category) {
      reasons.add('หมวดหมู่เดียวกัน');
    }

    if (userPost.building == otherPost.building) {
      reasons.add('อาคารเดียวกัน: อาคาร ${otherPost.building}');
    }

    if (userPost.location.isNotEmpty && otherPost.location.isNotEmpty) {
      if (userPost.location.toLowerCase() == otherPost.location.toLowerCase()) {
        reasons.add('สถานที่เดียวกัน: ${otherPost.location}');
      }
    }
    if (userPost.category == otherPost.category) {
      reasons.add('หมวดหมู่เดียวกัน: ${_getCategoryName(otherPost.category)}'); 
    }

    return reasons;
  }

  // หยุดฟัง
  static void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }
}
