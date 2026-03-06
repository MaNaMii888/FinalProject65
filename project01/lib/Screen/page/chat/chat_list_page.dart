import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project01/services/chat_service.dart';
import 'package:project01/Screen/page/chat/chat_room_page.dart';
import 'package:intl/intl.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  // ระบบ Cache เพื่อจำข้อมูลผู้ใช้ที่โหลดมาแล้ว ลดการสิ้นเปลือง Firestore Reads
  final Map<String, Map<String, dynamic>> _userCache = {};
  final Set<String> _fetchingUsers = {};

  void _fetchUserData(String userId) async {
    if (_fetchingUsers.contains(userId) || _userCache.containsKey(userId))
      return;
    _fetchingUsers.add(userId);

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      if (doc.exists && mounted) {
        setState(() {
          _userCache[userId] = doc.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      debugPrint('Error fetching user data for cache: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('กรุณาล็อกอินเพื่อดูแชท'));
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'ข้อความ',
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ChatService().getUserChatRoomsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs.toList() ?? [];

          // เรียงลำดับแชทจากใหม่ไปเก่า (ฝั่ง Client) เพื่อแก้ปัญหา Firestore requires an index
          docs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            final timeA = dataA['lastMessageTime'] as Timestamp?;
            final timeB = dataB['lastMessageTime'] as Timestamp?;
            if (timeA == null && timeB == null) return 0;
            if (timeA == null) return 1;
            if (timeB == null) return -1;
            return timeB.compareTo(timeA);
          });

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: colorScheme.onPrimary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ยังไม่มีการสนทนา',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onPrimary.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            separatorBuilder:
                (context, index) => Divider(
                  color: colorScheme.onPrimary.withOpacity(0.1),
                  height: 1,
                  indent: 72,
                ),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final chatId = docs[index].id;

              // ดึงข้อมูลเบื้องต้นมาแสดง
              final lastMessage = data['lastMessage'] ?? '';
              final lastMessageTime = data['lastMessageTime'] as Timestamp?;
              final postId = data['postId'] ?? '';
              final postStatus = data['postStatus'] ?? 'active';
              final participants = List<String>.from(
                data['participants'] ?? [],
              );

              // หา UID ของฝ่ายตรงข้าม
              final otherUserId = participants.firstWhere(
                (id) => id != user.uid,
                orElse: () => '',
              );

              // เลขแจ้งเตือนของตัวเอง
              final unreadMap = Map<String, dynamic>.from(
                data['unreadCount'] ?? {},
              );
              final int unreadCount = unreadMap[user.uid] ?? 0;
              final bool hasUnread = unreadCount > 0;

              // Trigger การดึงข้อมูลมาเก็บไว้ใน Cache ถ้ายังไม่มี
              if (!_userCache.containsKey(otherUserId)) {
                _fetchUserData(otherUserId);
              }

              final userData = _userCache[otherUserId] ?? {};
              final profileImage =
                  userData['profileImageUrl'] as String? ??
                  userData['profileUrl'] as String?;
              final displayName =
                  userData['firstName'] ??
                  userData['name'] ??
                  'ผู้ใช้ไม่ระบุชื่อ';

              return ListTile(
                onLongPress: () async {
                  final bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text("ยืนยันการลบ"),
                        content: const Text(
                          "คุณต้องการลบห้องแชตนี้ใช่หรือไม่?\nประวัติการคุยจะหายไปทั้งหมด",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("ยกเลิก"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text(
                              "ลบ",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm == true) {
                    ChatService()
                        .deleteChatRoom(chatId)
                        .then((_) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ลบห้องแชตเรียบร้อยแล้ว'),
                              ),
                            );
                          }
                        })
                        .catchError((error) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ไม่สามารถลบได้ กรุณาลองใหม่'),
                              ),
                            );
                          }
                        });
                  }
                },
                onTap: () {
                  // เคลียร์ notification แจ้งเตือนเวลาเข้าห้อง
                  ChatService().markMessagesAsRead(chatId, user.uid);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ChatRoomPage(
                            chatId: chatId,
                            otherUserId: otherUserId,
                            postId: postId,
                            initialUserName: displayName,
                            initialUserProfileImage: profileImage,
                          ),
                    ),
                  );
                },
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      _userCache.containsKey(otherUserId)
                          ? colorScheme.primary.withOpacity(0.2)
                          : colorScheme.onPrimary.withOpacity(0.1),
                  backgroundImage:
                      profileImage != null && profileImage.isNotEmpty
                          ? NetworkImage(profileImage)
                          : null,
                  child:
                      (profileImage == null || profileImage.isEmpty)
                          ? Icon(
                            Icons.person,
                            color:
                                _userCache.containsKey(otherUserId)
                                    ? colorScheme.primary
                                    : Colors.grey,
                          )
                          : null,
                ),
                title: Text(
                  displayName,
                  style: TextStyle(
                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                    color: colorScheme.onPrimary,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    lastMessage.isEmpty ? 'เริ่มการสนทนา...' : lastMessage,
                    style: TextStyle(
                      color:
                          hasUnread
                              ? colorScheme.onPrimary
                              : colorScheme.onPrimary.withOpacity(0.6),
                      fontWeight:
                          hasUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (postStatus == 'resolved')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ส่งมอบแล้ว',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    if (lastMessageTime != null)
                      Text(
                        _formatTime(lastMessageTime.toDate()),
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              hasUnread
                                  ? colorScheme.primary
                                  : colorScheme.onPrimary.withOpacity(0.5),
                          fontWeight:
                              hasUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    const SizedBox(height: 6),
                    if (hasUnread)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    if (now.year == date.year &&
        now.month == date.month &&
        now.day == date.day) {
      return DateFormat('HH:mm').format(date); // วันนี้ โชว์เวลา
    }
    return DateFormat('dd MMM').format(date); // วันอื่น โชว์วันที่
  }
}
