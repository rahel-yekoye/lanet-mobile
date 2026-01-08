import 'package:flutter/material.dart';

class Course {
  final String id;
  final String title;
  final String description;
  final String category;
  final String imagePath;
  final int totalLessons;
  final int completedLessons;
  final Color color;
  final List<String> tags;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imagePath,
    this.totalLessons = 0,
    this.completedLessons = 0,
    required this.color,
    this.tags = const [],
  });

  double get progress => totalLessons > 0 ? completedLessons / totalLessons : 0.0;

  bool get isCompleted => totalLessons > 0 && completedLessons >= totalLessons;
}

// Helper class for category image mapping
class CategoryAssets {
  static const Map<String, String> categoryImages = {
    'Greetings and farewell': 'assets/images/categories/greetings.png',
    'Wishes and Introduction': 'assets/images/categories/introduction.png',
    'Daily routine': 'assets/images/categories/daily_routine.png',
    'Emergency': 'assets/images/categories/emergency.png',
    'Hotel; Restaurant; Shopping': 'assets/images/categories/shopping.png',
    'Romance and love': 'assets/images/categories/romance.png',
    'Family': 'assets/images/categories/family.png',
    'Colors': 'assets/images/categories/colors.png',
    'Food': 'assets/images/categories/food.png',
    'Animals': 'assets/images/categories/animals.png',
    'Body parts': 'assets/images/categories/body_parts.png',
  };

  static const Map<String, Color> categoryColors = {
    'Greetings and farewell': Color(0xFF4CAF50), // Green
    'Wishes and Introduction': Color(0xFF2196F3), // Blue
    'Daily routine': Color(0xFFFF9800), // Orange
    'Emergency': Color(0xFFF44336), // Red
    'Hotel; Restaurant; Shopping': Color(0xFF9C27B0), // Purple
    'Romance and love': Color(0xFFE91E63), // Pink
    'Family': Color(0xFF00BCD4), // Cyan
    'Colors': Color(0xFFFFEB3B), // Yellow
    'Food': Color(0xFFFF5722), // Deep Orange
    'Animals': Color(0xFF795548), // Brown
    'Body parts': Color(0xFF607D8B), // Blue Grey
  };

  static String getImageForCategory(String category) {
    // Try exact match first
    if (categoryImages.containsKey(category)) {
      return categoryImages[category]!;
    }
    
    // Try partial match
    for (final key in categoryImages.keys) {
      if (category.contains(key) || key.contains(category)) {
        return categoryImages[key]!;
      }
    }
    
    // Default image
    return 'assets/images/categories/default.png';
  }

  static Color getColorForCategory(String category) {
    if (categoryColors.containsKey(category)) {
      return categoryColors[category]!;
    }
    
    // Generate a color based on category name hash
    int hash = category.hashCode;
    return Color.fromRGBO(
      (hash & 0xFF0000) >> 16,
      (hash & 0x00FF00) >> 8,
      hash & 0x0000FF,
      1.0,
    );
  }
}