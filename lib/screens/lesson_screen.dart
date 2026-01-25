import 'package:flutter/material.dart';
import '../models/phrase.dart';
import '../widgets/speech_practice.dart';
import '../services/onboarding_service.dart';
import 'package:provider/provider.dart';
import '../providers/lesson_provider.dart';
import '../services/progress_service.dart';
import '../services/session_manager.dart';
import '../services/session_manager.dart';

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
    final language = await OnboardingService.getValue(OnboardingService.keyLanguage);
    setState(() {
      _userLanguage = language?.toLowerCase();
      // Set the selected language to the user's language
      if (language != null) {
        _selectedLanguage = _convertToInternalLanguage(language.toLowerCase());
      }
    });
  }

  String _convertToInternalLanguage(String userLang) {
    switch(userLang) {
      case 'amharic':
        return 'amharic';
      case 'tigrinya':
      case 'tigrigna':
        return 'tigrinya';
      case 'oromo':
      case 'oromigna':
        return 'oromo';
      default:
        return 'amharic';
    }
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
    // Award XP for completing the lesson (simple rule: 10 XP)
    const xpAward = 10;
    await _progress.addXP(xpAward);
    await _progress.bumpStreakIfFirstSuccessToday();
    final unlockedBadges = await _progress.checkAndUnlockAchievements();
    await _sessionManager.markCategoryCompleted(widget.phrase.category);

    // Determine next category (if any)
    final lp = Provider.of<LessonProvider>(context, listen: false);
    final cats = lp.categories;
    final curIndex = cats.indexOf(widget.phrase.category);
    final hasNextCategory = curIndex >= 0 && curIndex < cats.length - 1;
    final nextCategory = hasNextCategory ? cats[curIndex + 1] : null;

    // Persist session pointing to next lesson start (index 0) when available
    if (nextCategory != null) {
      final nextPhrases = lp.phrasesFor(nextCategory);
      if (nextPhrases.isNotEmpty) {
        await _sessionManager.saveSession(
          currentCategory: nextCategory,
          currentScreen: 'lesson',
          additionalData: {
            'lesson_index': 0,
            'english': nextPhrases[0].english,
            'language': _selectedLanguage ?? _userLanguage,
          },
        );
      }
    }

    if (!mounted) return;
    // Show completion summary
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Lesson Complete', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('⭐ +$xpAward XP', style: const TextStyle(fontSize: 16, color: Colors.teal)),
              const SizedBox(height: 8),
              if (unlockedBadges.isNotEmpty)
                Text('🏅 Unlocked: ${unlockedBadges.join(', ')}', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  if (nextCategory != null)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        final nextPhrases = lp.phrasesFor(nextCategory);
                        if (nextPhrases.isNotEmpty) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LessonScreen(phrase: nextPhrases[0]),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: Text('Start ${nextCategory}'),
                    ),
                ],
              ),
            ],
          ),
        );
      },
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
      appBar: AppBar(
        title: Text(currentPhrase.category),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentPhrase.english,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Lesson ${_currentIndex + 1} of ${_categoryPhrases.length}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              if (_userLanguage != null && _userLanguage!.toLowerCase() == 'amharic')
                _rowLabel('Amharic', currentPhrase.amharic),
              if (_userLanguage != null && _userLanguage!.toLowerCase() == 'oromo')
                _rowLabel('Oromo', currentPhrase.oromo),
              if (_userLanguage != null && (_userLanguage!.toLowerCase() == 'tigrinya' || _userLanguage!.toLowerCase() == 'tigrigna'))
                _rowLabel('Tigrinya', currentPhrase.tigrinya),
              const SizedBox(height: 24),
              if (_userLanguage != null)
                Text(
                  'Practice pronunciation in $_userLanguage:',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.mic, size: 28),
                label: const Text(
                  'Practice Pronunciation',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _showSpeechPractice = true;
                  });
                  _saveLessonProgress();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
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
}
