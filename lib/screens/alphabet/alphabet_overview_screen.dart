import 'package:flutter/material.dart';
import 'package:lanet_mobile/providers/fidel_provider.dart';
import 'package:lanet_mobile/widgets/fidel_tile.dart';
import 'package:lanet_mobile/widgets/pattern_background.dart';
import 'package:provider/provider.dart';

import 'alphabet_family_screen.dart';
import '../../services/onboarding_service.dart';

class AlphabetOverviewScreen extends StatefulWidget {
  const AlphabetOverviewScreen({super.key});

  @override
  State<AlphabetOverviewScreen> createState() => _AlphabetOverviewScreenState();
}

class _AlphabetOverviewScreenState extends State<AlphabetOverviewScreen> {
  String? _userLanguage;

  @override
  void initState() {
    super.initState();
    _loadUserLanguage();
  }

  Future<void> _loadUserLanguage() async {
    final language = await OnboardingService.getValue(OnboardingService.keyLanguage);
    setState(() {
      _userLanguage = language;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fidelProvider = Provider.of<FidelProvider>(context);
    final leadingFamilies = fidelProvider.leadingFamilies;

    return PatternBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('${_userLanguage ?? 'Ethiopian'} Alphabet'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: leadingFamilies.length,
          itemBuilder: (context, index) {
            final item = leadingFamilies[index];
            return FidelTile(
              fidel: item,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AlphabetFamilyScreen(family: item.family),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
