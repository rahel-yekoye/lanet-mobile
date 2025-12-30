import 'package:flutter/material.dart';
import 'package:lanet_mobile/providers/fidel_provider.dart';
import 'package:lanet_mobile/widgets/fidel_tile.dart';
import 'package:provider/provider.dart';

import 'alphabet_family_screen.dart';

class AlphabetOverviewScreen extends StatelessWidget {
  const AlphabetOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FidelProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Amharic Alphabet'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: provider.leadingFamilies.length,
        itemBuilder: (context, index) {
          final item = provider.leadingFamilies[index];

          return FidelTile(
            fidel: item,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      AlphabetFamilyScreen(family: item.family),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
