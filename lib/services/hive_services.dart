// lib/services/hive_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/unit_model.dart';
import '../models/lesson_model.dart';
import '../models/content_model.dart';
import '../models/achievement_model.dart';

class HiveService {
  static Future<void> init() async {
    // Initialize Hive with Flutter
    await Hive.initFlutter();
    
    // Register Hive adapters
    Hive
      ..registerAdapter(UserAdapter())
      ..registerAdapter(UnitAdapter())
      ..registerAdapter(LessonAdapter())
      ..registerAdapter(ContentAdapter())
      ..registerAdapter(ContentTypeAdapter())
      ..registerAdapter(AchievementAdapter())
      ..registerAdapter(AchievementTypeAdapter());
    
    // Open all the boxes
    await Future.wait([
      Hive.openBox<User>('users'),
      Hive.openBox<Unit>('units'),
      Hive.openBox<Lesson>('lessons'),
      Hive.openBox<Content>('contents'),
      Hive.openBox<Achievement>('achievements'),
    ]);
  }
}