// // [Senior Note]: ตอนนี้ระบบ Notification สลับไปใช้ `smart_notification_popup.dart` แทนหน้านี้แล้ว
// // โค้ดในไฟล์นี้เป็นเวอร์ชันเก่าที่ไม่ได้ถูกเรียกใช้งานแล้วแบบ 100%
// // ** สามารถลบไฟล์ `notification_screen.dart` นี้ทิ้งได้เลยครับ **
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:project01/services/notifications_service.dart';
// import 'package:project01/utils/time_formatter.dart';

// class SmartNotificationScreen extends StatefulWidget {
//   const SmartNotificationScreen({super.key});

//   @override
//   State<SmartNotificationScreen> createState() =>
//       _SmartNotificationScreenState();
// }

// class _SmartNotificationScreenState extends State<SmartNotificationScreen> {
//   final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

//   @override
//   Widget build(BuildContext context) {
//     final statusBarHeight = MediaQuery.of(context).padding.top;
//     final topPadding = (statusBarHeight * 0.3).clamp(8.0, 20.0);

//     // ดึงสีจาก Theme
//     final primaryColor = Theme.of(context).colorScheme.primary;
//     final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

//     return Scaffold(
//       backgroundColor: primaryColor, // ✅ พื้นหลังสี Primary (เข้ม)
//       body: Column(
//         children: [
//           SizedBox(height: topPadding),
//           // Header
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
//             decoration: BoxDecoration(color: primaryColor),
//             child: Row(
//               children: [
//                 IconButton(
//                   onPressed: () => Navigator.pop(context),
//                   icon: Icon(Icons.arrow_back, color: onPrimaryColor),
//                 ),
//                 const SizedBox(width: 8),
//                 Icon(
//                   Icons.notifications_active,
//                   color: onPrimaryColor,
//                   size: 28,
//                 ),
//                 const SizedBox(width: 12),
//                 Text(
//                   'รายการที่ตรงกัน',
//                   style: TextStyle(
//                     color: onPrimaryColor,
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     fontFamily: 'Prompt',
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Divider
//           Divider(height: 1, color: onPrimaryColor.withOpacity(0.2)),

