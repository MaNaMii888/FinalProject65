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
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? json['detail'] ?? '',
      contact: json['contact'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      building: json['building'] ?? '',
      location: json['location'] ?? json['room'] ?? '',
      category: json['category']?.toString() ?? '',
      isLostItem: json['isLostItem'] ?? true,
      status: json['status'] ?? '',
      createdAt:
          (json['createdAt'] is Timestamp)
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
                  DateTime.now(),
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
