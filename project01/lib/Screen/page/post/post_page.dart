import 'package:flutter/material.dart';
import 'package:project01/Screen/page/post/action/find_item_action.dart';
import 'package:project01/Screen/page/post/action/found_item_action.dart';
import 'package:project01/Screen/page/post/action/post_actions_buttons.dart';
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
  final TextEditingController _searchController = TextEditingController();
  List<Post> posts = [];
  bool isLoading = true;
  String searchQuery = '';
  String? selectedCategory;
  static const int pageSize = 10;
  DocumentSnapshot? lastDocument;
  bool hasMore = true;

  // FAB Animated
  bool isFabOpen = false;

  // Cache for user names to avoid repeated reads
  final Map<String, String> _userNameCache = {};

  Future<String> _getUserName(String? userId) async {
    if (userId == null || userId.trim().isEmpty) return 'ไม่ระบุผู้โพสต์';
    if (_userNameCache.containsKey(userId)) return _userNameCache[userId]!;
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      final data = doc.data();
      final name =
          (data != null &&
                  data['name'] != null &&
                  (data['name'] as String).trim().isNotEmpty)
              ? data['name'] as String
              : 'ไม่ระบุผู้โพสต์';
      _userNameCache[userId] = name;
      return name;
    } catch (e) {
      // on error return fallback
      return 'ไม่ระบุผู้โพสต์';
    }
  }

  void toggleFab() {
    setState(() {
      isFabOpen = !isFabOpen;
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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
        hasMore = snapshot.docs.length == pageSize;
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
    if (!mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _normalize(String input) => input.replaceAll(' ', '').toLowerCase();

  // ฟังก์ชันเคลียร์ตัวกรองทั้งหมด
  void _clearAllFilters() {
    setState(() {
      searchQuery = '';
      selectedCategory = null;
    });
    // เคลียร์ข้อความค้นหาใน TextField
    _searchController.clear();
  }

  // ฟังก์ชันแสดงข้อความตัวกรองที่กำลังใช้งาน
  String _getActiveFiltersText() {
    List<String> activeFilters = [];

    if (searchQuery.isNotEmpty) {
      activeFilters.add('คำค้นหา "$searchQuery"');
    }

    if (selectedCategory != null) {
      String categoryName = _getCategoryName(selectedCategory!);
      activeFilters.add('ประเภท "$categoryName"');
    }

    if (activeFilters.isEmpty) {
      return 'ไม่มีตัวกรอง';
    }

    return activeFilters.join(' • ');
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
        return 'ไม่ระบุ';
    }
  }

  // ฟังก์ชันนับจำนวนโพสต์ที่ผ่านตัวกรอง
  int _getFilteredPostsCount(bool isLostItems) {
    final normalizedQuery = _normalize(searchQuery);
    return posts.where((post) {
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
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          // Use theme primary as page background
          backgroundColor: Theme.of(context).colorScheme.primary,
          appBar: AppBar(
            title: const SizedBox.shrink(),
            toolbarHeight: 0,
            bottom: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.onPrimary,
              unselectedLabelColor: Theme.of(
                context,
              ).colorScheme.onPrimary.withOpacity(0.7),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('ของหาย'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_getFilteredPostsCount(true)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('เจอของ'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_getFilteredPostsCount(false)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
        ),

        /// 👇 ปุ่ม FAB
        Positioned(
          child: PostActionButton(
            onLostPress: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LostItemForm()),
              ).then((_) {
                // After returning from Lost form, switch to the "ของหาย" tab and reload
                if (mounted) {
                  _tabController.animateTo(0);
                  _loadPosts();
                }
              });
            },
            onFoundPress: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FindItemForm()),
              ).then((_) {
                // After returning from Found form, switch to the "เจอของ" tab and reload
                if (mounted) {
                  _tabController.animateTo(1);
                  _loadPosts();
                }
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
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
                    controller: _searchController,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    cursorColor: Theme.of(context).colorScheme.surface,
                    decoration: InputDecoration(
                      hintText: 'ค้นหา...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              PopupMenuButton<String?>(
                icon: Icon(
                  Icons.filter_list,
                  color: Theme.of(context).colorScheme.surface,
                ),
                color: Theme.of(context).colorScheme.secondary,
                elevation: 3, // ✅ ความสูงของเงา
                shadowColor: Colors.white, // ✅ สีเงา
                offset: const Offset(0, 60),
                onSelected: (value) {
                  setState(() {
                    selectedCategory = value;
                  });
                },
                itemBuilder:
                    (context) => const [
                      PopupMenuItem<String?>(
                        value: null,
                        child: Text('ทั้งหมด'),
                      ),
                      PopupMenuItem<String?>(
                        value: '1',
                        child: Text('ของใช้ส่วนตัว'),
                      ),
                      PopupMenuItem<String?>(
                        value: '2',
                        child: Text('เอกสาร/บัตร'),
                      ),
                      PopupMenuItem<String?>(
                        value: '3',
                        child: Text('อุปกรณ์การเรียน'),
                      ),
                      PopupMenuItem<String?>(
                        value: '4',
                        child: Text('ของมีค่าอื่นๆ'),
                      ),
                    ],
              ),
            ],
          ),
          // แสดงสถานะตัวกรองและปุ่มเคลียร์
          if (searchQuery.isNotEmpty || selectedCategory != null)
            Container(
              margin: const EdgeInsets.only(top: 16.0),
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_alt,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'กรองโดย: ${_getActiveFiltersText()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _clearAllFilters,
                    icon: Icon(Icons.clear, size: 18, color: Colors.red[600]),
                    tooltip: 'เคลียร์ตัวกรองทั้งหมด',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostsList(bool isLostItems) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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

    if (filteredPosts.isEmpty) {
      String noResultsText = '';
      String suggestionText = '';

      if (searchQuery.isNotEmpty || selectedCategory != null) {
        // มีการใช้ตัวกรองแต่ไม่มีผลลัพธ์
        noResultsText = 'ไม่พบผลลัพธ์ที่ค้นหา';
        suggestionText = 'ลองเปลี่ยนคำค้นหาหรือเคลียร์ตัวกรอง';
      } else {
        // ไม่มีข้อมูลเลย
        noResultsText =
            isLostItems ? 'ยังไม่มีโพสต์ของหาย' : 'ยังไม่มีโพสต์เจอของ';
        suggestionText =
            isLostItems ? 'เป็นคนแรกที่แจ้งของหาย' : 'เป็นคนแรกที่แจ้งเจอของ';
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searchQuery.isNotEmpty || selectedCategory != null
                  ? Icons.search_off
                  : (isLostItems
                      ? Icons.help_outline
                      : Icons.check_circle_outline),
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              noResultsText,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              suggestionText,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            if (searchQuery.isNotEmpty || selectedCategory != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _clearAllFilters,
                icon: const Icon(Icons.clear_all),
                label: const Text('เคลียร์ตัวกรอง'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[100],
                  foregroundColor: Colors.orange[800],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
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
    );
  }

  Widget _buildPostItem(Post post, {required bool isMobile}) {
    if (isMobile) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        color: Theme.of(context).colorScheme.primary, // ✅ เพิ่มสีพื้นหลัง
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: Theme.of(context).colorScheme.onPrimary, // สีของกรอบ
            width: 0.5, // ความหนาของกรอบ
          ),
        ),
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
                          post.userName.trim().isEmpty
                              ? FutureBuilder<String>(
                                future: _getUserName(post.userId),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Text(
                                      'กำลังโหลด...',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Theme.of(context)
                                                .colorScheme
                                                .surface, // เปลี่ยนสีข้อความ
                                      ),
                                    );
                                  }
                                  final name =
                                      (snapshot.data ?? 'ไม่ระบุผู้โพสต์');
                                  return Text(
                                    name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context)
                                              .colorScheme
                                              .surface, // เปลี่ยนสีข้อความ
                                    ),
                                  );
                                },
                              )
                              : Text(
                                post.userName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.primary, // เปลี่ยนสีข้อความ
                                ),
                              ),
                          Text(
                            '${post.isLostItem ? "แจ้งของหาย" : "แจ้งเจอของ"} • ${_getTimeAgo(post.createdAt)}',
                            style: TextStyle(
                              color:
                                  Theme.of(context)
                                      .colorScheme
                                      .onPrimary, // สีเทาสำหรับรายละเอียด
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer, // สีข้อความหัวเรื่อง
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  post.description,
                  style: TextStyle(color: Colors.grey[700]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Desktop/Tablet layout
      return Card(
        elevation: 4,
        color: Theme.of(context).colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.grey[300]!, // สีของกรอบ
            width: 1.5, // ความหนาของกรอบ
          ),
        ),
        child: InkWell(
          onTap: () => _showPostDetail(post),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: post.imageUrl,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                    errorWidget:
                        (context, url, error) => const Icon(Icons.error),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            color: post.isLostItem ? Colors.red : Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child:
                              post.userName.trim().isEmpty
                                  ? FutureBuilder<String>(
                                    future: _getUserName(post.userId),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Text(
                                          'กำลังโหลด...',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      }
                                      final name =
                                          (snapshot.data ?? 'ไม่ระบุผู้โพสต์');
                                      return Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    },
                                  )
                                  : Text(
                                    post.userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.black87,
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
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
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
                    Text(
                      _getTimeAgo(post.createdAt),
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
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
}
