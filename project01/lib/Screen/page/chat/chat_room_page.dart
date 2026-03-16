import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project01/widgets/branded_loading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project01/services/chat_service.dart';
import 'package:project01/models/post.dart';
import 'package:project01/models/post_detail_sheet.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project01/widgets/smart_network_image.dart';
import 'package:project01/Screen/page/chat/qr_handover_dialog.dart';
import 'package:project01/Screen/page/chat/qr_scanner_page.dart';
import 'package:project01/Screen/page/chat/full_screen_image_page.dart';
import 'package:project01/services/chat_notification_service.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String postId;
  final String? initialUserName;
  final String? initialUserProfileImage;

  const ChatRoomPage({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.postId,
    this.initialUserName,
    this.initialUserProfileImage,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final ScrollController _scrollController = ScrollController();
  int _messageLimit = 20; // จำนวนข้อความที่จะดึงมาในแต่ละรอบ

  Map<String, dynamic>? otherUserData;
  Post? relatedPost;

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    ChatNotificationService.instance.setActiveChatRoom(widget.chatId);
    _loadHeaderData();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // เลื่อนขึ้นไปเกือบสุด (reverse: true หมายถึง maxScrollExtent คือด้านบนสุด)
      setState(() {
        _messageLimit += 20; // ดึงเพิ่มทีละ 20 ข้อความ
      });
    }
  }

  @override
  void dispose() {
    ChatNotificationService.instance.setActiveChatRoom(null);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadHeaderData() async {
    // 1. ดึงชื่อคนคุย
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.otherUserId)
            .get();
    if (userDoc.exists && mounted) {
      setState(() {
        otherUserData = userDoc.data();
      });
    }

    // 2. ดึงรูปสินค้า
    if (widget.postId.isNotEmpty) {
      try {
        final postDoc =
            await FirebaseFirestore.instance
                .collection('lost_found_items')
                .doc(widget.postId)
                .get();
        if (postDoc.exists && mounted) {
          setState(() {
            relatedPost = Post.fromJson({...postDoc.data()!, 'id': postDoc.id});
          });
        } else if (mounted) {
          setState(() {
            // โพสต์อาจถูกลบไปแล้ว สร้าง dummy ไว้กัน error
            relatedPost = Post(
              id: widget.postId,
              userId: '',
              userName: 'System',
              title: 'โพสต์ถูกลบหรือไม่มีอยู่',
              description: '',
              category: '',
              location: '',
              building: '',
              createdAt: DateTime.now(),
              imageUrl: '',
              isLostItem: true,
              status: 'deleted',
              contact: '',
            );
          });
        }
      } catch (e) {
        debugPrint('Error loading post data in chat room: $e');
      }
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentUserId == null) return;

    bool hasNet = await _hasInternet();
    if (!hasNet) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ไม่มีอินเตอร์เน็ต ไม่สามารถส่งข้อความได้'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    _messageController.clear();

    try {
      // ยิงข้อความผ่าน ChatService
      await ChatService().sendMessage(widget.chatId, currentUserId!, text);

      // เลื่อนจอลงมาร่างสุดเวลาพิมพ์เอง
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      // ระบบ Anti-Forget: ตรวจจับคีย์เวิร์ด
      _checkForAntiForgetKeywords(text);
    } catch (e) {
      // ถ้ายิงไม่สำเร็จ (เช่นเน็ตหลุด) คืนค่าข้อความกลับเข้าช่องพิมพ์
      _messageController.text = text;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ส่งข้อความไม่สำเร็จ กรุณาลองใหม่'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _checkForAntiForgetKeywords(String text) {
    if (relatedPost?.status == 'resolved' || relatedPost?.status == 'deleted') {
      return;
    }

    final keywords = [
      'เจอกัน',
      'ถึงแล้ว',
      'ที่ไหน',
      'รออยู่',
      'มารับ',
      'ส่งของ',
    ];
    bool found = keywords.any((k) => text.contains(k));

    if (found) {
      // ใช้ Future.delayed เพื่อไม่ให้ขึ้นมาทับกับการพิมพ์ทันที
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            duration: const Duration(seconds: 5),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'เตือนความจำจากระบบ (Anti-Forget)',
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'หากนัดเจอกันแล้ว อย่าลืมกดสัญลักษณ์รูป "QR Code" ด้านบนเพื่อทำการส่งมอบให้สมบูรณ์และปลอดภัยนะครับ!',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      });
    }
  }

  bool _isUploadingImage = false;

  void _sendImage() async {
    bool hasNet = await _hasInternet();
    if (!hasNet) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ไม่มีอินเตอร์เน็ต ไม่สามารถส่งรูปภาพได้'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    final picker = ImagePicker();
    // ให้เลือกว่าจะถ่ายรูปหรือเลือกจากคลังภาพ
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('ถ่ายรูป'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('เลือกจากแกลเลอรี'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (choice == null || currentUserId == null) return;

    final pickedFile = await picker.pickImage(
      source: choice,
      imageQuality: 70, // บีบอัดเล็กน้อยเพื่อประหยัดเน็ต
    );
    if (pickedFile == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final File imageFile = File(pickedFile.path);
      final downloadUrl = await ChatService().uploadImageToStorage(
        widget.chatId,
        imageFile,
      );

      if (downloadUrl != null) {
        await ChatService().sendImageMessage(
          widget.chatId,
          currentUserId!,
          downloadUrl,
        );

        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      } else {
        throw Exception('อัปโหลดรูปล้มเหลว');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ส่งรูปภาพไม่ได้ กรุณาลองใหม่'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Widget _buildDateSeparator(DateTime date, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.onPrimary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _formatDateSeparator(date),
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onPrimary.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return 'วันนี้';
    } else if (targetDate == yesterday) {
      return 'เมื่อวานนี้';
    } else {
      return DateFormat('d MMM yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      return const Scaffold(body: Center(child: Text('Unauthorized')));
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: _buildAppBar(colorScheme),
      body: Column(
        children: [
          // แถบโชว์สินค้าแบบ FB Marketplace
          if (relatedPost != null) _buildPostHeaderBanner(colorScheme),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: ChatService().getChatMessagesStream(
                widget.chatId,
                limit: _messageLimit,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const BrandedLoading();
                }
                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // เลื่อนจากล่างขึ้นบน
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == currentUserId;
                    final text = msg['text'] ?? '';
                    final type = msg['type'] ?? 'text';
                    final imageUrl = msg['imageUrl'] as String?;
                    final timestamp = msg['timestamp'] as Timestamp?;

                    bool showDateSeparator = false;
                    if (index == messages.length - 1) {
                      showDateSeparator = true;
                    } else {
                      final prevMsg =
                          messages[index + 1].data() as Map<String, dynamic>;
                      final prevTimestamp = prevMsg['timestamp'] as Timestamp?;
                      if (timestamp != null && prevTimestamp != null) {
                        final date1 = timestamp.toDate();
                        final date2 = prevTimestamp.toDate();
                        if (date1.day != date2.day ||
                            date1.month != date2.month ||
                            date1.year != date2.year) {
                          showDateSeparator = true;
                        }
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDateSeparator && timestamp != null)
                          _buildDateSeparator(timestamp.toDate(), colorScheme),
                        _buildMessageBubble(
                          text,
                          isMe,
                          timestamp,
                          colorScheme,
                          type: type,
                          imageUrl: imageUrl,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          _buildInputBottomBar(colorScheme),
        ],
      ),
    );
  }

  AppBar _buildAppBar(ColorScheme colorScheme) {
    // ใช้ข้อมูลที่ส่งเข้ามาเป็น Initial state ทันที หรือถ้าดึงจากเน็ตเสร็จแล้วร้อยเปอร์เซ็นต์ค่อยใช้
    final name =
        otherUserData?['firstName'] ??
        otherUserData?['name'] ??
        widget.initialUserName ??
        'ผู้ใช้ไม่ระบุชื่อ';

    final profileImage =
        otherUserData?['profileImageUrl'] as String? ??
        otherUserData?['profileUrl'] as String? ??
        widget.initialUserProfileImage;

    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 0.5,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colorScheme.primary.withOpacity(0.2),
            backgroundImage:
                profileImage != null && profileImage.isNotEmpty
                    ? NetworkImage(profileImage)
                    : null,
            child:
                profileImage == null
                    ? Icon(Icons.person, color: colorScheme.primary, size: 20)
                    : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        if (relatedPost != null &&
            relatedPost!.status != 'deleted' &&
            relatedPost!.status != 'resolved')
          IconButton(
            icon: Icon(Icons.qr_code_scanner, color: colorScheme.onPrimary),
            onPressed: () {
              _showQROptions(context, colorScheme);
            },
          ),
      ],
    );
  }

  void _showQROptions(BuildContext context, ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'การส่งมอบสิ่งของ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.qr_code_2, color: Colors.white),
                  ),
                  title: const Text('สร้าง QR Code ส่งมอบ'),
                  subtitle: const Text(
                    'สำหรับผู้ที่ถือของอยู่ ให้เปิดคิวอาร์โค้ดนี้รอ',
                  ),
                  onTap: () {
                    Navigator.pop(context); // ปิด bottom sheet
                    if (currentUserId == null || widget.postId.isEmpty) return;
                    showDialog(
                      context: context,
                      builder:
                          (context) => QRHandoverDialog(
                            postId: widget.postId,
                            senderId: currentUserId!,
                            receiverId: widget.otherUserId,
                            chatId: widget.chatId,
                          ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.camera_alt, color: Colors.white),
                  ),
                  title: const Text('สแกน QR รับของ'),
                  subtitle: const Text(
                    'สำหรับเจ้าของ นำกล้องไปสแกนที่เครื่องผู้ส่ง',
                  ),
                  onTap: () {
                    Navigator.pop(context); // ปิด bottom sheet
                    if (currentUserId == null) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                QRScannerPage(currentUserId: currentUserId!),
                      ),
                    ).then((success) {
                      if (success == true) {
                        // รีโหลดหน้าถ้ารับของเสร็จสิ้น
                        setState(() {});
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPostHeaderBanner(ColorScheme colorScheme) {
    if (widget.postId.isNotEmpty && relatedPost == null) {
      return Container(
        color: colorScheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: BrandedLoading(size: 20),
          ),
        ),
      );
    }
    if (widget.postId.isEmpty || relatedPost == null) {
      return const SizedBox.shrink();
    }

    final post = relatedPost!;
    return InkWell(
      onTap: () {
        if (post.status != 'deleted') {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => PostDetailSheet(post: post),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('ไม่สามารถดูรายละเอียดได้ (โพสต์ถูกลบ)'),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      },
      child: Container(
        color: colorScheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (post.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SmartNetworkImage(
                  imageUrl: post.imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.image_not_supported,
                  color: colorScheme.onPrimary.withOpacity(0.5),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    post.isLostItem ? 'ของหาย' : 'เจอของ',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          post.isLostItem ? Colors.red[600] : Colors.green[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    String text,
    bool isMe,
    Timestamp? timestamp,
    ColorScheme colorScheme, {
    String type = 'text',
    String? imageUrl,
  }) {
    final timeStr =
        timestamp != null ? DateFormat('HH:mm').format(timestamp.toDate()) : '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding:
            type == 'image'
                ? const EdgeInsets.all(4) // ขอบน้อยลงสำหรับรูป
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color:
              type == 'image'
                  ? Colors.transparent
                  : (isMe ? colorScheme.primary : colorScheme.surface),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            if (!isMe && type != 'image')
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (type == 'image' && imageUrl != null)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImagePage(imageUrl: imageUrl),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                   child: SmartNetworkImage(
                    imageUrl: imageUrl,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Text(
                text,
                style: TextStyle(
                  color:
                      isMe ? colorScheme.onPrimaryFixed : colorScheme.onPrimary,
                  fontSize: 15,
                ),
              ),
            if (timeStr.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 4, left: 4),
                child: Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        type == 'image'
                            ? colorScheme.onPrimary.withOpacity(0.6)
                            : (isMe
                                ? colorScheme.onPrimaryFixed.withOpacity(0.7)
                                : colorScheme.onPrimary.withOpacity(0.5)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBottomBar(ColorScheme colorScheme) {
    if (relatedPost != null &&
        (relatedPost!.status == 'resolved' ||
            relatedPost!.status == 'deleted')) {
      return Container(
        color: colorScheme.surface,
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Center(
          child: Text(
            'การสนทนาสิ้นสุดลงแล้ว เนื่องจากโพสต์ถูกปิดหรือส่งมอบสำเร็จ',
            style: TextStyle(
              color: colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Container(
      color: colorScheme.surface,
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.add_photo_alternate,
              color: colorScheme.primary,
              size: 28,
            ),
            onPressed: _isUploadingImage ? null : _sendImage,
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                style: TextStyle(color: colorScheme.onPrimary),
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'พิมพ์ข้อความ...',
                  hintStyle: TextStyle(
                    color: colorScheme.onPrimary.withOpacity(0.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: colorScheme.primary,
            radius: 22,
            child:
                _isUploadingImage
                    ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Center(
                        child: BrandedLoading(size: 20, color: Colors.white),
                      ),
                    )
                    : IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _sendMessage,
                    ),
          ),
        ],
      ),
    );
  }
}
