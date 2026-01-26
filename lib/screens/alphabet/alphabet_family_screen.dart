// lib/screens/alphabet/alphabet_family_screen.dart
import 'package:flutter/material.dart';
import 'package:lanet_mobile/models/fidel_model.dart';
import 'package:lanet_mobile/providers/fidel_provider.dart';
import 'package:lanet_mobile/services/srs_service.dart';
import 'package:lanet_mobile/services/alphabet_audio_service.dart';
import 'package:lanet_mobile/widgets/pattern_background.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/onboarding_service.dart';

class AlphabetFamilyScreen extends StatefulWidget {
  final String family;

  const AlphabetFamilyScreen({required this.family, super.key});

  @override
  State<AlphabetFamilyScreen> createState() => _AlphabetFamilyScreenState();
}

class _AlphabetFamilyScreenState extends State<AlphabetFamilyScreen> {
  final SRSService _srsService = SRSService();
  final AlphabetAudioService _alphabetAudioService = AlphabetAudioService();

  int _score = 0;
  int _mode = 0; // 0 = Learn mode, 1 = Quiz mode
  bool _isLoading = true;
  String? _userLanguage;

  FidelModel? _currentTarget;
  List<FidelModel> _quizOptions = [];
  late List<FidelModel> familyItems;

  @override
  void initState() {
    super.initState();
    _loadUserLanguage();
    _loadFamilyItems();
  }

  Future<void> _loadUserLanguage() async {
    final language = await OnboardingService.getValue(OnboardingService.keyLanguage);
    setState(() {
      _userLanguage = language;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PatternBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text('${widget.family.toUpperCase()} Family (${_userLanguage ?? 'Language'})'),
          actions: _mode == 0
              ? [
                  IconButton(
                    icon: const Icon(Icons.quiz_outlined, size: 28),
                    tooltip: 'Start Quiz',
                    onPressed: _startQuiz,
                  ),
                ]
              : [
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Exit Quiz',
                    onPressed: () => setState(() => _mode = 0),
                  ),
                ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _mode == 0
                ? _buildLearnMode()
                : _buildQuizMode(),
      ),
    );
  }

  Future<void> _loadFamilyItems() async {
    try {
      final fidelProvider = Provider.of<FidelProvider>(context, listen: false);
      final items = fidelProvider.family(widget.family);
      if (mounted) {
        setState(() {
          familyItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading family items: $e')),
        );
      }
    }
  }

  Future<void> _playSound(String audioFile) async {
    // Use the character-based audio service instead of audioFile from CSV
    // This method is called with audioFile, but we'll use the character from currentTarget
    if (_currentTarget != null) {
      final played = await _alphabetAudioService.playAlphabetAudio(_currentTarget!.character);
      if (!played && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('🔊 Audio not ready yet — quiz continues!')),
        );
      }
    }
  }

  void _startQuiz() {
    setState(() {
      _mode = 1;
      _score = 0;
      _generateNewQuestion();
    });
  }

  void _generateNewQuestion() {
    final shuffled = List<FidelModel>.from(familyItems)..shuffle();
    _currentTarget = shuffled.first;
    _quizOptions = [shuffled.first, ...shuffled.skip(1).take(3)]..shuffle();

    // Play audio using character-based mapping
    _playSound('');
  }

  Future<void> _checkAnswer(FidelModel selected) async {
    if (selected == _currentTarget) {
      setState(() => _score++);
      // Update SRS progress for correct answer
      await _srsService.markCorrect('alphabet', selected.character);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Correct! 🎉', style: TextStyle(color: Colors.white)),
          ),
        );
      }
    } else {
      // Update SRS progress for incorrect answer
      await _srsService.markWrong('alphabet', selected.character);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orange,
            content: Text('Try again!'),
          ),
        );
      }
    }

    if (mounted) {
      _generateNewQuestion();
    }
  }

  Widget _buildLetterCard(FidelModel fidel) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          // Play audio when alphabet is clicked - ONLY audio, no navigation
          await _alphabetAudioService.playAlphabetAudio(fidel.character);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              fidel.character,
              style: GoogleFonts.notoSansEthiopic(fontSize: 48),
            ),
            const SizedBox(height: 8),
            Text(
              fidel.transliteration,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            if (fidel.vowel.isNotEmpty)
              Text(
                fidel.vowel,
                style: const TextStyle(fontSize: 16, color: Colors.deepOrange),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearnMode() {
    if (familyItems.isEmpty) {
      return const Center(
        child: Text('No letters found in this family'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: familyItems.length,
      itemBuilder: (context, index) {
        return _buildLetterCard(familyItems[index]);
      },
    );
  }

  Widget _buildQuizMode() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('Score: $_score',
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange)),
          const SizedBox(height: 30),
          const Text('🔊 Listen and tap the correct letter!',
              style: TextStyle(fontSize: 20)),
          const SizedBox(height: 40),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
              ),
              itemCount: 4,
              itemBuilder: (context, i) {
                final option = _quizOptions[i];
                return Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                  color: Colors.amber.shade50,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () async => await _checkAnswer(option),
                    child: Center(
                      child: Text(
                        option.character,
                        style: GoogleFonts.notoSansEthiopic(fontSize: 80),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
