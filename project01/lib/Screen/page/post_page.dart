import 'package:flutter/material.dart';
import 'package:project01/Screen/action/find_item_action.dart';
import 'package:project01/Screen/action/post_actions_buttons.dart';
import 'package:project01/models/post.dart';
import 'package:project01/models/post_detail_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Post> posts = [];
  bool isLoading = true;
  String searchQuery = '';
  String? selectedCategory;
  static const int pageSize = 10;
  DocumentSnapshot? lastDocument;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('lost_found_items')
          .orderBy('createdAt', descending: true)
          .limit(pageSize)
          .get()
          .timeout(const Duration(seconds: 10));

      if (snapshot.docs.isNotEmpty) {
        lastDocument = snapshot.docs.last;
      }

      if (!mounted) return;
      setState(() {
        posts =
            snapshot.docs
                .map((doc) => Post.fromJson({...doc.data(), 'id': doc.id}))
                .toList();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showError('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e');
    }
  }

  Future<void> _loadMorePosts() async {
    if (!hasMore || isLoading) return;

    setState(() => isLoading = true);
    try {
      var query = FirebaseFirestore.instance
          .collection('lost_found_items')
          .orderBy('createdAt', descending: true)
          .limit(pageSize);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.length < pageSize) {
        hasMore = false;
      }

      if (snapshot.docs.isNotEmpty) {
        lastDocument = snapshot.docs.last;
      }

      setState(() {
        posts.addAll(
          snapshot.docs.map(
            (doc) => Post.fromJson({...doc.data(), 'id': doc.id}),
          ),
        );
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _normalize(String input) => input.replaceAll(' ', '').toLowerCase();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประกาศของหาย/เจอของ'),
        foregroundColor: theme.colorScheme.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'ของหาย'), Tab(text: 'เจอของ')],
          indicatorColor: Theme.of(context).colorScheme.primary,
          dividerColor: Colors.transparent,
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildPostsList(true), _buildPostsList(false)],
            ),
          ),
        ],
      ),
      bottomNavigationBar: PostActionButtons(
        onLostPress: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LostItemForm()),
          );
        },
        onFoundPress: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FindItemForm()),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'ค้นหา...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                ),
                onChanged: (value) {
                  // TODO: Handle search query
                },
              ),
            ),
          ),
          const SizedBox(
            width: 8.0,
          ), // เพิ่มระยะห่างระหว่าง TextField และ PopupButton
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              // TODO: Handle filter selection
            },
            itemBuilder:
                (context) => const [
                  PopupMenuItem(value: null, child: Text('ทั้งหมด')),
                  PopupMenuItem(value: '1', child: Text('ของใช้ส่วนตัว')),
                  PopupMenuItem(value: '2', child: Text('เอกสาร/บัตร')),
                  PopupMenuItem(value: '3', child: Text('อุปกรณ์การเรียน')),
                  PopupMenuItem(value: '4', child: Text('ของมีค่าอื่นๆ')),
                ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList(bool isLostItems) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    // กรองโพสต์ตามเงื่อนไขการค้นหาและหมวดหมู่
    final normalizedQuery = _normalize(searchQuery);
    final filteredPosts =
        posts.where((post) {
          final matchesType = post.isLostItem == isLostItems;
          final matchesSearch =
              normalizedQuery.isEmpty ||
              _normalize(post.title).contains(normalizedQuery) ||
              _normalize(post.description).contains(normalizedQuery) ||
              _normalize(post.building).contains(normalizedQuery) ||
              _normalize(post.location).contains(normalizedQuery);
          final matchesCategory =
              selectedCategory == null ||
              selectedCategory == 'all' ||
              post.category == selectedCategory;
          return matchesType && matchesSearch && matchesCategory;
        }).toList();

    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: Container(
        color:
            Theme.of(context).colorScheme.surface, // 👈 เปลี่ยนสีพื้นหลังตรงนี้
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo.metrics.pixels ==
                scrollInfo.metrics.maxScrollExtent) {
              _loadMorePosts();
            }
            return true;
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: filteredPosts.length,
            itemBuilder:
                (context, index) => _buildPostItem(
                  filteredPosts[index],
                  isMobile: MediaQuery.of(context).size.width < 600,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostItem(Post post, {required bool isMobile}) {
    if (isMobile) {
      // Mobile layout - แนวนอน
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: InkWell(
          onTap: () => _showPostDetail(post),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          post.isLostItem ? Colors.red[100] : Colors.green[100],
                      child: Icon(
                        post.isLostItem
                            ? Icons.help_outline
                            : Icons.check_circle_outline,
                        color: post.isLostItem ? Colors.red : Colors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.userName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${post.isLostItem ? "แจ้งของหาย" : "แจ้งเจอของ"} • ${_getTimeAgo(post.createdAt)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (post.status == 'closed')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'ปิดการค้นหา',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${post.building} • ${post.location}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                if (post.imageUrl.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: post.imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                      errorWidget:
                          (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
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
                  style: TextStyle(color: Colors.grey[600]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Tablet/Desktop layout - แนวตั้ง (Card style)
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => _showPostDetail(post),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              if (post.imageUrl.isNotEmpty)
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: post.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                      errorWidget:
                          (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                )
              else
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        post.isLostItem
                            ? Icons.help_outline
                            : Icons.check_circle_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),

              // Content section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with status
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                post.isLostItem
                                    ? Colors.red[100]
                                    : Colors.green[100],
                            child: Icon(
                              post.isLostItem
                                  ? Icons.help_outline
                                  : Icons.check_circle_outline,
                              size: 16,
                              color:
                                  post.isLostItem ? Colors.red : Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              post.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (post.status == 'closed')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'ปิด',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Title
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

                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${post.building} • ${post.location}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Time
                      Text(
                        _getTimeAgo(post.createdAt),
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showPostDetail(Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => PostDetailSheet(post: post),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays} วันที่แล้ว';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else {
      return 'เมื่อสักครู่';
    }
  }

  void _handleContact(Post post) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('ช่องทางการติดต่อ'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(post.userName),
                ),
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: Text(post.contact),
                ),
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
}
