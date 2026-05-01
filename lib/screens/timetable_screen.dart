import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/timetable_entry.dart';
import '../models/subject.dart';
import '../services/timetable_service.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final _timetableService = TimetableService();
  final _firebaseService = FirebaseService();

  static const _days = [
    '', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
  ];

  static const _dayColors = [
    Colors.transparent,
    Color(0xFF6C63FF),
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF00BCD4),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        title: const Text('Timetable'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddSheet,
            tooltip: 'Add class',
          )
        ],
      ),
      body: StreamBuilder<List<TimetableEntry>>(
        stream: _timetableService.entriesStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
          }

          final entries = snap.data ?? [];

          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 64, color: Colors.white.withOpacity(0.15)),
                  const SizedBox(height: 16),
                  Text('No classes added yet',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4), fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Tap + to add your timetable',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.25), fontSize: 13)),
                ],
              ),
            );
          }

          // Group by weekday
          final grouped = <int, List<TimetableEntry>>{};
          for (final e in entries) {
            grouped.putIfAbsent(e.weekday, () => []).add(e);
          }
          // Sort each day's entries by time
          for (final list in grouped.values) {
            list.sort((a, b) =>
                (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
          }

          final sortedDays = grouped.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100, top: 8),
            itemCount: sortedDays.length,
            itemBuilder: (_, i) {
              final day = sortedDays[i];
              final dayEntries = grouped[day]!;
              final color = _dayColors[day];
              final isToday = DateTime.now().weekday == day;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _days[day],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isToday ? color : Colors.white70,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('Today',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: color,
                                    fontWeight: FontWeight.w600)),
                          )
                        ],
                        const Spacer(),
                        Text('${dayEntries.length} class${dayEntries.length == 1 ? '' : 'es'}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white38)),
                      ],
                    ),
                  ),
                  ...dayEntries.map((entry) => _EntryTile(
                        entry: entry,
                        color: color,
                        onDelete: () async {
                          await _timetableService.deleteEntry(entry.id);
                          await NotificationService.cancelReminder(entry.id);
                        },
                      )),
                  const SizedBox(height: 4),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Class',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showAddSheet() async {
    // Fetch subjects for dropdown
    final subjects = await _firebaseService.subjectsStream().first;
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddEntrySheet(
        subjects: subjects,
        onAdd: (entry) async {
          await _timetableService.addEntry(entry);
          await NotificationService.scheduleClassReminder(entry);
        },
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final TimetableEntry entry;
  final Color color;
  final VoidCallback onDelete;

  const _EntryTile(
      {required this.entry, required this.color, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Colors.red.shade800,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(entry.timeLabel.split(' ')[0],
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.subjectName,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(entry.timeLabel,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.white54)),
                ],
              ),
            ),
            Icon(Icons.notifications_active_outlined,
                size: 16, color: color.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}

class _AddEntrySheet extends StatefulWidget {
  final List<Subject> subjects;
  final Future<void> Function(TimetableEntry) onAdd;

  const _AddEntrySheet({required this.subjects, required this.onAdd});

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  Subject? _selectedSubject;
  int _selectedDay = 1;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _loading = false;

  static const _days = [
    '', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24, right: 24, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          const Text('Add Class to Timetable',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Subject picker
          const Text('Subject', style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF12122A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Subject>(
                value: _selectedSubject,
                isExpanded: true,
                dropdownColor: const Color(0xFF1C1C2E),
                hint: const Text('Select subject',
                    style: TextStyle(color: Colors.white38)),
                items: widget.subjects
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.name),
                        ))
                    .toList(),
                onChanged: (s) => setState(() => _selectedSubject = s),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Day picker
          const Text('Day', style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(6, (i) {
                final day = i + 1;
                final selected = _selectedDay == day;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = day),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF6C63FF)
                          : const Color(0xFF12122A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: selected
                              ? const Color(0xFF6C63FF)
                              : Colors.white12),
                    ),
                    child: Text(
                      _days[day].substring(0, 3),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : Colors.white54),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          // Time picker
          const Text('Time', style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
                builder: (context, child) => Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                        primary: Color(0xFF6C63FF)),
                  ),
                  child: child!,
                ),
              );
              if (t != null) setState(() => _selectedTime = t);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF12122A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time,
                      color: Color(0xFF6C63FF), size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _selectedTime.format(context),
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.white38),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Add & Schedule Reminder',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a subject')));
      return;
    }

    setState(() => _loading = true);

    final entry = TimetableEntry(
      id: '',
      subjectId: _selectedSubject!.id,
      subjectName: _selectedSubject!.name,
      weekday: _selectedDay,
      hour: _selectedTime.hour,
      minute: _selectedTime.minute,
    );

    await widget.onAdd(entry);
    if (mounted) Navigator.pop(context);
  }
}