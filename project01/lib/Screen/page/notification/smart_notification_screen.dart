import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:project01/models/post.dart';

class SmartNotificationScreen extends StatefulWidget {
  const SmartNotificationScreen({super.key});

  @override
  State<SmartNotificationScreen> createState() =>
      _SmartNotificationScreenState();
}

class _SmartNotificationScreenState extends State<SmartNotificationScreen> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  List<SmartNotificationItem> smartNotifications = [];
  bool isLoading = true;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  @override
  void initState() {
    super.initState();
    _setupRealtimeNotifications();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeNotifications() {
    if (currentUserId == null) {
      debugPrint('SmartNotification: currentUserId is null');
      setState(() => isLoading = false);
      return;
    }

    try {
      _subscription = FirebaseFirestore.instance
          .collection('smart_notifications')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .listen(
            (snapshot) async {
              if (snapshot.docs.isEmpty) {
                if (mounted) {
                  setState(() {
                    smartNotifications = [];
                    isLoading = false;
                  });
                }
                return;
              }

              final List<SmartNotificationItem> temp = [];

              for (final doc in snapshot.docs) {
                final data = doc.data();
                try {
                  final postDoc =
                      await FirebaseFirestore.instance
                          .collection('lost_found_items')
                          .doc(data['postId'])
                          .get();

                  if (!postDoc.exists) continue;

                  final post = Post.fromJson({
                    ...postDoc.data()!,
                    'id': postDoc.id,
                  });

                  Post? related;
                  if (data['relatedPostId'] != null) {
                    final relatedDoc =
                        await FirebaseFirestore.instance
                            .collection('lost_found_items')
                            .doc(data['relatedPostId'])
                            .get();
                    if (relatedDoc.exists) {
                      related = Post.fromJson({
                        ...relatedDoc.data()!,
                        'id': relatedDoc.id,
                      });
                    }
                  }

                  temp.add(
                    SmartNotificationItem(
                      post: post,
                      matchScore:
                          (data['matchScore'] as num?)?.toDouble() ?? 0.0,
                      matchReasons: List<String>.from(
                        data['matchReasons'] ?? [],
                      ),
                      createdAt:
                          (data['createdAt'] as Timestamp?)?.toDate() ??
                          DateTime.now(),
                      relatedUserPost: related,
                      notificationId: doc.id,
                      isRead: data['isRead'] ?? false,
                    ),
                  );
                } catch (e) {
                  debugPrint('Error processing smart notification doc: $e');
                }
              }

              if (mounted) {
                setState(() {
                  smartNotifications = temp;
                  isLoading = false;
                });
              }
            },
            onError: (error) {
              debugPrint('Firestore listen error: $error');
              if (mounted) setState(() => isLoading = false);
            },
          );
    } catch (e) {
      debugPrint('Error setting up smart notification listener: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _removeNotification(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('smart_notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('Error removing notification $notificationId: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final topPadding = (statusBarHeight * 0.3).clamp(8.0, 20.0);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          SizedBox(height: topPadding),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.notifications_active,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'แจ้งเตือน',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'ไม่มีรายการแจ้งเตือน',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: smartNotifications.length,
      itemBuilder:
          (context, index) => _buildNotificationCard(smartNotifications[index]),
    );
  }

  Widget _buildNotificationCard(SmartNotificationItem notification) {
    final post = notification.post;
    final matchPercentage = (notification.matchScore * 100).round();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'พบความตรงกัน (${matchPercentage}%): ${post.title}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      if (notification.notificationId != null) {
                        setState(() => smartNotifications.remove(notification));
                        _removeNotification(notification.notificationId!);
                      }
                    },
                    child: const Text('ไม่ใช่'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _contactOwner(post),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('ใช่ (ติดต่อ)'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // (Optional) view details helper removed — not currently used

  void _contactOwner(Post post) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('ติดต่อเจ้าของ'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text('ชื่อ: '),
                    Text(
                      post.userName.trim().isEmpty
                          ? 'ไม่ระบุผู้โพสต์'
                          : post.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(children: [const Text('ติดต่อ: '), Text(post.contact)]),
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

  // helper functions removed if unused
}

class SmartNotificationItem {
  final Post post;
  final double matchScore;
  final List<String> matchReasons;
  final DateTime createdAt;
  final Post? relatedUserPost;
  final String? notificationId;
  final bool isRead;

  SmartNotificationItem({
    required this.post,
    required this.matchScore,
    required this.matchReasons,
    required this.createdAt,
    this.relatedUserPost,
    this.notificationId,
    this.isRead = false,
  });
}
