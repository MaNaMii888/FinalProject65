import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project01/models/post.dart';
import 'package:project01/models/post_detail_sheet.dart';
import 'package:project01/Screen/page/profile/widgets/edit_post_bottom_sheet.dart';
import 'package:project01/services/log_service.dart';
import 'package:project01/utils/time_formatter.dart';

class PostHistoryPage extends StatefulWidget {
  final String userId;
  final bool isLostItems; // true for lost items, false for found items
  final String title;

  const PostHistoryPage({
    super.key,
    required this.userId,
    required this.isLostItems,
    required this.title,
  });

  @override
  State<PostHistoryPage> createState() => _PostHistoryPageState();
}

class _PostHistoryPageState extends State<PostHistoryPage> {
  List<Post> posts = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  List<Post> _allPostsInMemory = [];
  int _currentOffset = 0;
  static const int pageSize = 15;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadData(isLoadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (!hasMore || isLoadingMore) return;
      setState(() {
        isLoadingMore = true;
      });
    } else {
      setState(() {
        isLoading = true;
        hasMore = true;
        posts.clear();
      });
    }

    try {
      if (!isLoadMore) {
        // โหลดข้อมูลทั้งหมดของ User คนนี้มาจากทั้ง 2 โกดัง (Active & Archived)
        final activeQuery =
            FirebaseFirestore.instance
                .collection('lost_found_items')
                .where('userId', isEqualTo: widget.userId)
                .where('isLostItem', isEqualTo: widget.isLostItems)
                .get();

        final archiveQuery =
            FirebaseFirestore.instance
                .collection('archived_items')
                .where('userId', isEqualTo: widget.userId)
                .where('isLostItem', isEqualTo: widget.isLostItems)
                .get();

        final results = await Future.wait([activeQuery, archiveQuery]);

        final List<Post> tempAllPosts = [];
        for (var snapshot in results) {
          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();
              tempAllPosts.add(Post.fromJson({...data, 'id': doc.id}));
            } catch (e) {
              print("Error parsing post: $e");
            }
          }
        }

        // เรียงลำดับจากใหม่สุดไปเก่าสุด
        tempAllPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _allPostsInMemory = tempAllPosts;
        _currentOffset = 0;
      }

      final List<Post> loaded = [];
      if (_currentOffset < _allPostsInMemory.length) {
        final end =
            (_currentOffset + pageSize < _allPostsInMemory.length)
                ? _currentOffset + pageSize
                : _allPostsInMemory.length;
        loaded.addAll(_allPostsInMemory.sublist(_currentOffset, end));
        _currentOffset = end;
      }

      setState(() {
        if (isLoadMore) {
          posts.addAll(loaded);
          isLoadingMore = false;
        } else {
          posts = loaded;
          isLoading = false;
        }
        hasMore = _currentOffset < _allPostsInMemory.length;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
      print('Error loading history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFFFFF),
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isLostItems
                        ? Icons.search_off
                        : Icons.check_circle_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isLostItems
                        ? 'ยังไม่มีประวัติของหาย'
                        : 'ยังไม่มีประวัติเจอของ',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _loadData(),
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: posts.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == posts.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final post = posts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => PostDetailSheet(post: post),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  post.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      post.status == 'resolved' ||
                                              post.status == 'closed'
                                          ? Colors.green[100]
                                          : Colors.orange[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  post.status == 'resolved' ||
                                          post.status == 'closed'
                                      ? 'เสร็จสิ้น'
                                      : 'กำลังดำเนินการ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        post.status == 'resolved' ||
                                                post.status == 'closed'
                                            ? Colors.green[700]
                                            : Colors.orange[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                              // แสดงชื่อผู้โพสต์และเวลาใต้หัวข้อ (เล็กและตัวหนาเล็กน้อย)
                              // จะอยู่ต่อจากส่วนสถานะในแถวนี้
                              // (สำหรับความชัดเจน เราแสดงชื่อผู้โพสต์ด้านล่างหัวข้อแทนที่จะแสดงในเมนู)

                              // Debug: ตรวจสอบค่า userId
                              // แสดงเมนูแก้ไข/ลบ เฉพาะโพสต์ของผู้ใช้คนนี้
                              Builder(
                                builder: (context) {
                                  // Debug prints
                                  print(
                                    'DEBUG: post.userId = "${post.userId}"',
                                  );
                                  print(
                                    'DEBUG: widget.userId = "${widget.userId}"',
                                  );
                                  print(
                                    'DEBUG: Are equal? ${post.userId == widget.userId}',
                                  );

                                  // แสดงปุ่มเสมอเพื่อทดสอบ (ชั่วคราว)
                                  return PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        // เปิดหน้าแก้ไขโพสต์
                                        await _editPost(post);
                                      } else if (value == 'delete') {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder:
                                              (context) => AlertDialog(
                                                title: const Text(
                                                  'ยืนยันการลบ',
                                                ),
                                                content: Text(
                                                  'คุณต้องการลบโพสต์นี้หรือไม่?\npost.userId: ${post.userId}\nwidget.userId: ${widget.userId}',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                          false,
                                                        ),
                                                    child: const Text('ยกเลิก'),
                                                  ),
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                          true,
                                                        ),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          Colors.red,
                                                    ),
                                                    child: const Text('ลบ'),
                                                  ),
                                                ],
                                              ),
                                        );

                                        if (confirm == true) {
                                          try {
                                            await FirebaseFirestore.instance
                                                .collection('lost_found_items')
                                                .doc(post.id)
                                                .delete();

                                            // บันทึก log การลบโพสต์
                                            final currentUser =
                                                FirebaseAuth
                                                    .instance
                                                    .currentUser;
                                            if (currentUser != null) {
                                              await LogService().logPostDelete(
                                                userId: currentUser.uid,
                                                userName:
                                                    currentUser.email?.split(
                                                      '@',
                                                    )[0] ??
                                                    'Unknown',
                                                postId: post.id,
                                                postTitle: post.title,
                                              );
                                            }

                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'ลบโพสต์เรียบร้อย',
                                                ),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'ไม่สามารถลบโพสต์ได้: $e',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    },
                                    itemBuilder:
                                        (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.edit,
                                                  color: Colors.black,
                                                ),
                                                SizedBox(width: 8),
                                                Text('แก้ไข'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                SizedBox(width: 8),
                                                Text('ลบโพสต์'),
                                              ],
                                            ),
                                          ),
                                        ],
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // แสดงชื่อผู้โพสต์และเวลา
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  post.userName.trim().isEmpty
                                      ? 'ไม่ระบุผู้โพสต์'
                                      : post.userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                post.getTimeAgo(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          if (post.description.isNotEmpty) ...[
                            Text(
                              post.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (post.imageUrl.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                post.imageUrl,
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 120,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.error),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  post.location,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.category,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getCategoryText(post.category),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const Spacer(),
                              Text(
                                TimeFormatter.getTimeAgo(post.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ฟังก์ชันแก้ไขโพสต์
  Future<void> _editPost(Post post) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditPostBottomSheet(post: post),
    );
  }

  String _getCategoryText(String category) {
    switch (category) {
      case '1':
        return 'ของใช้ส่วนตัว';
      case '2':
        return 'เอกสาร/บัตร';
      case '3':
        return 'อุปกรณ์การเรียน';
      case '4':
        return 'ของมีค่าอื่นๆ';
      default:
        return 'ไม่ระบุ';
    }
  }
}
