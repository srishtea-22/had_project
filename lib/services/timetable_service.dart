import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/timetable_entry.dart';

class TimetableService {
  final _col = FirebaseFirestore.instance.collection('timetable');

  Stream<List<TimetableEntry>> entriesStream() {
    return _col
        .orderBy('weekday')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => TimetableEntry.fromMap(d.id, d.data()))
            .toList());
  }

  /// Returns only today's entries sorted by time
  Stream<List<TimetableEntry>> todayStream() {
    final today = DateTime.now().weekday; // 1=Mon...6=Sat
    return _col
        .where('weekday', isEqualTo: today)
        .orderBy('hour')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => TimetableEntry.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> addEntry(TimetableEntry entry) async {
    await _col.add(entry.toMap());
  }

  Future<void> deleteEntry(String id) async {
    await _col.doc(id).delete();
  }
}