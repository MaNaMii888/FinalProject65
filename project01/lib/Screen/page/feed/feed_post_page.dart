import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project01/models/post.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:project01/models/post_detail_sheet.dart';

class FeedPostPage extends StatefulWidget {
  const FeedPostPage({super.key});

  @override
  State<FeedPostPage> createState() => _FeedPostPageState();
}

class _FeedPostPageState extends State<FeedPostPage> {
  final ScrollController _scrollController = ScrollController();
  List<Post> posts = [];
  bool isLoading = true;
  String searchQuery = '';
  String? selectedCategory;
  String selectedStatus = 'all'; // 'all', 'open', 'closed'
  String selectedType = 'all'; // 'all', 'lost', 'found'
  static const int pageSize = 10;
  DocumentSnapshot? lastDocument;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
      'lost_found_items',
    );

    // Filter by type (lost/found)
    if (selectedType != 'all') {
      query = query.where('isLostItem', isEqualTo: selectedType == 'lost');
    }

    // Filter by status
    if (selectedStatus != 'all') {
      query = query.where('status', isEqualTo: selectedStatus);
    }

    // Filter by category if selected
    if (selectedCategory != null && selectedCategory!.isNotEmpty) {
      query = query.where('category', isEqualTo: selectedCategory);
    }

    // Search in title and description
    if (searchQuery.isNotEmpty) {
      // Note: This is a simple implementation. For better search, consider using Algolia or similar
      query = query
          .where('title', isGreaterThanOrEqualTo: searchQuery)
          .where('title', isLessThanOrEqualTo: searchQuery + '\uf8ff');
    }

    return query.orderBy('createdAt', descending: true);
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final query = _buildQuery().limit(pageSize);
      final snapshot = await query.get();

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
      var query = _buildQuery().limit(pageSize);

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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showPostDetail(Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostDetailSheet(post: post),
    );
  }

  Widget _buildPostCard(Post post) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showPostDetail(post),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(
                child: Text(post.userName[0].toUpperCase()),
              ),
              title: Text(post.userName),
              subtitle: Text(post.getTimeAgo()),
              trailing: _buildStatusChip(post),
            ),
            if (post.imageUrl.isNotEmpty)
              SizedBox(
                height: 200,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(post.description),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.building} ${post.location}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(Post post) {
    Color backgroundColor;
    String label;
    Color textColor = Colors.white;

    switch (post.status.toLowerCase()) {
      case 'open':
        backgroundColor = Colors.green;
        label = 'เปิด';
        break;
      case 'closed':
        backgroundColor = Colors.red;
        label = 'ปิด';
        break;
      default:
        backgroundColor = Colors.grey;
        label = 'ไม่ระบุ';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 12)),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          DropdownButton<String>(
            value: selectedType,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('ทั้งหมด')),
              DropdownMenuItem(value: 'lost', child: Text('ของหาย')),
              DropdownMenuItem(value: 'found', child: Text('พบของ')),
            ],
            onChanged: (value) {
              setState(() {
                selectedType = value!;
                _loadPosts();
              });
            },
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: selectedStatus,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('สถานะทั้งหมด')),
              DropdownMenuItem(value: 'open', child: Text('เปิด')),
              DropdownMenuItem(value: 'closed', child: Text('ปิด')),
            ],
            onChanged: (value) {
              setState(() {
                selectedStatus = value!;
                _loadPosts();
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประกาศทั้งหมด'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ค้นหาประกาศ...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  _loadPosts();
                });
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadPosts,
              child:
                  posts.isEmpty && !isLoading
                      ? const Center(child: Text('ไม่พบประกาศ'))
                      : ListView.builder(
                        controller: _scrollController,
                        itemCount: posts.length + (isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= posts.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          return _buildPostCard(posts[index]);
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
