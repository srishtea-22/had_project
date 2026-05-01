import 'package:flutter/material.dart';
import '../models/timetable_entry.dart';
import '../models/subject.dart';
import '../services/timetable_service.dart';
import '../services/firebase_service.dart';

class TodayClassesWidget extends StatelessWidget {
  const TodayClassesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final timetableService = TimetableService();
    final firebaseService = FirebaseService();

    return StreamBuilder<List<TimetableEntry>>(
      stream: timetableService.todayStream(),
      builder: (context, snap) {
        final entries = snap.data ?? [];
        if (entries.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.today,
                      size: 16, color: Color(0xFF6C63FF)),
                  const SizedBox(width: 6),
                  const Text("Today's Classes",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6C63FF))),
                  const Spacer(),
                  Text('${entries.length} class${entries.length == 1 ? '' : 'es'}',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.white38)),
                ],
              ),
            ),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: entries.length,
                itemBuilder: (_, i) {
                  final entry = entries[i];
                  return StreamBuilder<List<Subject>>(
                    stream: firebaseService.subjectsStream(),
                    builder: (context, subSnap) {
                      final subjects = subSnap.data ?? [];
                      final subject = subjects
                          .where((s) => s.id == entry.subjectId)
                          .firstOrNull;

                      return _ClassChip(
                        entry: entry,
                        subject: subject,
                        onMark: (isPresent) async {
                          if (subject == null) return;
                          if (isPresent) {
                            subject.present++;
                          } else {
                            subject.absent++;
                          }
                          await firebaseService.updateSubject(subject);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isPresent
                                    ? '✅ Marked present for ${entry.subjectName}'
                                    : '❌ Marked absent for ${entry.subjectName}'),
                                backgroundColor: isPresent
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFEF5350),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: Colors.white12),
            ),
          ],
        );
      },
    );
  }
}

class _ClassChip extends StatelessWidget {
  final TimetableEntry entry;
  final Subject? subject;
  final void Function(bool isPresent) onMark;

  const _ClassChip(
      {required this.entry, required this.subject, required this.onMark});

  bool get _isPast {
    final now = DateTime.now();
    final classTime =
        DateTime(now.year, now.month, now.day, entry.hour, entry.minute);
    return now.isAfter(classTime);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: _isPast
                ? Colors.white12
                : const Color(0xFF6C63FF).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            entry.subjectName,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _isPast ? Colors.white38 : Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
          Text(entry.timeLabel,
              style: const TextStyle(fontSize: 11, color: Colors.white38)),
          Row(
            children: [
              _markBtn(true),
              const SizedBox(width: 6),
              _markBtn(false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _markBtn(bool present) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onMark(present),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: present
                ? const Color(0xFF4CAF50).withOpacity(0.15)
                : const Color(0xFFEF5350).withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Icon(
              present ? Icons.check : Icons.close,
              size: 14,
              color: present
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFEF5350),
            ),
          ),
        ),
      ),
    );
  }
}