 # Chapter Four — Implementation

 ## 4.1 Introduction
 This chapter describes the implementation of the system designed in the design phase. The chosen stack for this workspace is Flutter (Dart) using object-oriented design. The implementation is organized using classes and packages that mirror the design: models, services (data access), providers (business logic/state), screens/controllers and widgets.

 This document contains: design→implementation mapping, class descriptions, concrete, commented Dart source examples, integration notes, and build/run instructions. The examples are adapted to the existing workspace layout under `lib/`.

 ## 4.2 Implementation Overview (OOP mapping)
 - Models (`lib/models/`): Plain Dart classes representing domain entities (serializable).
 - Services (`lib/services/`): Encapsulate data access (asset parsing, local persistence, remote APIs).
 - Providers (`lib/providers/`): `ChangeNotifier`-based classes exposing business logic and state to the UI.
 - Screens/Controllers (`lib/screens/`, `lib/widgets/`): Flutter UI classes that consume providers.
 - Persistence: Example uses `hive` for local storage; adaptable to your current `hive_services.dart`.

 ## 4.3 Key classes and responsibilities
 - `Lesson` model: domain object for a lesson.
 - `DatasetService`: loads bundled JSON/CSV dataset and converts to `Lesson` objects.
 - `HiveServices`: local storage layer to cache lessons.
 - `LessonProvider`: orchestrates loading lessons and exposing them to UI.
 - `LessonScreen`: displays the list of lessons and navigates to detail/practice views.

 ## 4.4 Implementation details and code samples
 Below are concise, commented, copy-paste-ready examples. Place them under `lib/` as indicated by filenames.

 ---

 ### 4.4.1 Model: `lib/models/lesson.dart`
 ```dart
 // lib/models/lesson.dart
 import 'package:json_annotation/json_annotation.dart';

 part 'lesson.g.dart';

 @JsonSerializable()
 class Lesson {
   final String id;
   final String title;
   final List<String> phrases; // phrases inside the lesson
   final int order; // ordering key

   Lesson({
     required this.id,
     required this.title,
     required this.phrases,
     required this.order,
   });

   // JSON serialization (use build_runner to generate)
   factory Lesson.fromJson(Map<String, dynamic> json) => _$LessonFromJson(json);
   Map<String, dynamic> toJson() => _$LessonToJson(this);
 }
 ```

 Notes: run `flutter pub run build_runner build --delete-conflicting-outputs` to generate `lesson.g.dart`.

 ---

 ### 4.4.2 Dataset loader: `lib/services/dataset_service.dart`
 ```dart
 // lib/services/dataset_service.dart
 import 'dart:convert';
 import 'package:flutter/services.dart';
 import '../models/lesson.dart';

 class DatasetService {
   // Load a JSON array of lessons from assets
   Future<List<Lesson>> loadLessonsFromAssets(String assetPath) async {
     final raw = await rootBundle.loadString(assetPath);
     final data = json.decode(raw) as List<dynamic>;
     return data.map((e) => Lesson.fromJson(e as Map<String, dynamic>)).toList();
   }

   // Minimal CSV parser example (adapt to your CSV structure)
   Future<List<Lesson>> parseCsv(String csv) async {
     final lines = csv.split('\n');
     final lessons = <Lesson>[];
     for (var i = 1; i < lines.length; i++) {
       final cols = lines[i].split(',');
       if (cols.length < 3) continue; // skip malformed rows
       lessons.add(Lesson(
         id: cols[0].trim(),
         title: cols[1].trim(),
         phrases: cols[2].split('|').map((s) => s.trim()).toList(),
         order: i,
       ));
     }
     return lessons;
   }
 }
 ```

 ---

 ### 4.4.3 Local persistence: `lib/services/hive_services.dart`
 ```dart
 // lib/services/hive_services.dart
 import 'package:hive/hive.dart';
 import '../models/lesson.dart';

 class HiveServices {
   static const lessonsBox = 'lessons_box';

   // Save lessons as JSON maps for portability
   Future<void> saveLessons(List<Lesson> lessons) async {
     final box = await Hive.openBox(lessonsBox);
     for (final lesson in lessons) {
       await box.put(lesson.id, lesson.toJson());
     }
     await box.close();
   }

   Future<List<Lesson>> getLessons() async {
     final box = await Hive.openBox(lessonsBox);
     final out = <Lesson>[];
     for (final key in box.keys) {
       final json = Map<String, dynamic>.from(box.get(key));
       out.add(Lesson.fromJson(json));
     }
     await box.close();
     return out;
   }
 }
 ```

 Notes: ensure Hive is initialized in `main()` and add adapters if storing typed objects.

 ---

 ### 4.4.4 Provider: `lib/providers/lesson_provider.dart`
 ```dart
 // lib/providers/lesson_provider.dart
 import 'package:flutter/foundation.dart';
 import '../models/lesson.dart';
 import '../services/dataset_service.dart';
 import '../services/hive_services.dart';

 class LessonProvider extends ChangeNotifier {
   final DatasetService datasetService;
   final HiveServices hiveServices;

   List<Lesson> _lessons = [];
   bool _loading = false;

   LessonProvider({required this.datasetService, required this.hiveServices});

   List<Lesson> get lessons => _lessons;
   bool get loading => _loading;

   // Load lessons from cache first, then fallback to assets
   Future<void> loadLessons() async {
     _loading = true;
     notifyListeners();

     final cached = await hiveServices.getLessons();
     if (cached.isNotEmpty) {
       _lessons = cached;
     } else {
       _lessons = await datasetService.loadLessonsFromAssets('assets/multilingual_dataset.json');
       await hiveServices.saveLessons(_lessons);
     }

     _loading = false;
     notifyListeners();
   }

   Lesson? lessonById(String id) => _lessons.firstWhere((l) => l.id == id, orElse: () => null);
 }
 ```

 ---

 ### 4.4.5 UI: `lib/screens/lesson_screen.dart`
 ```dart
 // lib/screens/lesson_screen.dart
 import 'package:flutter/material.dart';
 import 'package:provider/provider.dart';
 import '../providers/lesson_provider.dart';

 class LessonScreen extends StatelessWidget {
   const LessonScreen({super.key});

   @override
   Widget build(BuildContext context) {
     final provider = context.watch<LessonProvider>();

     if (provider.loading) {
       return const Scaffold(body: Center(child: CircularProgressIndicator()));
     }

     final lessons = provider.lessons;
     return Scaffold(
       appBar: AppBar(title: const Text('Lessons')),
       body: ListView.builder(
         itemCount: lessons.length,
         itemBuilder: (context, i) {
           final l = lessons[i];
           return ListTile(
             title: Text(l.title),
             subtitle: Text('${l.phrases.length} phrases'),
             onTap: () {
               // TODO: navigate to detail / practice screen
             },
           );
         },
       ),
     );
   }
 }
 ```

 ---

 ## 4.5 Integration and project updates
 - Add these packages to `pubspec.yaml` dependencies: `provider`, `hive`, `hive_flutter`, `json_annotation` and dev_dependencies: `build_runner`, `json_serializable`.
 - Declare asset files in `pubspec.yaml`, e.g.:
 ```yaml
 assets:
   - assets/multilingual_dataset.json
   - assets/level_0_fidel.csv
 ```
 - Initialize Hive in `lib/main.dart` before `runApp()`:
 ```dart
 void main() async {
   WidgetsFlutterBinding.ensureInitialized();
   await Hive.initFlutter();
   runApp(const MyApp());
 }
 ```

 ## 4.6 Build and run
 Run the following commands in the workspace root:

 ```bash
 flutter pub get
 flutter pub run build_runner build --delete-conflicting-outputs
 flutter run
 ```

 ## 4.7 Notes and recommendations
 - Keep the separation: models ⇢ services ⇢ providers ⇢ UI. That keeps unit testing and maintenance easy.
 - If your CSVs are large or parsing is heavy, parse them in background isolates.
 - For more complex persistence use typed Hive adapters instead of JSON maps.

 ## 4.8 Deliverables created
 - `CHAPTER_4_IMPLEMENTATION.md` (this file)
 - `CHAPTER_4_IMPLEMENTATION.html` (HTML version for opening in Word)

 ---

 End of Chapter Four - Implementation
