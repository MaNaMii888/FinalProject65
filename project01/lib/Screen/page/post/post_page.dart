import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project01/providers/post_provider.dart';
import 'package:project01/Screen/page/post/action/found_item_action.dart';
import 'package:project01/Screen/page/post/action/lost_item_action.dart';
import 'package:project01/Screen/page/post/action/post_actions_buttons.dart';
import 'package:project01/utils/time_formatter.dart';
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

  bool isFabOpen = false;

  void toggleFab() {
    setState(() {
      isFabOpen = !isFabOpen;
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PostProvider>(context, listen: false);
      if (provider.lostPosts.isEmpty && provider.foundPosts.isEmpty) {
         provider.refreshAll();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _clearAllFilters() {
    final provider = Provider.of<PostProvider>(context, listen: false);
    provider.clearFilters();
    _searchController.clear();
  }

  // ฟังก์ชันแสดงข้อความตัวกรองที่กำลังใช้งาน
  String _getActiveFiltersText(PostProvider provider) {
    List<String> activeFilters = [];

    if (provider.searchQuery.isNotEmpty) {
      activeFilters.add('คำค้นหา "${provider.searchQuery}"');
    }

    if (provider.selectedCategory != null) {
      String categoryName = _getCategoryName(provider.selectedCategory!);
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
  int _getFilteredPostsCount(PostProvider provider, bool isLostItems) {
    if (provider.searchQuery.isEmpty && provider.selectedCategory == null) {
      return isLostItems ? provider.totalLostCount : provider.totalFoundCount;
    }
    return isLostItems ? provider.lostPosts.length : provider.foundPosts.length;
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
                          '${_getFilteredPostsCount(context.watch<PostProvider>(), true)}',
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
                          '${_getFilteredPostsCount(context.watch<PostProvider>(), false)}',
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
                  context.read<PostProvider>().refreshAll();
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
                  context.read<PostProvider>().refreshAll();
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
                      context.read<PostProvider>().setSearchQuery(value);
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
                  context.read<PostProvider>().setCategory(value);
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
          if (context.watch<PostProvider>().searchQuery.isNotEmpty || context.watch<PostProvider>().selectedCategory != null)
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
                      'กรองโดย: ${_getActiveFiltersText(context.watch<PostProvider>())}',
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
    return Consumer<PostProvider>(
      builder: (context, provider, child) {
        final bool currentIsLoading = isLostItems ? provider.isLoadingLost : provider.isLoadingFound;
        final bool currentIsLoadingMore = isLostItems ? provider.isLoadingMoreLost : provider.isLoadingMoreFound;

        if (currentIsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredPosts = isLostItems ? provider.lostPosts : provider.foundPosts;

        if (filteredPosts.isEmpty) {
          String noResultsText = '';
          String suggestionText = '';

          if (provider.searchQuery.isNotEmpty || provider.selectedCategory != null) {
            noResultsText = 'ไม่พบผลลัพธ์ที่ค้นหา';
            suggestionText = 'ลองเปลี่ยนคำค้นหาหรือเคลียร์ตัวกรอง';
          } else {
            noResultsText = isLostItems ? 'ยังไม่มีโพสต์ของหาย' : 'ยังไม่มีโพสต์เจอของ';
            suggestionText = isLostItems ? 'เป็นคนแรกที่แจ้งของหาย' : 'เป็นคนแรกที่แจ้งเจอของ';
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  (provider.searchQuery.isNotEmpty || provider.selectedCategory != null)
                      ? Icons.search_off
                      : (isLostItems ? Icons.help_outline : Icons.check_circle_outline),
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
                if (provider.searchQuery.isNotEmpty || provider.selectedCategory != null) ...[
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
          onRefresh: () async {
            provider.loadPosts(isLostItems: isLostItems, isRefresh: true);
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                provider.loadPosts(isLostItems: isLostItems, isRefresh: false);
              }
              return false;
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filteredPosts.length + (currentIsLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == filteredPosts.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return _buildPostItem(
                  filteredPosts[index],
                  isMobile: MediaQuery.of(context).size.width < 600,
                );
              },
            ),
          ),
        );
      },
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
                                        future: context.read<PostProvider>().getUserName(post.userId),
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
                              ' • ${TimeFormatter.getTimeAgo(post.createdAt)}',
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

                    // สถานที่ (Location Tag) และ สถานะ
                    if (post.building.isNotEmpty ||
                        post.location.isNotEmpty ||
                        post.status == 'active')
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            if (post.building.isNotEmpty ||
                                post.location.isNotEmpty)
                              Expanded(
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
                                          color: onPrimaryColor.withOpacity(
                                            0.5,
                                          ),
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (post.status == 'active') ...[
                              const Spacer(),
                              _buildStatusBadge('active'),
                            ],
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

  // ✅ ฟังก์ชันสำหรับสร้าง Badge สถานะ "กำลังดำเนินการ"
  Widget _buildStatusBadge(String status) {
    if (status != 'active') return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(
          0xFFFFE0B2,
        ).withOpacity(0.9), // สีส้มอ่อน (Peach/Orange)
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Text(
        'กำลังดำเนินการ',
        style: TextStyle(
          color: Color(0xFFEF6C00), // สีส้มเข้ม
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
