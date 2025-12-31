import 'package:flutter/material.dart';
import 'package:lanet_mobile/providers/fidel_provider.dart';
import 'package:lanet_mobile/widgets/fidel_tile.dart';
import 'package:lanet_mobile/widgets/pattern_background.dart';
import 'package:provider/provider.dart';

import 'alphabet_family_screen.dart';

class AlphabetOverviewScreen extends StatelessWidget {
  const AlphabetOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fidelProvider = Provider.of<FidelProvider>(context);
    final leadingFamilies = fidelProvider.leadingFamilies;

    return PatternBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Amharic Alphabet'),
          backgroundColor: Colors.transparent,
          elevation: 0,
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
