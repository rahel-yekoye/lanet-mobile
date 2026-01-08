import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lesson_provider.dart';
import '../models/course.dart';
import '../services/quiz_service.dart';
import 'quiz_screen.dart';
import 'category_screen.dart';

class CourseScreen extends StatelessWidget {
  const CourseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LessonProvider>(context);

    if (lp.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses & Quizzes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          const Text(
            'Start Learning',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a course to begin your learning journey',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // Course cards
          ...lp.categories.map((category) {
            final phrases = lp.phrasesFor(category);
            final course = _createCourseFromCategory(category, phrases.length);
            
            return _CourseCard(
              course: course,
              category: category,
              phraseCount: phrases.length,
            );
          }).toList(),
        ],
      ),
    );
  }

  Course _createCourseFromCategory(String category, int phraseCount) {
    return Course(
      id: category.toLowerCase().replaceAll(' ', '_'),
      title: category,
      description: 'Learn essential ${category.toLowerCase()} phrases and vocabulary',
      category: category,
      imagePath: CategoryAssets.getImageForCategory(category),
      totalLessons: (phraseCount / 5).ceil(), // Approximate lessons
      completedLessons: 0,
      color: CategoryAssets.getColorForCategory(category),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  final String category;
  final int phraseCount;

  const _CourseCard({
    required this.course,
    required this.category,
    required this.phraseCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showCourseOptions(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Course icon/image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: course.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getCategoryIcon(category),
                    size: 40,
                    color: course.color,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Course info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$phraseCount phrases',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: course.progress,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(course.color),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    if (category.contains('Greeting')) return Icons.waving_hand;
    if (category.contains('Food')) return Icons.restaurant;
    if (category.contains('Family')) return Icons.family_restroom;
    if (category.contains('Color')) return Icons.palette;
    if (category.contains('Animal')) return Icons.pets;
    if (category.contains('Body')) return Icons.accessibility;
    if (category.contains('Emergency')) return Icons.emergency;
    if (category.contains('Romance')) return Icons.favorite;
    if (category.contains('Shopping')) return Icons.shopping_bag;
    if (category.contains('Daily')) return Icons.schedule;
    return Icons.school;
  }

  void _showCourseOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              category,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // View all phrases
            ListTile(
              leading: Icon(Icons.list, color: course.color),
              title: const Text('View All Phrases'),
              subtitle: const Text('Browse and study all phrases in this category'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryScreen(category: category),
                  ),
                );
              },
            ),
            
            // Start quiz
            ListTile(
              leading: Icon(Icons.quiz, color: course.color),
              title: const Text('Start Quiz'),
              subtitle: const Text('Practice with interactive questions'),
              onTap: () => _startQuiz(context),
            ),
            
            // Language selection
            ListTile(
              leading: Icon(Icons.language, color: course.color),
              title: const Text('Select Language'),
              subtitle: const Text('Choose which language to learn'),
              onTap: () => _selectLanguage(context),
            ),
          ],
        ),
      ),
    );
  }

  void _startQuiz(BuildContext context) async {
    Navigator.pop(context);
    
    final lp = Provider.of<LessonProvider>(context, listen: false);
    final phrases = lp.phrasesFor(category);
    
    if (phrases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phrases available for this category')),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final quizService = QuizService();
      final questions = await quizService.generateQuestionsForCategory(
        phrases,
        category,
        'amharic', // Default to Amharic, can be made selectable
        questionCount: 10,
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuizScreen(
              category: category,
              questions: questions,
              targetLanguage: 'amharic',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading quiz: $e')),
        );
      }
    }
  }

  void _selectLanguage(BuildContext context) {
    // Simple language selection for now
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Amharic'),
              onTap: () {
                Navigator.pop(context);
                _startQuizWithLanguage(context, 'amharic');
              },
            ),
            ListTile(
              title: const Text('Oromo'),
              onTap: () {
                Navigator.pop(context);
                _startQuizWithLanguage(context, 'oromo');
              },
            ),
            ListTile(
              title: const Text('Tigrinya'),
              onTap: () {
                Navigator.pop(context);
                _startQuizWithLanguage(context, 'tigrinya');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _startQuizWithLanguage(BuildContext context, String language) async {
    final lp = Provider.of<LessonProvider>(context, listen: false);
    final phrases = lp.phrasesFor(category);
    
    if (phrases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phrases available for this category')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final quizService = QuizService();
      final questions = await quizService.generateQuestionsForCategory(
        phrases,
        category,
        language,
        questionCount: 10,
      );

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuizScreen(
              category: category,
              questions: questions,
              targetLanguage: language,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading quiz: $e')),
        );
      }
    }
  }
}
