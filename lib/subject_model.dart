class Subject {
  String id;
  String name;
  int present;
  int absent;

  Subject({required this.id, required this.name, this.present = 0, this.absent = 0});

  int get total => present + absent;
  double get percentage => total == 0 ? 0.0 : (present / total) * 100;

  String getStatus() {
    const double target = 85.0;
    if (total == 0) return "Add your first class!";
    
    if (percentage >= target) {
      int canMiss = (present / 0.85).floor() - total;
      return canMiss > 0 ? "Safe to miss: $canMiss classes" : "On the edge! Don't miss any classes.";
    } else {
      int toAttend = ((0.85 * total - present) / 0.15).ceil();
      return "Attend next $toAttend classes to meet the criteria.";
    }
  }
}