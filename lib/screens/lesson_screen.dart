import 'package:flutter/material.dart';
import '../models/phrase.dart';
import '../widgets/speech_practice.dart';
import '../widgets/celebration_dialog.dart';
import '../services/onboarding_service.dart';
import 'package:provider/provider.dart';
import '../providers/lesson_provider.dart';
import '../providers/auth_provider.dart';
import '../services/progress_service.dart';
import '../services/session_manager.dart';
import '../services/exercise_service.dart';
import '../services/admin_service.dart';
import '../models/admin_models.dart';
import 'exercise_screen.dart';

class LessonScreen extends StatefulWidget {
  final Phrase phrase;
  const LessonScreen({super.key, required this.phrase});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  String? _selectedLanguage;
  String? _userLanguage;
  bool _showSpeechPractice = false;
  List<Phrase> _categoryPhrases = [];
  int _currentIndex = 0;
  final SessionManager _sessionManager = SessionManager();
  final ProgressService _progress = ProgressService();

  @override
  void initState() {
    super.initState();
    _loadUserLanguage();
    final lp = Provider.of<LessonProvider>(context, listen: false);
    _categoryPhrases = lp.phrasesFor(widget.phrase.category);
    _currentIndex = _categoryPhrases.indexWhere((p) => p.english == widget.phrase.english);
    if (_currentIndex < 0) _currentIndex = 0;
    _restoreLessonProgress();
  }

  Future<void> _loadUserLanguage() async {
    // First try to get language from AuthProvider (Supabase)
    final auth = Provider.of<AuthProvider>(context, listen: false);
    String? language;
    
    // Get from user data (Supabase)
    final userData = auth.userData;
    if (userData != null) {
      language = userData['language']?.toString();
      debugPrint('DEBUG: Language from AuthProvider: $language');
    }
    
    // Fallback to SharedPreferences if not in userData
    if (language == null || language.isEmpty) {
      language = await OnboardingService.getValue(OnboardingService.keyLanguage);
      debugPrint('DEBUG: Language from SharedPreferences: $language');
    }
    
    // Convert language name to internal format
    if (language != null && language.isNotEmpty) {
      // Handle different language name formats
      final langLower = language.toLowerCase().trim();
      String internalLang;
      
      if (langLower.contains('oromo') || langLower.contains('afaan')) {
        internalLang = 'oromo';
      } else if (langLower.contains('tigrinya') || langLower == 'tigrigna') {
        internalLang = 'tigrinya';
      } else if (langLower.contains('amharic')) {
        internalLang = 'amharic';
      } else {
        internalLang = _convertToInternalLanguage(langLower);
      }
      
      debugPrint('DEBUG: Converted language: $language -> $internalLang');
      if (mounted) {
        setState(() {
          _userLanguage = internalLang;
          _selectedLanguage = internalLang;
        });
      }
    } else {
      // Default to amharic if no language found
      debugPrint('DEBUG: No language found, defaulting to amharic');
      if (mounted) {
        setState(() {
          _userLanguage = 'amharic';
          _selectedLanguage = 'amharic';
        });
      }
    }
  }

  String _convertToInternalLanguage(String userLang) {
    final langLower = userLang.toLowerCase().trim();
    // Handle various language name formats
    if (langLower.contains('oromo') || langLower.contains('afaan') || langLower == 'oromigna') {
      return 'oromo';
    } else if (langLower.contains('tigrinya') || langLower == 'tigrigna') {
      return 'tigrinya';
    } else if (langLower.contains('amharic')) {
      return 'amharic';
    }
    // Default fallback
    return 'amharic';
  }

  String _getTargetText() {
    switch (_selectedLanguage) {
      case 'amharic':
        return _categoryPhrases.isNotEmpty ? _categoryPhrases[_currentIndex].amharic : widget.phrase.amharic;
      case 'oromo':
        return _categoryPhrases.isNotEmpty ? _categoryPhrases[_currentIndex].oromo : widget.phrase.oromo;
      case 'tigrinya':
        return _categoryPhrases.isNotEmpty ? _categoryPhrases[_currentIndex].tigrinya : widget.phrase.tigrinya;
      default:
        return _categoryPhrases.isNotEmpty ? _categoryPhrases[_currentIndex].amharic : widget.phrase.amharic;
    }
  }

  Future<void> _restoreLessonProgress() async {
    final session = await _sessionManager.restoreSession();
    if (session != null) {
      final category = session['category'] as String?;
      final screen = session['screen'] as String?;
      final add = session['additionalData'] as Map<String, dynamic>?;
      if (category == widget.phrase.category && screen == 'lesson' && add != null) {
        final idx = add['lesson_index'];
        if (idx is int && idx >= 0 && idx < _categoryPhrases.length) {
          setState(() {
            _currentIndex = idx;
          });
        }
      }
    }
  }

