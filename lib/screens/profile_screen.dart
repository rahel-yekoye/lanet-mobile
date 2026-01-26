import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/onboarding_service.dart';
import '../services/progress_service.dart';
import '../services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isRefreshing = false;
  final ProgressService _progress = ProgressService();

  @override
  void initState() {
    super.initState();
    // Don't auto-refresh on init to avoid triggering router redirects
    // User can manually refresh if needed using the refresh button
  }

  Color _getDarkerColor(Color color) {
    // Create a darker version of the color (70% brightness)
    return Color.fromRGBO(
      (color.red * 0.7).round().clamp(0, 255),
      (color.green * 0.7).round().clamp(0, 255),
      (color.blue * 0.7).round().clamp(0, 255),
      1.0,
    );
  }

  Future<void> _refreshProfile() async {
    if (!mounted) return;
    setState(() => _isRefreshing = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      // Refresh user data without triggering router redirects
      // Use a silent refresh that doesn't notify listeners immediately
      await auth.refreshUserData();
      
      // Small delay to ensure state updates are processed
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final data = auth.userData ?? {};
    
    // Fetch from Supabase - get name from profiles table
    final name = (data['name'] ?? data['full_name'] ?? '').toString();
    final email = (data['email'] ?? '').toString();
    final language = (data['language'] ?? '').toString();
    final level = (data['level'] ?? '').toString();
    final reason = (data['reason'] ?? '').toString();
    final dailyGoal = (data['dailyGoal'] ?? data['daily_goal'] ?? 10).toString();
    
    // Get progress data
    final xp = (data['xp'] ?? 0).toString();
    final streak = (data['streak'] ?? 0).toString();
    final userLevel = (data['level'] ?? 1).toString();

    String initials() {
      if (name.isNotEmpty) {
        final parts = name.split(' ');
        if (parts.length > 1) {
          return (parts[0].isNotEmpty ? parts[0][0] : '') +
              (parts[1].isNotEmpty ? parts[1][0] : '');
        }
        return name[0].toUpperCase();
      }
      if (email.isNotEmpty) {
        return email[0].toUpperCase();
      }
      return 'U';
    }

    Widget statCard(String title, String value, IconData icon, Color color) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _getDarkerColor(color),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    Widget actionTile({
      required String title,
      required String subtitle,
      required IconData icon,
      required VoidCallback onTap,
      Color? iconColor,
    }) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (iconColor ?? Colors.teal).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor ?? Colors.teal, size: 24),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
          onTap: onTap,
        ),
      );
    }

    Future<void> chooseLanguage(BuildContext context) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      const options = ['Amharic', 'Tigrinya', 'Oromo'];
      await showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Choose Language',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                ...options.map((lang) => ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.language, color: Colors.teal),
                      ),
                      title: Text(lang, style: const TextStyle(fontSize: 16)),
                      trailing: language == lang
                          ? const Icon(Icons.check_circle, color: Colors.teal)
                          : null,
                      onTap: () async {
                        await OnboardingService.setValue(
                            OnboardingService.keyLanguage, lang);
                        await auth.updateProfile(language: lang);
                        if (context.mounted) {
                          Navigator.pop(context);
                          await _refreshProfile();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Language set to $lang'),
                              backgroundColor: Colors.teal,
                            ),
                          );
                        }
                      },
                    )),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );
    }

    Future<void> chooseLevel(BuildContext context) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      const options = ['Beginner', 'Intermediate', 'Advanced'];
      await showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Choose Level',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                ...options.map((lvl) => ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.school, color: Colors.purple),
                      ),
                      title: Text(lvl, style: const TextStyle(fontSize: 16)),
                      trailing: level == lvl
                          ? const Icon(Icons.check_circle, color: Colors.purple)
                          : null,
                      onTap: () async {
                        await auth.updateProfile(level: lvl);
                        if (context.mounted) {
                          Navigator.pop(context);
                          await _refreshProfile();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Level set to $lvl'),
                              backgroundColor: Colors.purple,
                            ),
                          );
                        }
                      },
                    )),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );
    }

    Future<void> chooseDailyGoal(BuildContext context) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      const options = ['5 minutes', '10 minutes', '15 minutes', '20 minutes'];
      int parse(String s) => int.tryParse(s.split(' ').first) ?? 10;
      await showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Set Daily Goal',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                ...options.map((g) => ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.timelapse, color: Colors.blue),
                      ),
                      title: Text(g, style: const TextStyle(fontSize: 16)),
                      trailing: dailyGoal == parse(g).toString()
                          ? const Icon(Icons.check_circle, color: Colors.blue)
                          : null,
                      onTap: () async {
                        final minutes = parse(g);
                        await auth.updateProfile(dailyGoal: minutes);
                        if (context.mounted) {
                          Navigator.pop(context);
                          await _refreshProfile();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Daily goal set to $minutes min'),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        }
                      },
                    )),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        automaticallyImplyLeading: false, // Don't show back button - use bottom nav instead
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshProfile,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.teal.shade400,
                    Colors.teal.shade600,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials().toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isNotEmpty ? name : 'User',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (language.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.language,
                                        size: 16, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(language,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                              ),
                            if (level.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.school,
                                        size: 16, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(level,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Stats Grid
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.1,
              children: [
                statCard('XP', xp, Icons.star, Colors.amber),
                statCard('Streak', '$streak days', Icons.local_fire_department,
                    Colors.orange),
                statCard('Level', level.isNotEmpty ? level : '-',
                    Icons.workspace_premium, Colors.purple),
                statCard('Daily Goal', '$dailyGoal min', Icons.timelapse,
                    Colors.blue),
              ],
            ),
            const SizedBox(height: 24),
            // Settings Section
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            actionTile(
              title: 'Change Language',
              subtitle: language.isNotEmpty ? 'Currently: $language' : 'Set your learning language',
              icon: Icons.language,
              iconColor: Colors.teal,
              onTap: () => chooseLanguage(context),
            ),
            const SizedBox(height: 8),
            actionTile(
              title: 'Change Level',
              subtitle: level.isNotEmpty ? 'Currently: $level' : 'Adjust your experience level',
              icon: Icons.school,
              iconColor: Colors.purple,
              onTap: () => chooseLevel(context),
            ),
            const SizedBox(height: 8),
            actionTile(
              title: 'Set Daily Goal',
              subtitle: 'Currently: $dailyGoal minutes per day',
              icon: Icons.timelapse,
              iconColor: Colors.blue,
              onTap: () => chooseDailyGoal(context),
            ),
          ],
        ),
      ),
    );
  }
}
