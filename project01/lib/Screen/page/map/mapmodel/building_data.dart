// models/building_data.dart
import 'package:flutter/foundation.dart';
import 'package:project01/models/post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomData {
  final String roomId;
  final String roomName;
  final String buildingId;
  final List<Post> posts;
  final int lostItemCount;
  final int foundItemCount;

  RoomData({
    required this.roomId,
    required this.roomName,
    required this.buildingId,
    this.posts = const [],
  }) : lostItemCount = posts.where((post) => post.isLostItem).length,
       foundItemCount = posts.where((post) => !post.isLostItem).length;

  RoomData copyWith({
    String? roomId,
    String? roomName,
    String? buildingId,
    List<Post>? posts,
  }) {
    return RoomData(
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      buildingId: buildingId ?? this.buildingId,
      posts: posts ?? this.posts,
    );
  }
}

class Room {
  final dynamic id; // Can be int or String ('food', 'library')
  final String name;
  final String type;
  final RoomData? roomData; // เพิ่มข้อมูลห้องที่เชื่อมโยงกับโพสต์

  Room({
    required this.id,
    required this.name,
    required this.type,
    this.roomData,
  });

  // สร้าง Room จาก RoomData
  factory Room.fromRoomData(RoomData roomData, String type) {
    return Room(
      id: roomData.roomId,
      name: roomData.roomName,
      type: type,
      roomData: roomData,
    );
  }
}

class Building {
  final String name;
  final List<Room> rooms;

  Building({required this.name, required this.rooms});
}

// Service class สำหรับดึงข้อมูลโพสต์ตามห้อง
class BuildingDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ดึงข้อมูลโพสต์สำหรับห้องเฉพาะ
  static Future<RoomData> getRoomData(
    String buildingId,
    String roomId,
    String roomName,
  ) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('lost_found_items')
              .where('building', isEqualTo: buildingId)
              .where('location', isEqualTo: roomId)
              .orderBy('createdAt', descending: true)
              .get();

      final posts =
          querySnapshot.docs
              .map((doc) => Post.fromJson({...doc.data(), 'id': doc.id}))
              .toList();

      return RoomData(
        roomId: roomId,
        roomName: roomName,
        buildingId: buildingId,
        posts: posts,
      );
    } catch (e) {
      debugPrint('Error fetching room data: $e');
      return RoomData(
        roomId: roomId,
        roomName: roomName,
        buildingId: buildingId,
        posts: [],
      );
    }
  }

  // ดึงข้อมูลโพสต์สำหรับอาคารทั้งหมด
  static Future<Map<String, Building>> getBuildingDataWithPosts() async {
    try {
      final Map<String, Building> updatedBuildingData = {};

      for (final entry in buildingData.entries) {
        final buildingId = entry.key;
        final building = entry.value;
        final List<Room> updatedRooms = [];

        for (final room in building.rooms) {
          final roomData = await getRoomData(
            buildingId,
            room.id.toString(),
            room.name,
          );

          updatedRooms.add(
            Room(
              id: room.id,
              name: room.name,
              type: room.type,
              roomData: roomData,
            ),
          );
        }

        updatedBuildingData[buildingId] = Building(
          name: building.name,
          rooms: updatedRooms,
        );
      }

      return updatedBuildingData;
    } catch (e) {
      debugPrint('Error fetching building data with posts: $e');
      return buildingData;
    }
  }

  // ดึงข้อมูลโพสต์สำหรับห้องเดียว
  static Future<List<Post>> getPostsForRoom(
    String buildingId,
    String roomId,
  ) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('lost_found_items')
              .where('building', isEqualTo: buildingId)
              .where('location', isEqualTo: roomId)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => Post.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error fetching posts for room: $e');
      return [];
    }
  }
}

Map<String, Building> buildingData = {
  'A': Building(
    name: 'Zone A', // เปลี่ยนจาก 'อาคาร A' เป็น 'Zone A'
    rooms: [
      Room(id: 1, name: 'อาคาร 1', type: 'classroom'),
      Room(id: 2, name: 'อาคาร 2', type: 'classroom'),
      Room(id: 3, name: 'อาคาร 3', type: 'classroom'),
      Room(id: 4, name: 'อาคาร 4', type: 'classroom'),
      Room(id: 5, name: 'อาคาร 5', type: 'classroom'),
      Room(id: 6, name: 'อาคาร 6', type: 'classroom'),
      Room(id: 7, name: 'อาคาร 7', type: 'classroom'),
      Room(id: 8, name: 'อาคาร 8', type: 'classroom'),
      Room(id: 9, name: 'อาคาร 9', type: 'classroom'),
      Room(id: 10, name: 'อาคาร 10', type: 'classroom'),
      Room(id: 11, name: 'อาคาร 11', type: 'classroom'),
      Room(id: 12, name: 'อาคาร 12', type: 'classroom'),
      Room(id: 'food', name: 'โรงอาหาร', type: 'food'),
      Room(id: 'library', name: 'ห้องสมุด', type: 'library'),
      Room(id: 'office', name: 'สำนักงาน', type: 'office'),
    ],
  ),
  'B': Building(
    name: 'Zone B', // เปลี่ยนจาก 'อาคาร B' เป็น 'Zone B'
    rooms: [
      Room(id: 15, name: 'อาคาร 15', type: 'classroom'),
      Room(id: 16, name: 'อาคาร 16', type: 'classroom'),
      Room(id: 17, name: 'อาคาร 17', type: 'classroom'),
      Room(id: 18, name: 'อาคาร 18', type: 'classroom'),
      Room(id: 19, name: 'อาคาร 19', type: 'classroom'),
      Room(id: 20, name: 'อาคาร 20', type: 'classroom'),
      Room(id: 22, name: 'อาคาร 22', type: 'classroom'),
      Room(id: 24, name: 'อาคาร 24', type: 'classroom'),
      Room(id: 26, name: 'อาคาร 26', type: 'classroom'),
      Room(id: 27, name: 'อาคาร 27', type: 'classroom'),
      Room(id: 28, name: 'อาคาร 28', type: 'classroom'),
      Room(id: 29, name: 'อาคาร 29', type: 'classroom'),
      Room(id: 30, name: 'อาคาร 30', type: 'classroom'),
      Room(id: 31, name: 'อาคาร 31', type: 'classroom'),
      Room(id: 33, name: 'อาคาร 33', type: 'classroom'),
      Room(id: 'lobby', name: 'สนาม', type: 'lobby'),
    ],
  ),
};
