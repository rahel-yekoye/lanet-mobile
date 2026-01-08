import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import '../models/phrase.dart';
import '../models/quiz_question.dart';
import '../models/course.dart';

class QuizService {
  final Random _random = Random();

  /// Generate quiz questions from phrases for a category
  Future<List<QuizQuestion>> generateQuestionsForCategory(
    List<Phrase> phrases,
    String category,
    String targetLanguage, {
    int questionCount = 10,
  }) async {
    if (phrases.isEmpty) return [];

    final List<QuizQuestion> questions = [];
    final shuffled = List<Phrase>.from(phrases)..shuffle();
    final questionTypes = [
      QuizQuestionType.multipleChoice,
      QuizQuestionType.fillInTheBlank,
      QuizQuestionType.imageQuestion,
      QuizQuestionType.translate,
    ];

    int index = 0;
    for (int i = 0; i < questionCount && index < shuffled.length; i++) {
      final phrase = shuffled[index % shuffled.length];
      final questionType = questionTypes[i % questionTypes.length];
      
      final question = _createQuestionFromPhrase(
        phrase,
        category,
        targetLanguage,
        questionType,
        phrases,
      );
      
      if (question != null) {
        questions.add(question);
      }
      index++;
    }

    return questions;
  }

  QuizQuestion? _createQuestionFromPhrase(
    Phrase phrase,
    String category,
    String targetLanguage,
    QuizQuestionType type,
    List<Phrase> allPhrases,
  ) {
    final questionId = '${category}_${phrase.english}_${_random.nextInt(10000)}';

    switch (type) {
      case QuizQuestionType.multipleChoice:
        return _createMultipleChoiceQuestion(
          phrase,
          category,
          targetLanguage,
          questionId,
          allPhrases,
        );

      case QuizQuestionType.fillInTheBlank:
        return _createFillInTheBlankQuestion(
          phrase,
          category,
          targetLanguage,
          questionId,
        );

      case QuizQuestionType.imageQuestion:
        return _createImageQuestion(
          phrase,
          category,
          targetLanguage,
          questionId,
        );

      case QuizQuestionType.translate:
        return _createTranslateQuestion(
          phrase,
          category,
          targetLanguage,
          questionId,
          allPhrases,
        );

      default:
        return null;
    }
  }

  QuizQuestion _createMultipleChoiceQuestion(
    Phrase phrase,
    String category,
    String targetLanguage,
    String questionId,
    List<Phrase> allPhrases,
  ) {
    // Question: "What is 'X' in [targetLanguage]?"
    final sourceText = phrase.english;
    final correctAnswer = _getLanguageText(phrase, targetLanguage);

    // Generate wrong options
    final options = <String>{correctAnswer};
    while (options.length < 4 && allPhrases.length > 1) {
      final randomPhrase = allPhrases[_random.nextInt(allPhrases.length)];
      final option = _getLanguageText(randomPhrase, targetLanguage);
      if (option.isNotEmpty && option != correctAnswer) {
        options.add(option);
      }
    }

    final optionsList = options.toList()..shuffle();
    final correctIndex = optionsList.indexOf(correctAnswer);

    return QuizQuestion(
      id: questionId,
      type: QuizQuestionType.multipleChoice,
      category: category,
      questionText: "What is '$sourceText' in ${_formatLanguage(targetLanguage)}?",
      options: optionsList,
      correctAnswer: correctAnswer,
      correctIndex: correctIndex,
      englishText: phrase.english,
      amharicText: phrase.amharic,
      oromoText: phrase.oromo,
      tigrinyaText: phrase.tigrinya,
      targetLanguage: targetLanguage,
      sourceLanguage: 'english',
    );
  }

  QuizQuestion _createFillInTheBlankQuestion(
    Phrase phrase,
    String category,
    String targetLanguage,
    String questionId,
  ) {
    final targetText = _getLanguageText(phrase, targetLanguage);
    final englishText = phrase.english;
    
    // Create a sentence with a blank
    final words = targetText.split(' ');
    if (words.length < 2) {
      // If single word, create a sentence around it
      return QuizQuestion(
        id: questionId,
        type: QuizQuestionType.fillInTheBlank,
        category: category,
        questionText: "Complete: '$englishText' means _____ in ${_formatLanguage(targetLanguage)}",
        correctAnswer: targetText,
        englishText: phrase.english,
        amharicText: phrase.amharic,
        oromoText: phrase.oromo,
        tigrinyaText: phrase.tigrinya,
        targetLanguage: targetLanguage,
        sourceLanguage: 'english',
      );
    }

    // Remove a random word for the blank
    final blankIndex = _random.nextInt(words.length);
    final missingWord = words[blankIndex];
    words[blankIndex] = '_____';
    final sentenceWithBlank = words.join(' ');

    return QuizQuestion(
      id: questionId,
      type: QuizQuestionType.fillInTheBlank,
      category: category,
      questionText: "$sentenceWithBlank\n(English: '$englishText')",
      correctAnswer: missingWord,
      englishText: phrase.english,
      amharicText: phrase.amharic,
      oromoText: phrase.oromo,
      tigrinyaText: phrase.tigrinya,
      targetLanguage: targetLanguage,
      sourceLanguage: 'english',
    );
  }

