class TimetableEntry {
  final String id;
  final String subjectId;
  final String subjectName;
  final int weekday; // 1=Monday ... 6=Saturday
  final int hour;   // 24h
  final int minute;

  TimetableEntry({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.weekday,
    required this.hour,
    required this.minute,
  });

  String get timeLabel {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  String get dayName => [
        '', 'Monday', 'Tuesday', 'Wednesday',
        'Thursday', 'Friday', 'Saturday'
      ][weekday];

  Map<String, dynamic> toMap() => {
        'subjectId': subjectId,
        'subjectName': subjectName,
        'weekday': weekday,
        'hour': hour,
        'minute': minute,
      };

  factory TimetableEntry.fromMap(String id, Map<String, dynamic> m) =>
      TimetableEntry(
        id: id,
        subjectId: m['subjectId'] ?? '',
        subjectName: m['subjectName'] ?? '',
        weekday: m['weekday'] ?? 1,
        hour: m['hour'] ?? 9,
        minute: m['minute'] ?? 0,
      );
}