import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
  runApp(const MyApp());
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
        theme: () {
          final base = ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.transparent,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          );
          final ff = GoogleFonts.notoSansEthiopic().fontFamily;
          return base.copyWith(
            textTheme: GoogleFonts.notoSansEthiopicTextTheme(base.textTheme),
          );
        }(),
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
      builder: (context, state) => LanguageScreen(),
    ),
    GoRoute(
      path: '/onboarding/level',
      builder: (context, state) => LevelScreen(),
    ),
    GoRoute(
      path: '/onboarding/reason',
      builder: (context, state) => ReasonScreen(),
    ),
    GoRoute(
      path: '/onboarding/daily_goal',
      builder: (context, state) => DailyGoalScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => HomeScreen(),
    ),
  ],
);