  Future<void> _saveLessonProgress() async {
    final currentPhrase = _categoryPhrases.isNotEmpty ? _categoryPhrases[_currentIndex] : widget.phrase;
    await _sessionManager.saveSession(
      currentCategory: widget.phrase.category,
      currentScreen: 'lesson',
      additionalData: {
        'lesson_index': _currentIndex,
        'english': currentPhrase.english,
        'language': _selectedLanguage ?? _userLanguage,
      },
    );
  }

  Future<void> _finishLessonAndAward() async {
    // Check if there are exercises for this lesson
    // Try to find a lesson ID from the category or phrase
    List<dynamic> exercises = [];
    String? lessonId;
    
    try {
      debugPrint('Looking for lesson with category: ${widget.phrase.category}');
      
      // Fetch all published lessons (use large page size to get all)
      final lessonsResponse = await AdminService.getLessons(
        status: 'published',
        pageSize: 100, // Get more lessons
      );
      final lessons = (lessonsResponse['lessons'] as List)
          .map((l) => Lesson.fromJson(l as Map<String, dynamic>))
          .toList();
      
      debugPrint('Found ${lessons.length} published lessons');
      // Log all lesson categories for debugging
      for (final lesson in lessons) {
        debugPrint('  - Lesson: ${lesson.title}, Category: ${lesson.category}');
      }
      
      // Try to match by category field first (exact match)
      Lesson? matchingLesson;
      final categoryLower = widget.phrase.category.toLowerCase().trim();
      
      try {
        matchingLesson = lessons.firstWhere(
          (l) => l.category?.toLowerCase().trim() == categoryLower,
        );
        debugPrint('Found lesson by exact category match: ${matchingLesson.id} - ${matchingLesson.title}');
      } catch (e) {
        debugPrint('No exact category match, trying partial match...');
        // Try partial match (contains)
        try {
          matchingLesson = lessons.firstWhere(
            (l) => l.category?.toLowerCase().contains(categoryLower) == true ||
                   categoryLower.contains(l.category?.toLowerCase() ?? ''),
          );
          debugPrint('Found lesson by partial category match: ${matchingLesson.id} - ${matchingLesson.title}');
        } catch (e2) {
          debugPrint('No category match, trying title match...');
          // Try matching by title
          try {
            matchingLesson = lessons.firstWhere(
              (l) => l.title.toLowerCase().trim() == categoryLower ||
                     l.title.toLowerCase().contains(categoryLower) ||
                     categoryLower.contains(l.title.toLowerCase()),
            );
            debugPrint('Found lesson by title match: ${matchingLesson.id} - ${matchingLesson.title}');
          } catch (e3) {
            debugPrint('No lesson found matching category "${widget.phrase.category}"');
            matchingLesson = null;
          }
        }
      }
      
      if (matchingLesson != null) {
        lessonId = matchingLesson.id;
        debugPrint('Fetching exercises for lesson: $lessonId');
        exercises = await ExerciseService.getExercisesForLesson(lessonId);
        debugPrint('Found ${exercises.length} exercises for lesson $lessonId');
      } else {
        debugPrint('No matching lesson found for category: ${widget.phrase.category}');
        debugPrint('Available categories: ${lessons.map((l) => l.category).where((c) => c != null).toSet()}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching exercises: $e');
      debugPrint('Stack trace: $stackTrace');
      // Continue without exercises
    }

    // If exercises exist, navigate to exercise screen
    if (exercises.isNotEmpty && lessonId != null) {
      debugPrint('Navigating to ExerciseScreen with ${exercises.length} exercises');
      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExerciseScreen(
            lessonId: lessonId!,
            lessonTitle: widget.phrase.category,
            exercises: exercises.cast(),
            onComplete: () async {
              // After exercises are completed, show final celebration
              await _showFinalCelebration();
            },
          ),
        ),
      );
      return;
    }