//           // Content
//           Expanded(child: _buildNotificationList(onPrimaryColor)),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyState(Color textColor) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.check_circle_outline,
//             size: 80,
//             color: textColor.withOpacity(0.5),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'ไม่มีรายการที่ตรงกันในขณะนี้',
//             style: TextStyle(
//               fontSize: 18,
//               color: textColor.withOpacity(0.7),
//               fontFamily: 'Prompt',
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildNotificationList(Color onPrimaryColor) {
//     if (currentUserId == null) {
//       return _buildEmptyState(onPrimaryColor);
//     }

//     return StreamBuilder<List<NotificationModel>>(
//       stream: NotificationService.getUserNotifications(currentUserId!),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(
//             child: CircularProgressIndicator(color: onPrimaryColor),
//           );
//         }

//         final items =
//             snapshot.data?.where((n) => n.type == 'smart_match').toList() ?? [];

//         if (items.isEmpty) {
//           return _buildEmptyState(onPrimaryColor);
//         }

//         return ListView.builder(
//           padding: EdgeInsets.zero, // ชิดขอบจอ
//           itemCount: items.length,
//           itemBuilder: (context, index) {
//             return _buildNotificationCard(items[index]);
//           },
//         );
//       },
//     );
//   }

//   // ✅ ปรับ UI เป็นสไตล์ X (Feed เต็มจอ)
//   Widget _buildNotificationCard(NotificationModel notification) {
//     final matchScore = notification.matchScore ?? 0;
//     final matchPercentage = (matchScore * 100).round();

//     final primaryColor = Theme.of(context).colorScheme.primary;
//     final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

//     return InkWell(
//       onTap: () {
//         _showContactDialog(notification);
//       },
//       child: Container(
//         // ✅ พื้นหลังสี Primary + เส้นคั่นล่าง
//         decoration: BoxDecoration(
//           color: primaryColor,
//           border: Border(
//             bottom: BorderSide(
//               color: onPrimaryColor.withOpacity(0.2),
//               width: 0.5,
//             ),
//           ),
//         ),
//         padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header: คะแนน + เวลา
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 10,
//                     vertical: 4,
//                   ),
//                   decoration: BoxDecoration(
//                     color: _getMatchColor(matchScore),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     '$matchPercentage% ตรงกัน',
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 Text(
//                   TimeFormatter.getTimeAgo(notification.createdAt),
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: onPrimaryColor.withOpacity(0.6),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),

//             // Content: Avatar + Text
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Avatar Image
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: Container(
//                     width: 50,
//                     height: 50,
//                     color: onPrimaryColor.withOpacity(0.1),
//                     child:
//                         (notification.postImageUrl ?? '').isNotEmpty
//                             ? Image.network(
//                               notification.postImageUrl!,
//                               fit: BoxFit.cover,
//                             )
//                             : Icon(
//                               notification.postType == 'lost'
//                                   ? Icons.help_outline
//                                   : Icons.check_circle_outline,
//                               color:
//                                   notification.postType == 'lost'
//                                       ? Colors.red[300]
//                                       : Colors.green[300],
//                               size: 28,
//                             ),
//                   ),
//                 ),
//                 const SizedBox(width: 16),

//                 // Title & Description
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         notification.postTitle ?? notification.title,
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: onPrimaryColor, // สี onPrimary
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         notification.message,
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: onPrimaryColor.withOpacity(0.8),
//                         ),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),

//             // Match Reasons (กล่องเหตุผล)
//             if (notification.matchReasons.isNotEmpty)
//               Container(
//                 margin: const EdgeInsets.only(
//                   top: 12,
//                   left: 66,
//                 ), // เว้นซ้ายให้ตรงข้อความ
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: onPrimaryColor.withOpacity(0.05),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: onPrimaryColor.withOpacity(0.1)),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'เหตุผลที่แจ้งเตือน:',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 12,
//                         color: onPrimaryColor,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     ...notification.matchReasons.map(
//                       (r) => Text(
//                         '• $r',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: onPrimaryColor.withOpacity(0.7),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//             const SizedBox(height: 12),

//             // Action Buttons (ใช่/ไม่ใช่)
//             Padding(
//               padding: const EdgeInsets.only(left: 66),
//               child: Row(
//                 children: [
//                   // ปุ่ม ไม่ใช่
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: () => _showRejectDialog(notification),
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: onPrimaryColor,
//                         side: BorderSide(
//                           color: onPrimaryColor.withOpacity(0.5),
//                         ),
//                         padding: const EdgeInsets.symmetric(vertical: 8),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                       ),
//                       child: const Text(
//                         'ไม่ใช่',
//                         style: TextStyle(fontSize: 12),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   // ปุ่ม ใช่ (ติดต่อ)
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       onPressed: () => _showConfirmContactDialog(notification),
//                       icon: const Icon(Icons.chat_bubble_outline, size: 16),
//                       label: const Text(
//                         'ยืนยัน',
//                         style: TextStyle(fontSize: 12),
//                       ),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 8),
//                         elevation: 0,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ---------- Helper Functions (แก้จุดแดง) ----------

//   Color _getMatchColor(double score) {
//     if (score >= 0.8) return Colors.green;
//     if (score >= 0.7) return Colors.orange;
//     return Colors.blue;
//   }

//   void _removeNotification(String notificationId) async {
//     try {
//       await NotificationService.deleteNotification(notificationId);
//     } catch (e) {
//       debugPrint('Error removing notification: $e');
//     }
//   }

//   void _showRejectDialog(NotificationModel notification) {
//     showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: const Text('ยืนยัน'),
//             content: const Text('รายการนี้จะถูกลบออกจากการแจ้งเตือน'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('ยกเลิก'),
//               ),
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   _removeNotification(notification.id);
//                 },
//                 child: const Text(
//                   'ยืนยัน',
//                   style: TextStyle(color: Colors.red),
//                 ),
//               ),
//             ],
//           ),
//     );
//   }

//   void _showConfirmContactDialog(NotificationModel notification) {
//     showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: const Text('ยืนยันการติดต่อ'),
//             content: const Text(
//               'ท่านได้ทำการติดต่อกับผู้พบ/ผู้ทำของหายแล้วใช่หรือไม่?',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('ยกเลิก'),
//               ),
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   NotificationService.deleteNotification(notification.id);
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('ยืนยันการติดต่อเรียบร้อย')),
//                   );
//                 },
//                 child: const Text(
//                   'ยืนยัน',
//                   style: TextStyle(color: Colors.green),
//                 ),
//               ),
//             ],
//           ),
//     );
//   }

//   void _showContactDialog(NotificationModel notification) {
//     showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: const Text('ข้อมูลติดต่อ'),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   notification.postTitle ?? 'ไม่ระบุสิ่งของ',
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Row(
//                   children: [
//                     Icon(
//                       notification.postType == 'lost'
//                           ? Icons.search
//                           : Icons.check_box,
//                       color: Colors.green,
//                       size: 16,
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       notification.postType == 'lost' ? 'ของหาย' : 'ของเจอ',
//                       style: const TextStyle(color: Colors.green, fontSize: 14),
//                     ),
//                   ],
//                 ),
//                 const Divider(height: 24),
//                 ListTile(
//                   contentPadding: EdgeInsets.zero,
//                   leading: const Icon(Icons.phone, color: Colors.green),
//                   title: Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           notification.data['contact'] ?? '-',
//                           style: const TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                       IconButton(
//                         icon: const Icon(
//                           Icons.copy,
//                           size: 20,
//                           color: Colors.grey,
//                         ),
//                         onPressed: () {
//                           Clipboard.setData(
//                             ClipboardData(
//                               text: notification.data['contact'] ?? '',
//                             ),
//                           );
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                               content: Text('คัดลอกเบอร์ติดต่อแล้ว'),
//                             ),
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                   subtitle: const Text('เบอร์โทร / Line ID'),
//                 ),
//                 if ((notification.data['location'] ?? '').isNotEmpty)
//                   ListTile(
//                     contentPadding: EdgeInsets.zero,
//                     leading: const Icon(
//                       Icons.location_on,
//                       color: Colors.orange,
//                     ),
//                     title: Text(notification.data['location']),
//                     subtitle: const Text('สถานที่'),
//                   ),
//               ],
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('ปิด'),
//               ),
//             ],
//           ),
//     );
//   }
// }
