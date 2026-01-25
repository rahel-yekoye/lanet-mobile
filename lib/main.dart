import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/lesson_provider.dart';
import 'providers/fidel_provider.dart';
import 'providers/auth_provider.dart';
import 'services/dataset_service.dart';

import 'screens/home_screen.dart';

// Auth screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';

// Onboarding screens
import 'screens/onboarding/language_screen.dart';
import 'screens/onboarding/level_screen.dart';
import 'screens/onboarding/reason_screen.dart';
import 'screens/onboarding/daily_goal_screen.dart';

// Progress screen
import 'screens/progress_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://dkhdekawkltxpzmngvii.supabase.co',
    anonKey: 'sb_publishable_UQpSzaZNC4rUpLtaf-ezmw_iJHbe1ta',
  );
  
  // Show a readable error widget in the app when a build/layout error occurs
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 12),
                const Text('An error occurred while building the UI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(details.exceptionAsString(), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  };

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
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, LessonProvider>(
          create: (_) {
            final provider = LessonProvider(DatasetService());
            provider.load(assetPath);
            return provider;
          },
          update: (_, auth, lessonProvider) {
            final provider = lessonProvider ?? LessonProvider(DatasetService());
            final userLanguage = auth.userData?['language'];
            
            if (userLanguage != null && userLanguage.toString().isNotEmpty) {
              provider.updateLanguage(assetPath, userLanguage.toString());
            }
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => FidelProvider(DatasetService())..load(),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
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
                textTheme:
                    GoogleFonts.notoSansEthiopicTextTheme(base.textTheme),
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
    initialLocation: '/splash',
    redirect: (context, state) {
      final location = state.uri.path;

      final isAuth = authProvider.isAuthenticated;
      final onboardingDone = authProvider.onboardingCompleted;
      final isLoading = authProvider.isLoading;

      final isAuthRoute =
          location == '/login' || location == '/register';
      final isOnboardingRoute =
          location.startsWith('/onboarding');
      final isSplash = location == '/splash';

      // ⏳ Still determining auth state
      if (isLoading) {
        return isSplash ? null : '/splash';
      }

      // 🚫 Not authenticated
      if (!isAuth) {
        return isAuthRoute ? null : '/login';
      }

      // 🧭 Authenticated but onboarding not completed
      if (isAuth && !onboardingDone) {
        debugPrint('Router: User authenticated but onboarding not complete, redirecting to onboarding');
        return isOnboardingRoute ? null : '/onboarding/language';
      }

      // ✅ Authenticated & onboarding completed
      if (isAuth && onboardingDone) {
        // If user is on auth, onboarding, or splash screens, navigate to home
        if (isAuthRoute || isOnboardingRoute || isSplash) {
          return '/home';
        }
        // If already on home screen or other valid locations, don't redirect
        if (location == '/home' || location == '/progress') {
          return null;
        }
        // For any other location, redirect to home
        return '/home';
      }

      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashPage(),
      ),

      // Auth
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),

      // Onboarding
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

      // Main
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
      ),
      
      // Progress
      GoRoute(
        path: '/progress',
        builder: (_, __) => const ProgressDashboardScreen(),
      ),
    ],
  );
}

// ------------------------------
// 🌟 Splash Screen
// ------------------------------

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade100, Colors.white],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.language, size: 80, color: Colors.teal),
              SizedBox(height: 24),
              Text(
                'Lanet',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Language Learner',
                style: TextStyle(fontSize: 16, color: Colors.teal),
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
              SizedBox(height: 16),
              Text('Loading...', style: TextStyle(color: Colors.teal)),
            ],
          ),
        ),
      ),
    );
  }
}
