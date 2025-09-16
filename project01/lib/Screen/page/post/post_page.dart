import 'package:flutter/material.dart';
import 'package:project01/Screen/action/find_item_action.dart';
import 'package:project01/Screen/page/post/widget/post_actions_buttons.dart';
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
  List<Post> allPosts = [];
  List<Post> lostPosts = [];
  List<Post> foundPosts = [];
  bool isLoading = true;
  String searchQuery = '';
  String? selectedCategory;
  static const int pageSize = 20;
  DocumentSnapshot? lastDocument;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    // Initialize TabController for two tabs: ของหาย, เจอของ
    _tabController = TabController(length: 2, vsync: this);
    // Load initial posts
    _loadAllPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllPosts() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    print('=== Starting _loadAllPosts() ===');

    try {
      print('Querying Firebase collection: lost_found_items');
      final snapshot = await FirebaseFirestore.instance
          .collection('lost_found_items')
          .orderBy('createdAt', descending: true)
          .limit(pageSize)
          .get()
          .timeout(const Duration(seconds: 10));

      print('Firebase query result - Number of docs: ${snapshot.docs.length}');

      if (snapshot.docs.isNotEmpty) {
        lastDocument = snapshot.docs.last;
        // Debug: แสดงข้อมูลของแต่ละ document
        for (int i = 0; i < snapshot.docs.length; i++) {
          print('Document $i: ${snapshot.docs[i].data()}');
        }
      } else {
        print('No documents found in Firebase collection');
      }

      if (!mounted) return;

      // แปลงข้อมูลทั้งหมด
      final allPostsData =
          snapshot.docs
              .map((doc) => Post.fromJson({...doc.data(), 'id': doc.id}))
              .toList();

      // แยกข้อมูลตามประเภท
      final lostItems = allPostsData.where((post) => post.isLostItem).toList();
      final foundItems =
          allPostsData.where((post) => !post.isLostItem).toList();

      setState(() {
        allPosts = allPostsData;
        lostPosts = lostItems;
        foundPosts = foundItems;
        isLoading = false;
      });

      print(
        'Posts loaded - All: ${allPosts.length}, Lost: ${lostPosts.length}, Found: ${foundPosts.length}',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      print('Error loading posts: $e');
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ประกาศของหาย/เจอของ',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
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
              children: [
                _buildPostsList(true), // ของหาย
                _buildPostsList(false), // เจอของ
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: PostActionButtons(
        onLostPress: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LostItemForm()),
          ).then((_) => _loadAllPosts()); // รีเฟรชข้อมูลหลังจากสร้างโพสต์
        },
        onFoundPress: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FindItemForm()),
          ).then((_) => _loadAllPosts()); // รีเฟรชข้อมูลหลังจากสร้างโพสต์
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
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                selectedCategory = value;
              });
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

  // หน้าหลักแสดงโพสต์ทั้งหมด
  Widget _buildAllPostsList() {
    print('=== _buildAllPostsList called ===');
    print('isLoading: $isLoading');
    print('Total all posts: ${allPosts.length}');

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredPosts = _filterPosts(allPosts);
    print('Filtered all posts: ${filteredPosts.length}');

    if (filteredPosts.isEmpty) {
      return _buildEmptyState(
        'ยังไม่มีโพสต์',
        'เมื่อมีผู้ใช้แจ้งของหายหรือเจอของ จะแสดงที่นี่',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllPosts,
      child: _buildPostsListView(filteredPosts),
    );
  }

  // หน้าสำหรับแสดงโพสต์ตามประเภท (ของหาย/เจอของ)
  Widget _buildPostsList(bool isLostItems) {
    print('=== _buildPostsList called for ${isLostItems ? "Lost Items" : "Found Items"} ===');
    
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('lost_found_items')
          .where('isLostItem', isEqualTo: isLostItems)
          .snapshots(),
      builder: (context, snapshot) {
        print('StreamBuilder state: ${snapshot.connectionState}');
        print('Has error: ${snapshot.hasError}');
        print('Has data: ${snapshot.hasData}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('StreamBuilder waiting...');
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          print('StreamBuilder error: ${snapshot.error}');
          return _buildEmptyState(
            'เกิดข้อผิดพลาดในการโหลด',
            'Error: ${snapshot.error}',
          );
        }
        
        final docs = snapshot.data?.docs ?? [];
        print('Number of documents from Firebase: ${docs.length}');
        
        if (docs.isEmpty) {
          final message =
              isLostItems ? 'ยังไม่มีโพสต์ของหาย' : 'ยังไม่มีโพสต์เจอของ';
          final subtitle =
              isLostItems
                  ? 'เมื่อมีผู้ใช้แจ้งของหาย จะแสดงที่นี่'
                  : 'เมื่อมีผู้ใช้แจ้งเจอของ จะแสดงที่นี่';
          return _buildEmptyState(message, subtitle);
        }

        try {
          final allPostsData = docs
              .map((doc) {
                final data = doc.data();
                print('Document ${doc.id}: $data');
                return Post.fromJson({...data, 'id': doc.id});
              })
              .toList();

          print('Successfully parsed ${allPostsData.length} posts');

          // เรียงลำดับข้อมูลใน client side แทนการใช้ orderBy ใน query
          allPostsData.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          final filteredPosts = _filterPosts(allPostsData);
          print('Filtered posts: ${filteredPosts.length}');

          if (filteredPosts.isEmpty) {
            final message =
                isLostItems ? 'ไม่พบโพสต์ของหายที่ตรงกับการค้นหา' : 'ไม่พบโพสต์เจอของที่ตรงกับการค้นหา';
            return _buildEmptyState(message, 'ลองเปลี่ยนคำค้นหาหรือตัวกรอง');
          }

          return RefreshIndicator(
            onRefresh: _loadAllPosts,
            child: _buildPostsListView(filteredPosts),
          );
        } catch (e) {
          print('Error parsing posts: $e');
          return _buildEmptyState(
            'เกิดข้อผิดพลาดในการแปลงข้อมูล',
            'Error: $e',
          );
        }
      },
    );
  }

  // กรองโพสต์ตามเงื่อนไขการค้นหาและหมวดหมู่
  List<Post> _filterPosts(List<Post> posts) {
    final normalizedQuery = _normalize(searchQuery);
    print(
      'Filtering posts - searchQuery: "$searchQuery", selectedCategory: $selectedCategory',
    );

    return posts.where((post) {
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

      print(
        'Post: "${post.title}", matchesSearch: $matchesSearch, matchesCategory: $matchesCategory',
      );

      return matchesSearch && matchesCategory;
    }).toList();
  }

  // สร้าง ListView สำหรับแสดงโพสต์
  Widget _buildPostsListView(List<Post> posts) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: posts.length,
      itemBuilder:
          (context, index) => _buildPostItem(
            posts[index],
            isMobile: MediaQuery.of(context).size.width < 600,
          ),
    );
  }

  // สร้าง empty state
  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Debug: Total posts = ${allPosts.length}',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  // สร้าง PostItem
  Widget _buildPostItem(Post post, {required bool isMobile}) {
    print(
      '_buildPostItem - Post: ${post.title}, isLostItem: ${post.isLostItem}',
    );

    if (isMobile) {
      // Mobile layout
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
      // Tablet/Desktop layout
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
}
