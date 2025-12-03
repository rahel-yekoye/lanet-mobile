import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lesson_provider.dart';
import 'category_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LessonProvider>(context);
    if (lp.loading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: Text('Lanet — Learn Languages')),
      body: ListView.builder(
        itemCount: lp.categories.length,
        itemBuilder: (context, i) {
          final cat = lp.categories[i];
          final count = lp.phrasesFor(cat).length;
          return ListTile(
            title: Text(cat),
            subtitle: Text('$count phrases'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryScreen(category: cat)));
            },
          );
        },
      ),
    );
  }
}
