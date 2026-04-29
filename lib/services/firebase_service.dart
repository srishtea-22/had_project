import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';

class FirebaseService {
  final _col = FirebaseFirestore.instance.collection('subjects');

  Stream<List<Subject>> subjectsStream() {
    return _col.orderBy('name').snapshots().map(
          (snap) => snap.docs
              .map((doc) => Subject.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> addSubject(Subject subject) async {
    await _col.add(subject.toMap());
  }

  Future<void> updateSubject(Subject subject) async {
    await _col.doc(subject.id).update({
      'present': subject.present,
      'absent': subject.absent,
    });
  }

  Future<void> deleteSubject(String id) async {
    await _col.doc(id).delete();
  }
}