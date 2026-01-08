enum QuizQuestionType {
  multipleChoice, // Multiple choice questions
  fillInTheBlank, // Fill in the blank
  imageQuestion, // "What do you see in the image?"
  translate, // Translate from one language to another
  listenAndType, // Listen and type what you hear
  listenAndSelect, // Listen and select from options
  matchWords, // Match words/meanings (tap pairs)
  selectImageFromWord, // Select correct image based on word + voice
  translateSentence, // Translate sentence from given words
  completeSentence, // Complete sentence from given words
}

class QuizQuestion {
  final String id;
  final QuizQuestionType type;
  final String category;
  final String? questionText; // Question prompt
  final String? imagePath; // For image-based questions
  final List<String>? options; // For multiple choice
  final String correctAnswer; // The correct answer
  final int? correctIndex; // Index of correct answer in options list
  final String? englishText; // English reference
  final String? amharicText;
  final String? oromoText;
  final String? tigrinyaText;
  final String targetLanguage; // Which language to learn/test
  final String sourceLanguage; // Source language for translation
  final String? audioPath; // Path to audio file for listening questions
  final List<String>? imageOptions; // Multiple images to choose from
  final List<Map<String, String>>? matchingPairs; // For match words type
  final List<String>? sentenceWords; // Words to arrange for sentence
  final Map<String, dynamic>? metadata; // Additional data

  QuizQuestion({
    required this.id,
    required this.type,
    required this.category,
    this.questionText,
    this.imagePath,
    this.options,
    required this.correctAnswer,
    this.englishText,
    this.amharicText,
    this.oromoText,
    this.tigrinyaText,
    this.targetLanguage = 'amharic',
    this.sourceLanguage = 'english',
    this.audioPath,
    this.imageOptions,
    this.matchingPairs,
    this.sentenceWords,
    this.metadata,
    this.correctIndex,
  });

  String getDisplayText() {
    switch (sourceLanguage.toLowerCase()) {
      case 'english':
        return englishText ?? '';
      case 'amharic':
        return amharicText ?? '';
      case 'oromo':
        return oromoText ?? '';
      case 'tigrinya':
        return tigrinyaText ?? '';
      default:
        return englishText ?? '';
    }
  }

  String getTargetText() {
    switch (targetLanguage.toLowerCase()) {
      case 'english':
        return englishText ?? '';
      case 'amharic':
        return amharicText ?? '';
      case 'oromo':
        return oromoText ?? '';
      case 'tigrinya':
        return tigrinyaText ?? '';
      default:
        return amharicText ?? '';
    }
  }
}
