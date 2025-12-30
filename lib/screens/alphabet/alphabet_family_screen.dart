// lib/screens/alphabet/alphabet_family_screen.dart
import 'package:flutter/material.dart';
import 'package:lanet_mobile/providers/fidel_provider.dart';
import 'package:lanet_mobile/theme/theme.dart';
import 'package:provider/provider.dart';

class AlphabetFamilyScreen extends StatelessWidget {
  final String family;

  const AlphabetFamilyScreen({required this.family, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FidelProvider>();
    final familyItems = provider.family(family);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          family.toUpperCase(),
          style: AppTheme.appBarTitleStyle,
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: familyItems.length,
        itemBuilder: (context, index) {
          final fidel = familyItems[index];
          return Card(
            child: InkWell(
              onTap: () {
                // Handle tap
              },
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    fidel.character,
                    style: AppTheme.characterStyle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fidel.transliteration,
                    style: AppTheme.transliterationStyle,
                  ),
                  if (fidel.vowel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      fidel.vowel,
                      style: AppTheme.vowelStyle,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}