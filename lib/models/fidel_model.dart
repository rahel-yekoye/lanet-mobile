class FidelModel {
  final int id;
  final String family;
  final int familyOrder;
  final int order;
  final String character;
  final String transliteration;
  final String vowel;
  final String audioFile;

  FidelModel({
    required this.id,
    required this.family,
    required this.familyOrder,
    required this.order,
    required this.character,
    required this.transliteration,
    required this.vowel,
    required this.audioFile,
  });

  factory FidelModel.fromCsv(Map<String, dynamic> row) {
    return FidelModel(
      id: int.parse(row['id']),
      family: row['family'],
      familyOrder: int.parse(row['family_order']),
      order: int.parse(row['order']),
      character: row['character'],
      transliteration: row['transliteration'],
      vowel: row['vowel'],
      audioFile: row['audio_file'] ?? '',
    );
  }
}
