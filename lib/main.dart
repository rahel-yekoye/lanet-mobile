import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/lesson_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final String assetPath = 'assets/data/multilingual_dataset.json';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final p = LessonProvider();
        p.load(assetPath);
        return p;
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Lanet — Language Learner',
        theme: ThemeData(primarySwatch: Colors.teal),
        home: HomeScreen(),
      ),
    );
  }
}
