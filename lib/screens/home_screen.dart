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
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Optional: Alphabet entry only for Amharic or Tigrinya learners
            if (_userLanguage == 'amharic' || _userLanguage == 'tigrinya' || _userLanguage == 'tigrigna')
              ListTile(
                leading: const Icon(Icons.translate, color: Colors.deepOrange),
                title: const Text('Learn the Alphabet'),
                subtitle: const Text('Sounds • Letters • Pronunciation'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AlphabetOverviewScreen(),
                    ),
                  );
                },
              ),
            
            const SizedBox(height: 8),

            /// 📚 PHRASE CATEGORIES
            ...lp.categories.map((cat) {
              final count = lp.phrasesFor(cat).length;
              return ListTile(
                title: Text(cat),
                subtitle: Text('$count phrases'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final sessionManager = SessionManager();
                  final phrases = lp.phrasesFor(cat);
                  if (phrases.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('No lessons in $cat yet')),
                    );
                    return;
                  }
                  // Try resuming from saved index
                  int idx = 0;
                  final session = await sessionManager.restoreSession();
                  if (session != null) {
                    final category = session['category'] as String?;
                    final screen = session['screen'] as String?;
                    final add = session['additionalData'] as Map<String, dynamic>?;
                    if (category == cat && screen == 'lesson' && add != null) {
                      final saved = add['lesson_index'];
                      if (saved is int && saved >= 0 && saved < phrases.length) {
                        idx = saved;
                      }
                    }
                  }
                  await sessionManager.saveSession(
                    currentCategory: cat,
                    currentScreen: 'lesson',
                    additionalData: {'lesson_index': idx, 'english': phrases[idx].english},
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LessonScreen(phrase: phrases[idx]),
                    ),
                  );
                },
              );
            }),
          ],
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
}