  QuizQuestion _createImageQuestion(
    Phrase phrase,
    String category,
    String targetLanguage,
    String questionId,
  ) {
    final targetText = _getLanguageText(phrase, targetLanguage);
    final imagePath = CategoryAssets.getImageForCategory(category);

    return QuizQuestion(
      id: questionId,
      type: QuizQuestionType.imageQuestion,
      category: category,
      questionText: "What do you see in the image?",
      imagePath: imagePath,
      correctAnswer: targetText,
      englishText: phrase.english,
      amharicText: phrase.amharic,
      oromoText: phrase.oromo,
      tigrinyaText: phrase.tigrinya,
      targetLanguage: targetLanguage,
      sourceLanguage: 'english',
    );
  }

  QuizQuestion _createTranslateQuestion(
    Phrase phrase,
    String category,
    String targetLanguage,
    String questionId,
    List<Phrase> allPhrases,
  ) {
    final sourceText = phrase.english;
    final correctAnswer = _getLanguageText(phrase, targetLanguage);

    // Generate wrong options
    final options = <String>{correctAnswer};
    while (options.length < 4 && allPhrases.length > 1) {
      final randomPhrase = allPhrases[_random.nextInt(allPhrases.length)];
      final option = _getLanguageText(randomPhrase, targetLanguage);
      if (option.isNotEmpty && option != correctAnswer) {
        options.add(option);
      }
    }

    final optionsList = options.toList()..shuffle();
    final correctIndex = optionsList.indexOf(correctAnswer);

    return QuizQuestion(
      id: questionId,
      type: QuizQuestionType.translate,
      category: category,
      questionText: "Translate to ${_formatLanguage(targetLanguage)}:\n'$sourceText'",
      options: optionsList,
      correctAnswer: correctAnswer,
      correctIndex: correctIndex,
      englishText: phrase.english,
      amharicText: phrase.amharic,
      oromoText: phrase.oromo,
      tigrinyaText: phrase.tigrinya,
      targetLanguage: targetLanguage,
      sourceLanguage: 'english',
    );
  }

  String _getLanguageText(Phrase phrase, String language) {
    switch (language.toLowerCase()) {
      case 'amharic':
        return phrase.amharic;
      case 'oromo':
        return phrase.oromo;
      case 'tigrinya':
        return phrase.tigrinya;
      case 'english':
        return phrase.english;
      default:
        return phrase.amharic;
    }
  }

  String _formatLanguage(String language) {
    switch (language.toLowerCase()) {
      case 'amharic':
        return 'Amharic';
      case 'oromo':
        return 'Oromo';
      case 'tigrinya':
        return 'Tigrinya';
      case 'english':
        return 'English';
      default:
        return language;
    }
  }

  /// Load phrases from CSV (Category,English format)
  /// Note: This assumes the CSV is in assets/data/ or will be added there
  Future<List<Phrase>> loadPhrasesFromCategoryCsv() async {
    try {
      // Try loading from assets first
      String raw;
      try {
        raw = await rootBundle.loadString('assets/data/Category,English.csv');
      } catch (_) {
        // If not in assets, try root (for development)
        return []; // Skip for now - file needs to be in assets
      }
      final lines = const LineSplitter().convert(raw);
      
      if (lines.isEmpty) return [];

      // Skip header line (first line)
      final List<Phrase> phrases = [];

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i];
        if (line.trim().isEmpty) continue;

        // Handle CSV with quotes and commas inside values
        final values = _parseCsvLine(line);
        if (values.length < 2) continue;

        final category = values[0].trim();
        final english = values[1].trim();

        if (category.isEmpty || english.isEmpty) continue;

        // Create phrase with empty translations (can be filled later)
        phrases.add(Phrase(
          category: category,
          english: english,
          amharic: '',
          oromo: '',
          tigrinya: '',
        ));
      }

      return phrases;
    } catch (e) {
      print('Error loading CSV: $e');
      return [];
    }
  }

  List<String> _parseCsvLine(String line) {
    final List<String> result = [];
    String current = '';
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current);
        current = '';
      } else {
        current += char;
      }
    }
    result.add(current);
    return result;
  }
}
