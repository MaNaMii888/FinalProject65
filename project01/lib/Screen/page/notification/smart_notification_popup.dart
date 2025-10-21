import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project01/models/post.dart';

class SmartNotificationPopup extends StatefulWidget {
  const SmartNotificationPopup({super.key});

  @override
  State<SmartNotificationPopup> createState() => _SmartNotificationPopupState();
}

class _SmartNotificationPopupState extends State<SmartNotificationPopup> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  List<SmartNotificationItem> smartNotifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSmartNotifications();
  }

  Future<void> _loadSmartNotifications() async {
    if (currentUserId == null) return;

    setState(() => isLoading = true);

    try {
      // 1. ดึงข้อมูลโพสต์ที่ผู้ใช้เคยโพสต์
      final userPosts = await _getUserPosts();

      // 2. ดึงโพสต์ล่าสุดของคนอื่น
      final otherPosts = await _getOtherPosts();

      // 3. วิเคราะห์และสร้าง notification สำหรับความใกล้เคียง
      final notifications = await _generateMatchNotifications(
        userPosts,
        otherPosts,
      );

      setState(() {
        smartNotifications = notifications;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading smart notifications: $e');
      setState(() => isLoading = false);
    }
  }

  Future<List<Post>> _getUserPosts() async {
    try {
      final userPostsSnapshot =
          await FirebaseFirestore.instance
              .collection('lost_found_items')
              .where('userId', isEqualTo: currentUserId)
              .orderBy('createdAt', descending: true)
              .get();

      return userPostsSnapshot.docs
          .map((doc) => Post.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting user posts: $e');
      return [];
    }
  }

  Future<List<Post>> _getOtherPosts() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('lost_found_items')
              .where('userId', isNotEqualTo: currentUserId)
              .orderBy('userId')
              .orderBy('createdAt', descending: true)
              .limit(100)
              .get();

      return snapshot.docs
          .map((doc) => Post.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting other posts: $e');
      return [];
    }
  }

  Future<List<SmartNotificationItem>> _generateMatchNotifications(
    List<Post> userPosts,
    List<Post> otherPosts,
  ) async {
    List<SmartNotificationItem> notifications = [];

    for (var otherPost in otherPosts) {
      double bestMatch = 0.0;
      Post? matchingUserPost;
      List<String> matchReasons = [];

      for (var userPost in userPosts) {
        double similarity = _calculatePostSimilarity(userPost, otherPost);
        if (similarity > bestMatch) {
          bestMatch = similarity;
          matchingUserPost = userPost;
          matchReasons = _getPostMatchReasons(userPost, otherPost);
        }
      }

      if (bestMatch > 0.7 && matchingUserPost != null) {
        notifications.add(
          SmartNotificationItem(
            post: otherPost,
            matchScore: bestMatch,
            matchReasons: matchReasons,
            createdAt: DateTime.now(),
            relatedUserPost: matchingUserPost,
          ),
        );
      }
    }

    notifications.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    return notifications.take(10).toList();
  }

  double _calculatePostSimilarity(Post userPost, Post otherPost) {
    double score = 0.0;

    if (userPost.isLostItem != otherPost.isLostItem) {
      score += 0.4;
    }

    if (userPost.category == otherPost.category) {
      score += 0.25;
    }

    if (userPost.building == otherPost.building) {
      score += 0.2;
    }

    double titleSimilarity = _calculateTextSimilarity(
      userPost.title,
      otherPost.title,
    );
    score += titleSimilarity * 0.1;

    double descSimilarity = _calculateTextSimilarity(
      userPost.description,
      otherPost.description,
    );
    score += descSimilarity * 0.05;

    return score;
  }

  double _calculateTextSimilarity(String text1, String text2) {
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

  List<String> _extractKeywords(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'[\s,.-]+'))
        .where((word) => word.length > 2)
        .toList();
  }

  List<String> _getPostMatchReasons(Post userPost, Post otherPost) {
    List<String> reasons = [];

    if (userPost.isLostItem != otherPost.isLostItem) {
      String userType = userPost.isLostItem ? 'หาของ' : 'เจอของ';
      String otherType = otherPost.isLostItem ? 'หาของ' : 'เจอของ';
      reasons.add('คุณเคย$userType และมีคนอื่น$otherType');
    }

    if (userPost.category == otherPost.category) {
      reasons.add('หมวดหมู่เดียวกัน: ${otherPost.category}');
    }

    if (userPost.building == otherPost.building) {
      reasons.add('อาคารเดียวกัน: อาคาร ${otherPost.building}');
    }

    List<String> userWords = _extractKeywords(
      '${userPost.title} ${userPost.description}',
    );
    List<String> otherWords = _extractKeywords(
      '${otherPost.title} ${otherPost.description}',
    );

    List<String> commonWords = [];
    for (String userWord in userWords) {
      for (String otherWord in otherWords) {
        if (userWord.toLowerCase() == otherWord.toLowerCase() &&
            !commonWords.contains(userWord)) {
          commonWords.add(userWord);
        }
      }
    }

    if (commonWords.isNotEmpty) {
      reasons.add('คำที่คล้ายกัน: ${commonWords.take(3).join(', ')}');
    }

    reasons.add('เกี่ยวข้องกับโพสต์ของคุณ: ${userPost.title}');

    return reasons;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85, // 85% ของหน้าจอ
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'การแจ้งเตือน',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Prompt',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: Colors.grey[300]),

          // Content
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : smartNotifications.isEmpty
                    ? _buildEmptyState()
                    : _buildNotificationList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'ยังไม่มีการแจ้งเตือนที่ตรงกับความสนใจของคุณ',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontFamily: 'Prompt',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'ระบบจะแจ้งเตือนเมื่อมีสิ่งของที่เข้าข่ายความสนใจของคุณ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontFamily: 'Prompt',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: smartNotifications.length,
      itemBuilder: (context, index) {
        final notification = smartNotifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(SmartNotificationItem notification) {
    final post = notification.post;
    final matchPercentage = (notification.matchScore * 100).round();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with match score
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getMatchColor(notification.matchScore),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$matchPercentage% ตรง',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    post.isLostItem ? 'มีคนหาของ' : 'มีคนเจอของ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Text(
                  'อาคาร ${post.building}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Post content
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color:
                        post.isLostItem ? Colors.red[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    post.isLostItem ? Icons.search : Icons.find_in_page,
                    color:
                        post.isLostItem ? Colors.red[600] : Colors.green[600],
                    size: 24,
                  ),
                ),

                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      Text(
                        post.description,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Match reasons
                      if (notification.matchReasons.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'เหตุผลที่แจ้งเตือน:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              ...notification.matchReasons.map(
                                (reason) => Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8,
                                    top: 2,
                                  ),
                                  child: Text(
                                    '• $reason',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // แสดงโพสต์ที่เกี่ยวข้องของผู้ใช้
                      if (notification.relatedUserPost != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'โพสต์ของคุณที่เกี่ยวข้อง:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification.relatedUserPost!.title,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _viewPostDetails(post);
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('ดูรายละเอียด'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _contactOwner(post);
                    },
                    icon: const Icon(Icons.message, size: 16),
                    label: const Text('ติดต่อ'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getMatchColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.7) return Colors.orange;
    return Colors.blue;
  }

  void _viewPostDetails(Post post) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(post.title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('รายละเอียด: ${post.description}'),
                const SizedBox(height: 8),
                Text('สถานที่: ${post.location}'),
                Text('อาคาร: ${post.building}'),
                Text('ประเภท: ${_getCategoryName(post.category)}'),
                Text('ติดต่อ: ${post.contact}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ปิด'),
              ),
            ],
          ),
    );
  }

  void _contactOwner(Post post) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('ติดต่อเจ้าของ'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ชื่อ: ${post.userName}'),
                const SizedBox(height: 8),
                Text('ติดต่อ: ${post.contact}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ปิด'),
              ),
            ],
          ),
    );
  }

  // ฟังก์ชันแปลงรหัสหมวดหมู่เป็นชื่อ
  String _getCategoryName(String categoryId) {
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
}

// Data models
class SmartNotificationItem {
  final Post post;
  final double matchScore;
  final List<String> matchReasons;
  final DateTime createdAt;
  final Post? relatedUserPost;

  SmartNotificationItem({
    required this.post,
    required this.matchScore,
    required this.matchReasons,
    required this.createdAt,
    this.relatedUserPost,
  });
}
