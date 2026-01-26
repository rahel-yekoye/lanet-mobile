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
import 'services/admin_service.dart';

import 'screens/home_screen.dart';

// Auth screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/role_selection_screen.dart';

// Onboarding screens
import 'screens/onboarding/language_screen.dart';
import 'screens/onboarding/level_screen.dart';
import 'screens/onboarding/reason_screen.dart';
import 'screens/onboarding/daily_goal_screen.dart';
import 'screens/profile_screen.dart';

// Progress screen
import 'screens/progress_dashboard_screen.dart';

// Admin screen
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/sections/lesson_form_screen.dart';
import 'models/admin_models.dart';

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
            // Don't load lessons until onboarding is complete
            return provider;
          },
          update: (_, auth, lessonProvider) {
            final provider = lessonProvider ?? LessonProvider(DatasetService());
            final onboardingDone = auth.onboardingCompleted;
            final userLanguage = auth.userData?['language'];

            // Only load lessons if onboarding is complete
            if (onboardingDone && userLanguage != null && userLanguage.toString().isNotEmpty) {
              // Check if lessons haven't been loaded yet or language changed
              if (provider.categories.isEmpty || provider.loading) {
                provider.load(assetPath, language: userLanguage.toString());
              } else {
                provider.updateLanguage(assetPath, userLanguage.toString());
              }
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
    initialLocation: '/role-selection',
    redirect: (context, state) async {
      final location = state.uri.path;

      final onboardingDone = authProvider.onboardingCompleted;
      final isLoading = authProvider.isLoading;

      final isAuthRoute = location == '/login' || location == '/register';
      final isOnboardingRoute = location.startsWith('/onboarding');
      final isRoleSelection = location == '/role-selection';
      final isAdminRoute = location == '/admin' || location.startsWith('/admin/');

      final isAuth = authProvider.isAuthenticated;

      // ⏳ Still determining auth state - skip splash, go directly to appropriate screen
      if (isLoading) {
        // Don't redirect anywhere, let the app load
        return null;
      }

      // Check if role is selected
      final selectedRole = await RoleSelectionScreen.getSelectedRole();

      // 🎯 Role Selection - First step for all users
      if (!isAuth && !isRoleSelection && selectedRole == null) {
        return '/role-selection';
      }

      // 🚫 Not authenticated - but role is selected
      if (!isAuth) {
        // If on role selection, allow it
        if (isRoleSelection) {
          return null;
        }
        // Otherwise go to auth routes
        return isAuthRoute ? null : '/register';
      }

      // 🧭 Authenticated but onboarding not completed
      if (isAuth && !onboardingDone) {
        // Check if user is admin - admins skip onboarding
        final isAdmin = await AdminService.isAdmin();
        if (isAdmin) {
          // Admins go directly to admin dashboard, skip onboarding
          return isAdminRoute ? null : '/admin';
        }
        
        // CRITICAL: If we are already on an onboarding route, ALWAYS let them stay there
        // This prevents ANY redirects while user is actively filling out forms
        // This check MUST come first, before any other logic
        if (isOnboardingRoute) {
          return null; // Stay on onboarding route - do NOT redirect
        }
        
        // Allow accessing Profile and Progress even if onboarding is not completed
        if (location == '/profile' || location == '/progress') {
          return null;
        }

        // Smart Routing: Check what is missing and redirect accordingly
        final userData = authProvider.userData;
        final hasLanguage = userData?['language'] != null &&
            userData!['language'].toString().isNotEmpty;
        final hasLevel = userData?['level'] != null &&
            userData!['level'].toString().isNotEmpty;
        final hasReason = userData?['reason'] != null &&
            userData!['reason'].toString().isNotEmpty;
        // Check if daily goal is set AND is not the default value (100)
        // Valid user choices from onboarding are: 5, 10, 15, 20 minutes
        // If it's 100, it's the old default and user hasn't set it properly
        final dailyGoalValue = userData?['daily_goal'] ?? userData?['dailyGoal'];
        final hasDailyGoal = dailyGoalValue != null && 
            dailyGoalValue != 100 && // 100 is the old default, not a valid user choice
            dailyGoalValue.toString().isNotEmpty;

        // Route to the first missing step
        // IMPORTANT: Only redirect if we're NOT already on an onboarding route
        // This prevents redirects during navigation between onboarding screens
        if (!hasLanguage && location != '/onboarding/language') {
          return '/onboarding/language';
        } else if (!hasLevel && location != '/onboarding/level') {
          return '/onboarding/level';
        } else if (!hasReason && location != '/onboarding/reason') {
          return '/onboarding/reason';
        } else if (!hasDailyGoal && location != '/onboarding/daily_goal') {
          return '/onboarding/daily_goal';
        } else if (hasLanguage && hasLevel && hasReason && hasDailyGoal && location != '/onboarding/daily_goal') {
          // All fields present but onboarding_completed flag not set - go to final step
          return '/onboarding/daily_goal';
        }
        
        // If we're already on the correct onboarding screen, stay there
        return null;
      }

      // ✅ Onboarding completed - route based on role
      if (onboardingDone) {
        // Check if user is admin
        final isAdmin = await AdminService.isAdmin();
        
        // Admin users go to admin dashboard
        if (isAdmin) {
          if (isOnboardingRoute || (location == '/home' && !isAdminRoute)) {
            return '/admin';
          }
          // CRITICAL: Allow all admin routes (including /admin/lessons/new, etc.)
          // This prevents redirects when navigating to admin sub-routes
          if (isAdminRoute) {
            return null; // Stay on admin route - do NOT redirect
          }
          // Redirect other routes to dashboard (but not admin sub-routes)
          if (!isAdminRoute && 
              location != '/login' && 
              location != '/register' &&
              location != '/role-selection') {
            return '/admin';
          }
        } else {
          // Student users go to home/student screens
          if (isOnboardingRoute || isAdminRoute) {
            return '/home';
          }
          // CRITICAL: If already on student screens (home, progress, profile), stay there
          // This prevents redirects when user is actively viewing these screens
          if (location == '/home' ||
              location == '/progress' ||
              location == '/profile') {
            return null; // Stay on current screen - do NOT redirect
          }
          // For any other location, redirect to home
          return '/home';
        }
      }

      return null;
    },
    routes: [
      // Role Selection
      GoRoute(
        path: '/role-selection',
        builder: (_, __) => const RoleSelectionScreen(),
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
      
      // Admin Dashboard
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminDashboardScreen(),
      ),
      
      // Admin Lesson Routes
      GoRoute(
        path: '/admin/lessons/new',
        builder: (_, __) => const LessonFormScreen(),
      ),
      GoRoute(
        path: '/admin/lessons/:id',
        builder: (context, state) {
          final lessonId = state.pathParameters['id']!;
          // The LessonFormScreen will load the lesson itself if needed
          // For now, we'll create a wrapper that loads it
          return _LessonFormWrapper(lessonId: lessonId);
        },
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

// Wrapper widget to load lesson asynchronously
class _LessonFormWrapper extends StatefulWidget {
  final String lessonId;

  const _LessonFormWrapper({required this.lessonId});

  @override
  State<_LessonFormWrapper> createState() => _LessonFormWrapperState();
}

class _LessonFormWrapperState extends State<_LessonFormWrapper> {
  Lesson? _lesson;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  Future<void> _loadLesson() async {
    try {
      final lesson = await AdminService.getLesson(widget.lessonId);
      if (mounted) {
        setState(() {
          _lesson = lesson;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load lesson: $e'),
            backgroundColor: Colors.red,
          ),
        );
        context.go('/admin');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _lesson == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load lesson'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/admin'),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
    return LessonFormScreen(lesson: _lesson);
  }
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

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade50, Colors.white],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