    // No exercises - show regular celebration
    debugPrint('No exercises found, showing regular celebration');
    await _showFinalCelebration();
  }

  Future<void> _showFinalCelebration() async {
    // Award XP for completing the lesson (simple rule: 10 XP)
    const xpAward = 10;
    await _progress.addXP(xpAward);
    await _progress.bumpStreakIfFirstSuccessToday();
    final unlockedBadges = await _progress.checkAndUnlockAchievements();
    await _sessionManager.markCategoryCompleted(widget.phrase.category);

    if (!mounted) return;

    // Determine next category (if any)
    final lp = Provider.of<LessonProvider>(context, listen: false);
    final cats = lp.categories;
    final curIndex = cats.indexOf(widget.phrase.category);
    final hasNextCategory = curIndex >= 0 && curIndex < cats.length - 1;
    final nextCategory = hasNextCategory ? cats[curIndex + 1] : null;

    // Persist session pointing to next lesson start (index 0) when available
    // If no next category, save current category as completed (user finished all lessons)
    if (nextCategory != null) {
      final nextPhrases = lp.phrasesFor(nextCategory);
      if (nextPhrases.isNotEmpty) {
        await _sessionManager.saveSession(
          currentCategory: nextCategory,
          currentScreen: 'home', // Changed to 'home' so user goes to home screen next time
          additionalData: {
            'lesson_index': 0,
            'english': nextPhrases[0].english,
            'language': _selectedLanguage ?? _userLanguage,
          },
        );
      }
    } else {
      // All lessons completed - save session to home
      await _sessionManager.saveSession(
        currentCategory: widget.phrase.category,
        currentScreen: 'home',
        additionalData: {
          'all_completed': true,
        },
      );
    }

    if (!mounted) return;
    
    // Show celebration dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CelebrationDialog(
        xpEarned: xpAward,
        achievements: unlockedBadges,
        nextCategory: nextCategory,
        onContinue: nextCategory != null
            ? () {
                if (!mounted) return;
                final nextPhrases = lp.phrasesFor(nextCategory!);
                if (nextPhrases.isNotEmpty) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LessonScreen(phrase: nextPhrases[0]),
                    ),
                  );
                } else {
                  if (mounted) {
                    Navigator.of(context).pop(); // Pop lesson screen
                  }
                }
              }
            : () {
                if (mounted) {
                  Navigator.of(context).pop(); // Pop lesson screen
                }
              },
      ),
    );
  }

  void _onSpeechResult(bool correct) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(correct ? 'Excellent pronunciation! 🎉' : 'Keep practicing! 💪'),
        backgroundColor: correct ? Colors.green : Colors.orange,
      ),
    );
    _saveLessonProgress();
  }

  @override
  Widget build(BuildContext context) {
    final currentPhrase = _categoryPhrases.isNotEmpty ? _categoryPhrases[_currentIndex] : widget.phrase;
    if (_showSpeechPractice) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Practice Pronunciation'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _showSpeechPractice = false;
              });
              _saveLessonProgress();
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SpeechPractice(
            prompt: currentPhrase.english,
            targetText: _getTargetText(),
            onResult: _onSpeechResult,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.school, color: Colors.teal, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentPhrase.category,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Lesson ${_currentIndex + 1} of ${_categoryPhrases.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Indicator with better styling
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        '${_currentIndex + 1}/${_categoryPhrases.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (_currentIndex + 1) / _categoryPhrases.length,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.teal.shade400,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Main Content Card with gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.teal.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.translate,
                            color: Colors.teal,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'English',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currentPhrase.english,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.3,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Always show the user's selected language translation
                    if (_selectedLanguage == 'amharic' || _userLanguage == 'amharic')
                      _buildTranslationCard('Amharic', currentPhrase.amharic),
                    if (_selectedLanguage == 'oromo' || _userLanguage == 'oromo')
                      _buildTranslationCard('Oromo', currentPhrase.oromo),
                    if (_selectedLanguage == 'tigrinya' || _userLanguage == 'tigrinya')
                      _buildTranslationCard('Tigrinya', currentPhrase.tigrinya),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Practice Button with better styling
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.mic, size: 24),
                ),
                label: const Text(
                  'Practice Pronunciation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  setState(() {
                    _showSpeechPractice = true;
                  });
                  _saveLessonProgress();
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: (_categoryPhrases.length > 1)
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _currentIndex > 0
                        ? () {
                            setState(() {
                              _currentIndex = _currentIndex - 1;
                            });
                            _saveLessonProgress();
                          }
                        : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (_currentIndex < _categoryPhrases.length - 1) {
                        setState(() {
                          _currentIndex = _currentIndex + 1;
                        });
                        await _saveLessonProgress();
                      } else {
                        await _finishLessonAndAward();
                      }
                    },
                    icon: Icon(_currentIndex < _categoryPhrases.length - 1 ? Icons.arrow_forward : Icons.flag),
                    label: Text(_currentIndex < _categoryPhrases.length - 1 ? 'Next' : 'Finish'),
                  ),
                ],
              ),
            )
          : null,
    );
  }



  Widget _rowLabel(String lang, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTranslationCard(String lang, String text) {
    Color cardColor;
    Color borderColor;
    Color textColor;
    
    switch (lang.toLowerCase()) {
      case 'amharic':
        cardColor = Colors.blue.shade50;
        borderColor = Colors.blue.shade200;
        textColor = Colors.blue.shade700;
        break;
      case 'oromo':
        cardColor = Colors.green.shade50;
        borderColor = Colors.green.shade200;
        textColor = Colors.green.shade700;
        break;
      case 'tigrinya':
        cardColor = Colors.orange.shade50;
        borderColor = Colors.orange.shade200;
        textColor = Colors.orange.shade700;
        break;
      default:
        cardColor = Colors.teal.shade50;
        borderColor = Colors.teal.shade200;
        textColor = Colors.teal.shade700;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardColor,
            cardColor.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.language,
                  size: 16,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                lang,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.4,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
