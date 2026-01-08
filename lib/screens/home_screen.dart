import 'package:flutter/material.dart';
import 'package:lanet_mobile/screens/alphabet/alphabet_overview_screen.dart';
import 'package:lanet_mobile/screens/tutor_screen.dart';
import 'package:lanet_mobile/widgets/pattern_background.dart';
import 'package:provider/provider.dart';

import '../providers/lesson_provider.dart';
import 'category_screen.dart';
import 'course_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LessonProvider>(context);

    if (lp.loading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PatternBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Lanet — Learn Languages'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            /// 🔤 ALPHABET ENTRY (FIXED AT TOP)
            _AlphabetEntryCard(context),

            const SizedBox(height: 16),

            /// 🤖 TUTOR ENTRY
            _TutorEntryCard(context),

            const SizedBox(height: 16),

            /// 📚 COURSES & QUIZZES ENTRY
            _CoursesEntryCard(context),

            const SizedBox(height: 16),

            /// 📚 PHRASE CATEGORIES
            ...lp.categories.map((cat) {
              final count = lp.phrasesFor(cat).length;
              return ListTile(
                title: Text(cat),
                subtitle: Text('$count phrases'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryScreen(category: cat),
                    ),
                  );
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

/// 🤖 Tutor Card Widget
class _TutorEntryCard extends StatelessWidget {
  const _TutorEntryCard(this.context);

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TutorScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            /// Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 28,
                color: Colors.blue,
              ),
            ),

            const SizedBox(width: 16),

            /// Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'AI Amharic Tutor',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Ask questions • Practice conversation',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

/// 📚 Courses & Quizzes Card Widget
class _CoursesEntryCard extends StatelessWidget {
  const _CoursesEntryCard(this.context);

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CourseScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purple.shade200),
        ),
        child: Row(
          children: [
            /// Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school,
                size: 28,
                color: Colors.purple,
              ),
            ),

            const SizedBox(width: 16),

            /// Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Courses & Quizzes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Interactive learning • Multiple question types',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

/// 🔤 Alphabet Card Widget
class _AlphabetEntryCard extends StatelessWidget {
  const _AlphabetEntryCard(this.context);

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AlphabetOverviewScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            /// Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.translate,
                size: 28,
                color: Colors.deepOrange,
              ),
            ),

            const SizedBox(width: 16),

            /// Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Learn the Alphabet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Sounds • Letters • Pronunciation',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
