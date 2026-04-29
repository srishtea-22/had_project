import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../services/firebase_service.dart';
import 'add_subject_screen.dart';
import 'subject_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AddSubjectScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = FirebaseService();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Tracker',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Subject>>(
        stream: service.subjectsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
          }

          if (snap.hasError) {
            return Center(
              child: Text('Error: ${snap.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }

          final subjects = snap.data ?? [];

          if (subjects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined,
                      size: 72, color: Colors.white.withOpacity(0.15)),
                  const SizedBox(height: 16),
                  Text(
                    'No subjects yet',
                    style: TextStyle(
                        fontSize: 18, color: Colors.white.withOpacity(0.4)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first subject',
                    style: TextStyle(
                        fontSize: 13, color: Colors.white.withOpacity(0.25)),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            itemCount: subjects.length,
            itemBuilder: (_, i) => SubjectCard(key: ValueKey(subjects[i].id), subject: subjects[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Subject',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
