import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'providers/lesson_provider.dart';
import 'providers/fidel_provider.dart';
import 'services/dataset_service.dart';
import 'screens/home_screen.dart';

// Onboarding screens
import 'screens/onboarding/language_screen.dart';
import 'screens/onboarding/level_screen.dart';
import 'screens/onboarding/reason_screen.dart';
import 'screens/onboarding/daily_goal_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final String assetPath = 'assets/data/multilingual_dataset.json';

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = LessonProvider();
            provider.load(assetPath);
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => FidelProvider(DatasetService())..load(),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Lanet — Language Learner',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          scaffoldBackgroundColor: Colors.transparent,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
        routerConfig: _router,
      ),
    );
  }
}

// ------------------------------
// 🚀 GoRouter Configuration
// ------------------------------

final GoRouter _router = GoRouter(
  initialLocation: '/onboarding/language',
  routes: [
    GoRoute(
      path: '/onboarding/language',
      builder: (_, __) => const LanguageScreen(),
    ),
    GoRoute(
      path: '/onboarding/level',
      builder: (_, __) => const LevelScreen(),
    ),
    GoRoute(
      path: '/onboarding/reason',
      builder: (_, __) => const ReasonScreen(),
    ),
    GoRoute(
      path: '/onboarding/daily_goal',
      builder: (_, __) => const DailyGoalScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (_, __) => HomeScreen(),
    ),
  ],
);
