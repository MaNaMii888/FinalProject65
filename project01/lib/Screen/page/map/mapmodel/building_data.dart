// models/building_data.dart
class Room {
  final dynamic id; // Can be int or String ('food', 'library')
  final String name;
  final String type;

  Room({required this.id, required this.name, required this.type});
}

class Building {
  final String name;
  final List<Room> rooms;

  Building({required this.name, required this.rooms});
}

Map<String, Building> buildingData = {
  'A': Building(
    name: 'อาคาร A',
    rooms: [
      Room(id: 1, name: 'ห้อง 1', type: 'classroom'),
      Room(id: 2, name: 'ห้อง 2', type: 'classroom'),
      Room(id: 3, name: 'ห้อง 3', type: 'classroom'),
      Room(id: 4, name: 'ห้อง 4', type: 'classroom'),
      Room(id: 5, name: 'ห้อง 5', type: 'classroom'),
      Room(id: 6, name: 'ห้อง 6', type: 'classroom'),
      Room(id: 7, name: 'ห้อง 7', type: 'classroom'),
      Room(id: 8, name: 'ห้อง 8', type: 'classroom'),
      Room(id: 9, name: 'ห้อง 9', type: 'classroom'),
      Room(id: 10, name: 'ห้อง 10', type: 'classroom'),
      Room(id: 11, name: 'ห้อง 11', type: 'classroom'),
      Room(id: 12, name: 'ห้อง 12', type: 'classroom'),
      Room(id: 'food', name: 'โรงอาหาร', type: 'food'),
      Room(id: 'library', name: 'ห้องสมุด', type: 'library'),
      Room(id: 'office', name: 'สำนักงาน', type: 'office')
    ],
  ),
  'B': Building(
    name: 'อาคาร B',
    rooms: [
      Room(id: 15, name: 'ห้อง 15', type: 'classroom'),
      Room(id: 16, name: 'ห้อง 16', type: 'classroom'),
      Room(id: 17, name: 'ห้อง 17', type: 'classroom'),
      Room(id: 18, name: 'ห้อง 18', type: 'classroom'),
      Room(id: 19, name: 'ห้อง 19', type: 'classroom'),
      Room(id: 20, name: 'ห้อง 20', type: 'classroom'),
      Room(id: 22, name: 'ห้อง 22', type: 'classroom'),
      Room(id: 24, name: 'ห้อง 24', type: 'classroom'),
      Room(id: 26, name: 'ห้อง 26', type: 'classroom'),
      Room(id: 27, name: 'ห้อง 27', type: 'classroom'),
      Room(id: 28, name: 'ห้อง 28', type: 'classroom'),
      Room(id: 29, name: 'ห้อง 29', type: 'classroom'),
      Room(id: 30, name: 'ห้อง 30', type: 'classroom'),
      Room(id: 31, name: 'ห้อง 31', type: 'classroom'),
      Room(id: 33, name: 'ห้อง 33', type: 'classroom'),
      Room(id: 'lobby', name: 'ล็อบบี้', type: 'lobby')
    ],
  ),
};