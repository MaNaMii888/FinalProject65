import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

class Post {
  final String id;
  final String userId;
  final String userName;
  final String title;
  final String description;
  final String imageUrl;
  final String location;
  final String building;
  final DateTime createdAt;
  final bool isLostItem;
  final String status;
  final String category;
  final String contact;

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    required this.title,
    required this.description,
    this.imageUrl = '',
    required this.location,
    required this.building,
    required this.createdAt,
    required this.isLostItem,
    this.status = 'open',
    required this.category,
    required this.contact,
  });

  // เพิ่ม factory constructor สำหรับแปลง JSON
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String? ?? '',
      location: json['location'] as String,
      building: json['building'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      isLostItem: json['isLostItem'] as bool,
      status: json['status'] as String? ?? 'open',
      category: json['category'] as String,
      contact: json['contact'] as String,
    );
  }

  // เพิ่ม method สำหรับแปลงเป็น JSON (อาจต้องใช้ตอนบันทึกข้อมูล)
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'title': title,
    'description': description,
    'imageUrl': imageUrl,
    'location': location,
    'building': building,
    'createdAt': Timestamp.fromDate(createdAt),
    'isLostItem': isLostItem,
    'status': status,
    'category': category,
    'contact': contact,
  };

  String getTimeAgo() {
    timeago.setLocaleMessages('th', timeago.ThMessages());
    return timeago.format(createdAt, locale: 'th');
  }
}
