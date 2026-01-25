import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';

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
import 'screens/profile_screen.dart';

// Progress screen
import 'screens/progress_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://dkhdekawkltxpzmngvii.supabase.co',
    anonKey: 'sb_publishable_UQpSzaZNC4rUpLtaf-ezmw_iJHbe1ta',
  );
  


  try {
    print('Initializing Supabase with URL: ${SupabaseConfig.url}');
    if (!SupabaseConfig.isDemoMode) {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
      print('Supabase initialized successfully');
    } else {
      print('Demo mode enabled, skipping Supabase initialization');
    }
  } catch (e) {
    print('Error initializing Supabase: \${e.toString()}');
    print('This might be due to network connectivity issues or incorrect Supabase configuration');
    print('Please verify your Supabase URL and API key are correct in lib/config/supabase_config.dart');
    
    
    // Continue anyway to allow app to load with error handling
  }

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
                const Text('An error occurred while building the UI',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

      final onboardingDone = authProvider.onboardingCompleted;
      final isLoading = authProvider.isLoading;

      final isAuthRoute = location == '/login' || location == '/register';
      final isOnboardingRoute = location.startsWith('/onboarding');
      final isSplash = location == '/splash';

      final isAuth = authProvider.isAuthenticated;

      // ⏳ Still determining auth state
      if (isLoading) {
        return isSplash ? null : '/splash';
      }

      // 🚫 Not authenticated
      if (!isAuth) {
        return isAuthRoute ? null : '/register';
      }

      // 🧭 Authenticated but onboarding not completed
      if (isAuth && !onboardingDone) {
        // Smart Routing: Check what is missing and redirect accordingly
        final userData = authProvider.userData;
        final hasLanguage = userData?['language'] != null &&
            userData!['language'].toString().isNotEmpty;
        final hasLevel = userData?['level'] != null &&
            userData!['level'].toString().isNotEmpty;
        final hasReason = userData?['reason'] != null &&
            userData!['reason'].toString().isNotEmpty;

        // If we are already on an onboarding route, we might want to let them stay there
        // unless they are on the WRONG onboarding route (e.g. back at language when they have language)
        if (isOnboardingRoute) {
          return null;
        }
        // Allow accessing Profile and Progress even if onboarding is not completed
        if (location == '/profile' || location == '/progress') {
          return null;
        }

        if (!hasLanguage) {
          return '/onboarding/language';
        } else if (!hasLevel) {
          return '/onboarding/level';
        } else if (!hasReason) {
          return '/onboarding/reason';
        } else {
          // If they have all essentials but flag is false, just send to goal (final step)
          return '/onboarding/daily_goal';
        }
      }

      // ✅ Onboarding completed - allow access to home and other screens
      if (onboardingDone) {
        // If user is on splash or onboarding screens, navigate to home
        if (isSplash || isOnboardingRoute) {
          return '/home';
        }
        // If already on home screen or other valid locations, don't redirect
        if (location == '/home' ||
            location == '/progress' ||
            location == '/profile') {
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

      ShellRoute(
        builder: (context, state, child) {
          return BottomNavScaffold(currentPath: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/progress',
            builder: (_, __) => const ProgressDashboardScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}

class BottomNavScaffold extends StatelessWidget {
  const BottomNavScaffold(
      {super.key, required this.child, required this.currentPath});
  final Widget child;
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    int index = 0;
    if (currentPath.startsWith('/progress')) {
      index = 1;
    } else if (currentPath.startsWith('/profile')) {
      index = 2;
    }
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/progress');
              break;
            case 2:
              context.go('/profile');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
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
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
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
