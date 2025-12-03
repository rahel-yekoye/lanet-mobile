class Phrase {
  final String english;
  final String amharic;
  final String oromo;
  final String tigrinya;
  final String category;

  Phrase({
    required this.english,
    required this.amharic,
    required this.oromo,
    required this.tigrinya,
    required this.category,
  });

  factory Phrase.fromMap(Map<String, dynamic> m, String category) {
    return Phrase(
      english: (m['English'] ?? '').toString(),
      amharic: (m['Amharic'] ?? '').toString(),
      oromo: (m['Oromo'] ?? '').toString(),
      tigrinya: (m['Tigrinya'] ?? '').toString(),
      category: category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Category': category,
      'English': english,
      'Amharic': amharic,
      'Oromo': oromo,
      'Tigrinya': tigrinya,
    };
  }
}
