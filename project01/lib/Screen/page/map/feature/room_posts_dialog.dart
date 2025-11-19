import 'package:flutter/material.dart';
import 'package:project01/models/post.dart';
import 'package:project01/models/post_detail_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomPostsDialog extends StatelessWidget {
  final String roomName;
  final String buildingName;
  final List<Post> posts;

  const RoomPostsDialog({
    super.key,
    required this.roomName,
    required this.buildingName,
    required this.posts,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    // ---- ใช้ responsive constraints แบบเดิมของคุณ ----
    final BoxConstraints constraints = BoxConstraints(
      maxWidth: 600,
      maxHeight:
          isLargeScreen
              ? screenWidth * 0.7
              : MediaQuery.of(context).size.height * 0.6,
    );

    // ---- เนื้อหาหลักของ dialog ----
    Widget contentContainer = Container(
      constraints: constraints,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.room,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        roomName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      Text(
                        buildingName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ],
            ),
          ),

          // ส่วนล่าง (โพสต์)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onPrimary,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child:
                  posts.isEmpty
                      ? _buildEmptyState(context)
                      : _buildPostsList(context),
            ),
          ),
        ],
      ),
    );

    // ---- Dialog responsive สำหรับจอใหญ่ ----
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.transparent,
      child:
          isLargeScreen
              ? FractionallySizedBox(
                widthFactor: 0.6, // 60% ของหน้าจอ — ดูโปรสุดบน Desktop
                child: contentContainer,
              )
              : contentContainer,
    );
  }

  // ---------- Empty State ----------
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'ไม่มีรายการของหาย/เจอของ',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ในอาคาร $roomName',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Posts List ----------
  Widget _buildPostsList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Card(
          color: Theme.of(context).colorScheme.onPrimary,
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showPostDetail(context, post),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon สถานะ
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                          post.isLostItem
                              ? Theme.of(
                                context,
                              ).colorScheme.error.withOpacity(0.15)
                              : Theme.of(
                                context,
                              ).colorScheme.secondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      post.isLostItem
                          ? Icons.help_outline
                          : Icons.check_circle_outline,
                      color:
                          post.isLostItem
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.secondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // เนื้อหาโพสต์
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          post.description,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.surface.withOpacity(0.5),
                            ),
                            const SizedBox(width: 4),
                            _posterNameWidget(context, post),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.surface.withOpacity(0.5),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                post.getTimeAgo(),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surface.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ลูกศรทางขวา
                  SizedBox(
                    width: 28,
                    child: Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPostDetail(BuildContext context, Post post) {
    Navigator.of(context).pop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => PostDetailSheet(post: post),
    );
  }

  // ---------- ชื่อผู้โพสต์ ----------
  static final Map<String, String> _userNameCache = {};

  Widget _posterNameWidget(BuildContext context, Post post) {
    final raw = post.userName.trim();
    final textStyle = TextStyle(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    if (raw.isNotEmpty) {
      return Flexible(
        child: Text(raw, overflow: TextOverflow.ellipsis, style: textStyle),
      );
    }

    final uid = post.userId;
    if (uid.isNotEmpty && _userNameCache.containsKey(uid)) {
      return Flexible(
        child: Text(
          _userNameCache[uid]!,
          overflow: TextOverflow.ellipsis,
          style: textStyle,
        ),
      );
    }

    if (uid.isEmpty) {
      return Text('ไม่ระบุผู้โพสต์', style: textStyle);
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text('กำลังโหลด...', style: textStyle);
        }
        try {
          final data = snapshot.data?.data();
          final name =
              (data?['name'] ?? data?['displayName'] ?? data?['fullName'] ?? '')
                  .toString()
                  .trim();
          final result = name.isNotEmpty ? name : 'ไม่ระบุผู้โพสต์';
          _userNameCache[uid] = result;
          return Flexible(
            child: Text(
              result,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          );
        } catch (_) {
          return Text('ไม่ระบุผู้โพสต์', style: textStyle);
        }
      },
    );
  }
}
