import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/subject.dart';
import '../services/firebase_service.dart';

class SubjectCard extends StatefulWidget {
  final Subject subject;
  const SubjectCard({super.key, required this.subject});

  @override
  State<SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<SubjectCard> {
  late int present;
  late int absent;
  late Subject _calculated;
  final _service = FirebaseService();

  @override
  void initState() {
    super.initState();
    present = widget.subject.present;
    absent = widget.subject.absent;
    _calculated = widget.subject;
  }

  @override
  void didUpdateWidget(SubjectCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only sync from Firebase if the user hasn't locally modified the counts.
    // This prevents a newly added subject from overwriting another card's state.
    if (oldWidget.subject.id != widget.subject.id) {
      present = widget.subject.present;
      absent = widget.subject.absent;
      _calculated = widget.subject;
    }
  }

  void _calculate() {
    setState(() {
      _calculated = Subject(
        id: widget.subject.id,
        name: widget.subject.name,
        present: present,
        absent: absent,
      );
    });
    // save to firebase
    _service.updateSubject(_calculated);
  }

  void _increment(bool isPresent) {
    setState(() {
      if (isPresent) {
        present++;
      } else {
        absent++;
      }
    });
  }

  void _decrement(bool isPresent) {
    setState(() {
      if (isPresent) {
        if (present > 0) present--;
      } else {
        if (absent > 0) absent--;
      }
    });
  }

  Color get _statusColor {
    if (_calculated.isMet) return const Color(0xFF4CAF50);
    final pct = _calculated.percentage;
    if (pct >= 75) return const Color(0xFFFFB300);
    return const Color(0xFFEF5350);
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF1C1C2E),
                  title: const Text('Delete Subject'),
                  content: Text(
                      'Delete "${widget.subject.name}"? This cannot be undone.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirm == true) {
                _service.deleteSubject(widget.subject.id);
              }
            },
            backgroundColor: Colors.red.shade800,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _statusColor.withOpacity(0.4), width: 1.2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject name + percentage
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.subject.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_calculated.percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                          color: _statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  )
                ],
              ),

              const SizedBox(height: 4),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _calculated.total == 0
                      ? 0
                      : _calculated.percentage / 100,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation(_statusColor),
                  minHeight: 6,
                ),
              ),

              const SizedBox(height: 16),

              // Present / Absent counters
              Row(
                children: [
                  _Counter(
                    label: 'Present',
                    value: present,
                    color: const Color(0xFF4CAF50),
                    onIncrement: () => _increment(true),
                    onDecrement: () => _decrement(true),
                  ),
                  const SizedBox(width: 16),
                  _Counter(
                    label: 'Absent',
                    value: absent,
                    color: const Color(0xFFEF5350),
                    onIncrement: () => _increment(false),
                    onDecrement: () => _decrement(false),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _calculate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    child: const Text('Calculate'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Status message
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _statusMessage(),
                  style: TextStyle(
                      color: _statusColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusMessage() {
    if (_calculated.total == 0) return 'No classes recorded yet.';
    if (_calculated.isMet) {
      final miss = _calculated.classesCanMiss;
      return miss == 0
          ? 'Attendance met! You cannot miss any more classes.'
          : 'You can afford to miss $miss more class${miss == 1 ? '' : 'es'}.';
    } else {
      final need = _calculated.classesNeeded;
      return '⚠️ You need to attend $need more class${need == 1 ? '' : 'es'} to reach 85%.';
    }
  }
}

class _Counter extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _Counter({
    required this.label,
    required this.value,
    required this.color,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Row(
          children: [
            _iconBtn(Icons.remove, onDecrement, color),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('$value',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            _iconBtn(Icons.add, onIncrement, color),
          ],
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback cb, Color c) {
    return GestureDetector(
      onTap: cb,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: c.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: c),
      ),
    );
  }
}