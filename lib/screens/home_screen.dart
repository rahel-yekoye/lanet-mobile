import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lanet_mobile/screens/alphabet/alphabet_overview_screen.dart';
import 'package:lanet_mobile/screens/tutor_screen.dart';
import 'package:lanet_mobile/widgets/pattern_background.dart';
import 'package:provider/provider.dart';
import '../services/session_manager.dart';
import '../services/onboarding_service.dart';

import '../providers/lesson_provider.dart';
import 'lesson_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userLanguage;
  @override
  void initState() {
    super.initState();
    _loadUserLanguage();
  }
  
  Future<void> _loadUserLanguage() async {
    final language = await OnboardingService.getValue(OnboardingService.keyLanguage);
    setState(() {
      _userLanguage = language?.toLowerCase();
    });
  }
  
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
          actions: [
            IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: () {
                GoRouter.of(context).go('/progress');
              },
              tooltip: 'View Progress',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Optional: Alphabet entry
              if (_userLanguage == 'amharic' || 
                  _userLanguage == 'tigrinya' || 
                  _userLanguage == 'tigrigna')
                _buildAlphabetCard(),
              
              const SizedBox(height: 16),
              
              // Lesson Cards
              ...lp.categories.asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value;
                return _buildLessonCard(
                  context,
                  category,
                  index,
                  lp,
                );
              }),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'AI Tutor',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TutorScreen(),
              ),
            );
          },
          child: const Icon(Icons.chat),
        ),
      ),
    );
  }

  Widget _buildAlphabetCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AlphabetOverviewScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.translate,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Learn the Alphabet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sounds • Letters • Pronunciation',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessonCard(
    BuildContext context,
    String category,
    int index,
    LessonProvider lp,
  ) {
    return FutureBuilder<List<String>>(
      future: SessionManager().getCompletedCategories(),
      builder: (context, snapshot) {
        final completedCategories = snapshot.data ?? [];
        final isCompleted = completedCategories.contains(category);
        final phrases = lp.phrasesFor(category);
        final count = phrases.length;
        
        // Determine if lesson is locked (previous must be completed)
        bool isLocked = false;
        if (index > 0) {
          final prevCategory = lp.categories[index - 1];
          isLocked = !completedCategories.contains(prevCategory);
        }
        
        // First lesson is always unlocked
        if (index == 0) {
          isLocked = false;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isLocked ? 2 : 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: isLocked ? Colors.grey.shade200 : Colors.white,
          child: InkWell(
            onTap: isLocked
                ? null
                : () async {
                    final sessionManager = SessionManager();
                    final phrases = lp.phrasesFor(category);
                    if (phrases.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No lessons in $category yet')),
                      );
                      return;
                    }
                    
                    int idx = 0;
                    final session = await sessionManager.restoreSession();
                    if (session != null) {
                      final sessionCategory = session['category'] as String?;
                      final screen = session['screen'] as String?;
                      final add = session['additionalData'] as Map<String, dynamic>?;
                      if (sessionCategory == category && 
                          screen == 'lesson' && 
                          add != null) {
                        final saved = add['lesson_index'];
                        if (saved is int && saved >= 0 && saved < phrases.length) {
                          idx = saved;
                        }
                      }
                    }
                    
                    await sessionManager.saveSession(
                      currentCategory: category,
                      currentScreen: 'lesson',
                      additionalData: {
                        'lesson_index': idx,
                        'english': phrases[idx].english,
                      },
                    );
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LessonScreen(phrase: phrases[idx]),
                      ),
                    );
                  },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Status Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isLocked
                          ? Colors.grey.shade300
                          : isCompleted
                              ? Colors.green.shade100
                              : _getCategoryColor(category).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isLocked
                        ? Icon(
                            Icons.lock,
                            color: Colors.grey.shade600,
                            size: 28,
                          )
                        : isCompleted
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 32,
                              )
                            : Icon(
                                _getCategoryIcon(category),
                                color: _getCategoryColor(category),
                                size: 32,
                              ),
                  ),
                  const SizedBox(width: 16),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isLocked
                                      ? Colors.grey.shade600
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            if (isCompleted)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '✓ Done',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$count phrases',
                          style: TextStyle(
                            fontSize: 14,
                            color: isLocked
                                ? Colors.grey.shade500
                                : Colors.grey.shade600,
                          ),
                        ),
                        if (isLocked) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Complete previous lesson to unlock',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!isLocked)
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.indigo,
      Colors.teal,
    ];
    return colors[category.hashCode % colors.length];
  }

  IconData _getCategoryIcon(String category) {
    if (category.toLowerCase().contains('greeting')) {
      return Icons.waving_hand;
    } else if (category.toLowerCase().contains('emergency')) {
      return Icons.warning;
    } else if (category.toLowerCase().contains('romance')) {
      return Icons.favorite;
    } else if (category.toLowerCase().contains('hotel') || 
               category.toLowerCase().contains('restaurant')) {
      return Icons.restaurant;
    } else {
      return Icons.school;
    }
  }
}
