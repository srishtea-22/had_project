class Subject {
  final String id;
  final String name;
  int present;
  int absent;

  Subject({
    required this.id,
    required this.name,
    required this.present,
    required this.absent,
  });

  int get total => present + absent;

  double get percentage => total == 0 ? 0 : (present / total) * 100;

  static const double required = 85.0;

  bool get isMet => percentage >= required;

  int get classesCanMiss {
    if (!isMet) return 0;
    return ((present - (required / 100) * total) / (required / 100)).floor();
  }

  int get classesNeeded {
    if (isMet) return 0;
    return (((required / 100) * total - present) / (1 - required / 100)).ceil();
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'present': present,
        'absent': absent,
      };

  factory Subject.fromMap(String id, Map<String, dynamic> map) => Subject(
        id: id,
        name: map['name'] ?? '',
        present: map['present'] ?? 0,
        absent: map['absent'] ?? 0,
      );
}