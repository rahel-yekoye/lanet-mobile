import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:google_fonts/google_fonts.dart';


import 'providers/lesson_provider.dart';
import 'providers/fidel_provider.dart';
import 'providers/auth_provider.dart';
import 'services/dataset_service.dart';
import 'services/onboarding_service.dart';
import 'screens/home_screen.dart';

// Auth screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';

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
            final provider = LessonProvider(DatasetService());
            provider.load(assetPath);
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => FidelProvider(DatasetService())..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp.router(
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
              return base.copyWith(
                textTheme: GoogleFonts.notoSansEthiopicTextTheme(base.textTheme),
              );
            }(),
            routerConfig: _router(authProvider),
          );
        },
      ),
    );
  }
}

// ------------------------------
// 🚀 GoRouter Configuration
// ------------------------------

GoRouter _router(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: authProvider.isAuthenticated ? '/home' : '/login',
    redirect: (context, state) async {
      final isAuth = authProvider.isAuthenticated;
      final isAuthRoute = state.uri.path == '/login' || state.uri.path == '/register';
      final isOnboardingRoute = state.uri.path.startsWith('/onboarding');
      
      if (!isAuth && !isAuthRoute && !isOnboardingRoute) {
        return '/login';
      }
      
      if (isAuth && isAuthRoute) {
        // Check if onboarding is completed, if not, redirect to onboarding
        final onboardingCompleted = await OnboardingService.isCompleted();
        if (!onboardingCompleted) {
          return '/onboarding/language';
        }
        return '/home';
      }
      
      // If user is authenticated but hasn't completed onboarding and tries to access home
      if (isAuth && state.uri.path == '/home') {
        final onboardingCompleted = await OnboardingService.isCompleted();
        if (!onboardingCompleted) {
          return '/onboarding/language';
        }
      }
      
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      
      // Onboarding routes
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
      
      // Main app routes
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
      ),
    ],
  );
}