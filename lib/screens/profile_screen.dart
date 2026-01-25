import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/onboarding_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final data = auth.userData ?? {};
    final name = (data['name'] ?? '').toString();
    final email = (data['email'] ?? '').toString();
    final language = (data['language'] ?? '').toString();
    final level = (data['level'] ?? '').toString();
    final dailyGoal =
        (data['dailyGoal'] ?? data['daily_goal'] ?? 10).toString();
    final xp = (data['xp'] ?? 0).toString();
    final streak = (data['streak'] ?? 0).toString();

    String initials() {
      if (name.isNotEmpty) {
        final parts = name.split(' ');
        if (parts.length > 1) {
          return (parts[0].isNotEmpty ? parts[0][0] : '') +
              (parts[1].isNotEmpty ? parts[1][0] : '');
        }
        return name[0];
      }
      if (email.isNotEmpty) {
        return email[0].toUpperCase();
      }
      return 'U';
    }

    Widget statCard(String title, String value, IconData icon, Color color) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
    }) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Icon(icon, color: Colors.teal),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
    }

    Future<void> _chooseLanguage(BuildContext context) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final options = const ['Amharic', 'Tigrinya', 'Oromo'];
      await showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) {
          return SafeArea(
            child: ListView(
              children: [
                const ListTile(
                  title: Text('Choose Language',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ...options.map((lang) => ListTile(
                      leading: const Icon(Icons.language),
                      title: Text(lang),
                      onTap: () async {
                        await OnboardingService.setValue(
                            OnboardingService.keyLanguage, lang);
                        await auth.updateProfile(language: lang);
                        if (context.mounted) {
                          Navigator.pop(context);
                          context.go('/home');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Language set to $lang')),
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

    Future<void> _chooseLevel(BuildContext context) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final options = const ['Beginner', 'Intermediate', 'Advanced'];
      await showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) {
          return SafeArea(
            child: ListView(
              children: [
                const ListTile(
                  title: Text('Choose Level',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ...options.map((lvl) => ListTile(
                      leading: const Icon(Icons.school),
                      title: Text(lvl),
                      onTap: () async {
                        await auth.updateProfile(level: lvl);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Level set to $lvl')),
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

    Future<void> _chooseDailyGoal(BuildContext context) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final options = const [
        '5 minutes',
        '10 minutes',
        '15 minutes',
        '20 minutes'
      ];
      int parse(String s) => int.tryParse(s.split(' ').first) ?? 10;
      await showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) {
          return SafeArea(
            child: ListView(
              children: [
                const ListTile(
                  title: Text('Set Daily Goal',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ...options.map((g) => ListTile(
                      leading: const Icon(Icons.timelapse),
                      title: Text(g),
                      onTap: () async {
                        final minutes = parse(g);
                        await auth.updateProfile(dailyGoal: minutes);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Daily goal set to $minutes min')),
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.teal.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.teal.shade200,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials().toUpperCase(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isNotEmpty ? name : 'User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text(
                              language.isNotEmpty ? language : 'Language',
                            ),
                            avatar: const Icon(Icons.language, size: 18),
                          ),
                          Chip(
                            label: Text(level.isNotEmpty ? level : 'Level'),
                            avatar: const Icon(Icons.school, size: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              statCard('XP', xp, Icons.star, Colors.amber),
              statCard(
                  'Streak', streak, Icons.local_fire_department, Colors.red),
              statCard('Level', level.isNotEmpty ? level : '-',
                  Icons.workspace_premium, Colors.purple),
              statCard(
                  'Daily Goal', '$dailyGoal min', Icons.timelapse, Colors.blue),
            ],
          ),
          const SizedBox(height: 16),
          actionTile(
            title: 'Change Language',
            subtitle: 'Update your learning language',
            icon: Icons.language,
            onTap: () => _chooseLanguage(context),
          ),
          actionTile(
            title: 'Change Level',
            subtitle: 'Adjust your experience level',
            icon: Icons.school,
            onTap: () => _chooseLevel(context),
          ),
          actionTile(
            title: 'Set Daily Goal',
            subtitle: 'Choose your daily study time',
            icon: Icons.timelapse,
            onTap: () => _chooseDailyGoal(context),
          ),
          const SizedBox(height: 8),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Achievements',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  ListTile(
                    leading: Icon(Icons.emoji_events, color: Colors.orange),
                    title: Text('First Lesson'),
                    subtitle: Text('Completed your first lesson'),
                    trailing: Icon(Icons.check_circle, color: Colors.green),
                  ),
                  ListTile(
                    leading: Icon(Icons.emoji_events, color: Colors.deepPurple),
                    title: Text('5-Day Streak'),
                    subtitle: Text('Studied for 5 days in a row'),
                    trailing: Icon(Icons.lock, color: Colors.black26),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
