class TimeFormatter {
  static String getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);

    if (diff.inDays >= 365) {
      final years = (diff.inDays / 365).floor();
      return '$years ปีที่แล้ว';
    }

    if (diff.inDays >= 30) {
      final months = (diff.inDays / 30).floor();
      return '$months เดือนที่แล้ว';
    }

    if (diff.inDays > 0) return '${diff.inDays} วันที่แล้ว';
    if (diff.inHours > 0) return '${diff.inHours} ชม. ที่แล้ว';
    if (diff.inMinutes > 0) return '${diff.inMinutes} นาทีที่แล้ว';
    return 'เมื่อสักครู่';
  }
}
