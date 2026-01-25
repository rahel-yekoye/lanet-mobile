import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/onboarding_service.dart';
import '../../widgets/onboarding_scaffold.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  final languages = const ["Amharic", "Tigrinya", "Oromo"];

  Color _getLanguageColor(String language) {
    switch (language.toLowerCase()) {
      case 'amharic':
        return Colors.blue.shade100.withOpacity(0.4);
      case 'tigrinya':
        return Colors.green.shade100.withOpacity(0.4);
      case 'oromo':
        return Colors.orange.shade100.withOpacity(0.4);
      default:
        return Colors.purple.shade100.withOpacity(0.4);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'Choose your language',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Your Language',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose the language you want to learn',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...languages
                      .map((lang) => _buildLanguageOption(lang, context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String language, BuildContext context) {
    IconData icon;
    Color iconColor;

    switch (language.toLowerCase()) {
      case 'amharic':
        icon = Icons.language;
        iconColor = Colors.blue;
        break;
      case 'tigrinya':
        icon = Icons.translate;
        iconColor = Colors.green;
        break;
      case 'oromo':
        icon = Icons.record_voice_over;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.question_mark;
        iconColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          language,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () async {
          print('DEBUG: Language Selected: $language');
          await OnboardingService.setValue(
              OnboardingService.keyLanguage, language);

          // Incrementally save to backend so we don't lose progress if user drops off
          try {
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            await authProvider.updateProfile(language: language);
          } catch (e) {
            debugPrint('Error saving language incrementally: $e');
          }

          if (context.mounted) {
            context.push('/onboarding/level');
          }
        },
      ),
    );
  }
}
