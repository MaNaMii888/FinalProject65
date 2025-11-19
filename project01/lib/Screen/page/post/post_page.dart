import 'package:flutter/material.dart';
import 'package:project01/Screen/page/post/action/found_item_action.dart';
import 'package:project01/Screen/page/post/action/lost_item_action.dart';
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
      // ลอง comment บรรทัด orderBy ออกชั่วคราว เพื่อเทสว่าเกี่ยวกับ Index ไหม
      final snapshot =
          await FirebaseFirestore.instance
              .collection('lost_found_items')
              .orderBy('createdAt', descending: true)
              .limit(pageSize)
              .get();

      debugPrint("🔥 เจอข้อมูลจำนวน: ${snapshot.docs.length} รายการ");

      if (snapshot.docs.isNotEmpty) {
        lastDocument = snapshot.docs.last;
      }

      if (!mounted) return;

      // ลองแปลงข้อมูลดูว่าพังตรง Model หรือไม่
      final List<Post> loadedPosts = [];
      for (var doc in snapshot.docs) {
        try {
          loadedPosts.add(Post.fromJson({...doc.data(), 'id': doc.id}));
        } catch (e) {
          debugPrint("💥 Error แปลงข้อมูล ID ${doc.id}: $e");
          // อาจจะเกิดจากชื่อตัวแปรไม่ตรงกัน (detail vs description)
        }
      }

      setState(() {
        posts = loadedPosts;
        isLoading = false;
        hasMore = snapshot.docs.length == pageSize;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      debugPrint("❌ Error โหลดข้อมูล: $e");
      _showError('เกิดข้อผิดพลาด: $e');
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
          backgroundColor: Theme.of(context).colorScheme.surface,
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
              indicatorColor: Theme.of(context).colorScheme.surface,
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
                    color: Theme.of(context).colorScheme.surfaceContainer,
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
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.primary,
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
                  color: Theme.of(context).colorScheme.secondary,
                ),
                color: Theme.of(context).colorScheme.primary,
                elevation: 3, // ✅ ความสูงของเงา
                shadowColor: Colors.white, // ✅ สีเงา
                offset: const Offset(0, 60),
                onSelected: (value) {
                  setState(() {
                    selectedCategory = value;
                  });
                },
                itemBuilder:
                    (context) => [
                      PopupMenuItem<String?>(
                        value: null,
                        child: Text(
                          'ทั้งหมด',
                          style: TextStyle(
                            color:
                                Theme.of(context)
                                    .colorScheme
                                    .onPrimary, // หรือ Theme.of(context).colorScheme.onSecondary,
                          ),
                        ),
                      ),
                      PopupMenuItem<String?>(
                        value: '1',
                        child: Text(
                          'ของใช้ส่วนตัว',
                          style: TextStyle(
                            color:
                                Theme.of(context)
                                    .colorScheme
                                    .onPrimary, // หรือ Theme.of(context).colorScheme.onSecondary,
                          ),
                        ),
                      ),
                      PopupMenuItem<String?>(
                        value: '2',
                        child: Text(
                          'เอกสาร/บัตร',
                          style: TextStyle(
                            color:
                                Theme.of(context)
                                    .colorScheme
                                    .onPrimary, // หรือ Theme.of(context).colorScheme.onSecondary,
                          ),
                        ),
                      ),
                      PopupMenuItem<String?>(
                        value: '3',
                        child: Text(
                          'อุปกรณ์การเรียน',
                          style: TextStyle(
                            color:
                                Theme.of(context)
                                    .colorScheme
                                    .onPrimary, // หรือ Theme.of(context).colorScheme.onSecondary,
                          ),
                        ),
                      ),
                      PopupMenuItem<String?>(
                        value: '4',
                        child: Text(
                          'ของมีค่าอื่นๆ',
                          style: TextStyle(
                            color:
                                Theme.of(context)
                                    .colorScheme
                                    .onPrimary, // หรือ Theme.of(context).colorScheme.onSecondary,
                          ),
                        ),
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
                  color: Theme.of(context).colorScheme.surface,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_alt,
                    size: 16,
                    color: Theme.of(context).colorScheme.surface,
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
    // ดึงสีจาก Theme ให้ตรงกับหน้าแจ้งเตือน
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

    if (isMobile) {
      return InkWell(
        onTap: () => _showPostDetail(post),
        child: Container(
          // ✅ 1. ดีไซน์แบบ Feed: เต็มจอ + เส้นคั่นล่าง
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface, // พื้นหลังสี Primary
            border: Border(
              bottom: BorderSide(
                color: onPrimaryColor.withOpacity(0.2), // เส้นคั่นบางๆ
                width: 0.5,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ส่วนหัว: รูปโปรไฟล์ + ชื่อ + เวลา
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // รูปโปรไฟล์ (Avatar)
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: onPrimaryColor.withOpacity(0.1),
                    child: Icon(
                      post.isLostItem
                          ? Icons.help_outline
                          : Icons.check_circle_outline,
                      color:
                          post.isLostItem ? Colors.red[300] : Colors.green[300],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ชื่อและเวลา
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // ชื่อผู้ใช้
                            Flexible(
                              child:
                                  post.userName.trim().isEmpty
                                      ? FutureBuilder<String>(
                                        future: _getUserName(post.userId),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Text(
                                              'กำลังโหลด...',
                                              style: TextStyle(
                                                color: onPrimaryColor
                                                    .withOpacity(0.5),
                                                fontSize: 14,
                                              ),
                                            );
                                          }
                                          return Text(
                                            snapshot.data ?? 'ไม่ระบุชื่อ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color:
                                                  onPrimaryColor, // ✅ สีชื่อ (onPrimary)
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          );
                                        },
                                      )
                                      : Text(
                                        post.userName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: onPrimaryColor, // ✅ สีชื่อ
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                            ),
                            // เวลา (แสดงแบบ • 5 นาทีที่แล้ว)
                            Text(
                              ' • ${_getTimeAgo(post.createdAt)}',
                              style: TextStyle(
                                color: onPrimaryColor.withOpacity(
                                  0.6,
                                ), // ✅ สีเวลาจางๆ
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),

                        // ประเภทโพสต์ (แจ้งของหาย/เจอของ)
                        Text(
                          post.isLostItem ? '@แจ้งของหาย' : '@แจ้งเจอของ',
                          style: TextStyle(
                            color: onPrimaryColor.withOpacity(
                              0.5,
                            ), // สไตล์ Handle name
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ปุ่มปิดสถานะ (ถ้ามี)
                  if (post.status == 'closed')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: onPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ปิดแล้ว',
                        style: TextStyle(
                          fontSize: 10,
                          color: onPrimaryColor.withOpacity(0.7),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // ส่วนเนื้อหา (เยื้องขวานิดหน่อย หรือชิดซ้ายตามดีไซน์ X)
              // ผมจัดให้ตรงกับแนวชื่อเพื่อความสวยงาม (padding left = Avatar size + space)
              Padding(
                padding: const EdgeInsets.only(
                  left: 52,
                ), // 40(avatar) + 12(gap)
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // หัวข้อ
                    if (post.title.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          post.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: onPrimaryColor, // ✅ สีหัวข้อ
                          ),
                        ),
                      ),

                    // รายละเอียด
                    if (post.description.isNotEmpty)
                      Text(
                        post.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: onPrimaryColor.withOpacity(0.9), // ✅ สีเนื้อหา
                          height: 1.4,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 8),

                    // สถานที่ (Location Tag)
                    if (post.building.isNotEmpty || post.location.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: onPrimaryColor.withOpacity(0.5),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${post.building} ${post.location.isNotEmpty ? "• ${post.location}" : ""}',
                                style: TextStyle(
                                  color: onPrimaryColor.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // รูปภาพ (ถ้ามี) - ปรับขอบมนเล็กน้อย
                    if (post.imageUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: onPrimaryColor.withOpacity(0.1),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: post.imageUrl,
                              width: double.infinity,
                              // height: 200, // ปล่อย auto height หรือกำหนด max
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Container(
                                    height: 150,
                                    color: onPrimaryColor.withOpacity(0.05),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    height: 100,
                                    color: onPrimaryColor.withOpacity(0.05),
                                    child: Icon(
                                      Icons.broken_image,
                                      color: onPrimaryColor.withOpacity(0.3),
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return const SizedBox(); // ละไว้ฐานที่เข้าใจ
    }
  }

  void _showPostDetail(Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
