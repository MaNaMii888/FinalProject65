import 'package:google_maps_flutter/google_maps_flutter.dart';

class BuildingPoint {
  final String id;
  final String name;
  final String fullName;
  final LatLng center; // จุดกึ่งกลางสำหรับปักหมุดแจ้งเตือนของหาย/เจอของ

  BuildingPoint({
    required this.id,
    required this.name,
    this.fullName = '',
    required this.center,
  });

  String get displayFullName => fullName.isNotEmpty ? fullName : name;
}

class BuildingPointData {
  // ใส่พิกัด Lat/Lng กึ่งกลางตึกที่คุณหามาได้จาก Google Maps ลงในนี้ให้ครบทุกตึก
  static List<BuildingPoint> getCampusBuildings() {
    return [
      BuildingPoint(
        id: '1, โรงอาหาร',
        name: 'อาคาร 1',
        fullName: 'อาคารสมเด็จเจ้าพระยาบรมมหาศรีสุริยวงศ์',
        center: const LatLng(
          13.732486613252691,
          100.49018908964632,
        ), // พิกัดที่คุณหามา
      ),
      BuildingPoint(
        id: '2',
        name: 'อาคาร 2',
        fullName: 'อาคารเรียนรวม',
        center: const LatLng(
          13.731980489652452,
          100.49060664561752,
        ), // พิกัดที่คุณหามา
      ),
      BuildingPoint(
        id: '3',
        name: 'อาคาร 3',
        fullName: 'อาคารเรียนรวม',
        center: const LatLng(
          13.732199908091697,
          100.49001893059564,
        ), // พิกัดที่คุณหามา
      ),
      BuildingPoint(
        id: '4',
        name: 'อาคาร 4',
        fullName: 'อาคารเรียนรวม',
        center: const LatLng(
          13.731822104429915,
          100.49046149508014,
        ), // พิกัดที่คุณหามา
      ),
      BuildingPoint(
        id: '5',
        name: 'อาคาร 5',
        fullName: 'สำนักงานอธิการบดีวิชาการและทะเบียน',
        center: const LatLng(
          13.731415030063298,
          100.49074614315353,
        ), // พิกัดที่คุณหามา
      ),
      BuildingPoint(
        id: '6',
        name: 'อาคาร 6',
        fullName: 'อาคาร 100 ปี ศรีสุริยวงศ์(อาคารบริหาร)',
        center: const LatLng(
          13.731408457540125,
          100.49106358151366,
        ), // พิกัดที่คุณหามา
      ),
      BuildingPoint(
        id: '7',
        name: 'อาคาร 7',
        fullName: 'คณะวิทยาการจัดการ',
        center: const LatLng(
          13.73111012196978,
          100.49128888705968,
        ), // พิกัดที่คุณหามา
      ),
      BuildingPoint(
        id: '8, ห้องสมุด',
        name: 'อาคาร 8',
        fullName: 'สำนักวิทยบริการและเทคโนโลยีสารสนเทศ',
        center: const LatLng(
          13.73175326177798,
          100.49109935563081,
        ), // พิกัดที่คุณหามา
      ),
      BuildingPoint(
        id: '9',
        name: 'อาคาร 9',
        fullName: 'สำนักวิทยบริการและเทคโนโลยีสารสนเทศ',
        center: const LatLng(
          13.732482983388122,
          100.4905453039174,
        ), // พิกัดที่คุณหามา
      ),
      BuildingPoint(
        id: '10',
        name: 'อาคาร 10',
        fullName: 'สำนักงานคอมพิวเตอร์/สำนักวินาศสัมพันธ์ละเครือข่ายอาเซียน',
        center: const LatLng(
          13.732803464248342,
          100.49028915294154,
        ), // พิกัดที่คุณหามา
      ),
      BuildingPoint(
        id: '11',
        name: 'อาคาร 11',
        fullName: 'บัณฑิตวิทยาลัย',
        center: const LatLng(
          13.73313333887971,
          100.4899877372875,
        ), // พิกัดที่คุณหามา
      ),
      BuildingPoint(
        id: '12',
        name: 'อาคาร 12',
        fullName: 'อาคารเรียนรวม',
        center: const LatLng(
          13.732662908708164,
          100.48949720566019,
        ), // พิกัดที่คุณหามา
      ),
      BuildingPoint(
        id: '15',
        name: 'อาคาร 15',
        fullName: 'สระว่ายน้ำ',
        center: const LatLng(
          13.733006878893656,
          100.48870211872597,
        ), // พิกัดที่คุณหามา
      ),
      BuildingPoint(
        id: '16',
        name: 'อาคาร 16',
        fullName: 'สำนักศิลปะและวัฒนธรรม/แหล่งการเรียนรู้กรุงธนบุรีศึกษา',
        center: const LatLng(
          13.732786956389164,
          100.48843505512149,
        ), // พิกัดที่คุณหามา
      ),
      BuildingPoint(
        id: '17',
        name: 'อาคาร 17',
        fullName: 'คณะมนุษยศาสตร์และสังคมศาสตร์',
        center: const LatLng(
          13.732602507476958,
          100.48884308817094,
        ), // พิกัดที่คุณหามา
      ),
      BuildingPoint(
        id: '18',
        name: 'อาคาร 18',
        fullName: 'โรงเรียนสาธิตมหาวิทยาลัยราชภัฏบ้านสมเด็จเจ้าพระยา',
        center: const LatLng(
          13.732024197404002,
          100.48859936376962,
        ), // พิกัดที่คุณหามา
      ),
      BuildingPoint(
        id: '19',
        name: 'อาคาร 19',
        fullName: 'อาคารสุริยาคาร',
        center: const LatLng(
          13.732080555509173,
          100.48886328780772,
        ), // พิกัดที่คุณหามา
      ),
      BuildingPoint(
        id: '20',
        name: 'อาคาร 20',
        fullName: 'อาคารเรียนรวม/หอพักนักศึกษานานาชาติ',
        center: const LatLng(
          13.731872559291503,
          100.48868755081483,
        ), // พิกัดที่คุณหามา
      ),
      BuildingPoint(
        id: '22',
        name: 'อาคาร 22',
        fullName: 'อาคารชงโค',
        center: const LatLng(
          13.73163618011035,
          100.48830970820077,
        ), // พิกัดที่คุณหามา
      ),
      BuildingPoint(
        id: '24',
        name: 'อาคาร 24',
        fullName: 'อาคารสมเด็จพระพุทธาจารย์(นวม)',
        center: const LatLng(
          13.731479201550853,
          100.48813397120963,
        ), // พิกัดที่คุณหามา
      ),
      BuildingPoint(
        id: '26',
        name: 'อาคาร 26',
        fullName: 'บ้านเอกะนาค/พิพิทภัณฑ์ท้องถิ่นฝั่งรนบุรี',
        center: const LatLng(
          13.731369316494964,
          100.4876754390349,
        ), // พิกัดที่คุณหามา
      ),
      BuildingPoint(
        id: '27',
        name: 'อาคาร 27',
        fullName: 'วิทยาลัยการดนตรี ',
        center: const LatLng(
          13.731793158562866,
          100.48804913264374,
        ), // พิกัดที่คุณหามา
      ),
      BuildingPoint(
        id: '28',
        name: 'อาคาร 28',
        fullName: 'โรงฝึกประสบการณ์วิชาชีพวิศวกรรม',
        center: const LatLng(
          13.731521301564225,
          100.48868396478308,
        ), // พิกัดที่คุณหามา
      ),
      BuildingPoint(
        id: '29',
        name: 'อาคาร 29',
        fullName: 'ศูนย์สาธิตการศึกษาปฐมวัย',
        center: const LatLng(
          13.731995268174535,
          100.48765927929482,
        ), // พิกัดที่คุณหามา
      ),
      BuildingPoint(
        id: '30',
        name: 'อาคาร 30',
        fullName: 'คณะครุศาสตร์',
        center: const LatLng(
          13.73235043123215,
          100.4875643409066,
        ), // พิกัดที่คุณหามา
      ),
      BuildingPoint(
        id: '32',
        name: 'อาคาร 32',
        fullName: 'อาคารสันทนาการด้านกีฬา',
        center: const LatLng(
          13.732623759145834,
          100.48749701150783,
        ), // พิกัดที่คุณหามา
      ),
      BuildingPoint(
        id: 'lobby',
        name: 'สนาม',
        fullName: 'สนามฟุตบอล',
        center: const LatLng(
          13.732427622731654,
          100.48806693270356,
        ), // พิกัดที่คุณหามา
      ),
    ];
  }
}
