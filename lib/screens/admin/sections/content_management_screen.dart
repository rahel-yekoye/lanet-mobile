import 'package:flutter/material.dart';
import '../../../services/admin_service.dart';
import 'lessons_list_screen.dart';
import 'categories_list_screen.dart';

class ContentManagementScreen extends StatefulWidget {
  const ContentManagementScreen({super.key});

  @override
  State<ContentManagementScreen> createState() => _ContentManagementScreenState();
}

class _ContentManagementScreenState extends State<ContentManagementScreen> {
  int _selectedTab = 0;
  int _totalLessons = 0;
  int _totalCategories = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final lessonsResult = await AdminService.getLessons(page: 1, pageSize: 1);
      final categories = await AdminService.getCategories();
      
      setState(() {
        _totalLessons = lessonsResult['total'] as int? ?? 0;
        _totalCategories = categories.length;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() => _isLoadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Content Management'),
          bottom: TabBar(
            onTap: (index) {
              setState(() => _selectedTab = index);
            },
            tabs: [
              Tab(
                icon: const Icon(Icons.library_books),
                text: _isLoadingStats
                    ? 'Lessons'
                    : 'Lessons ($_totalLessons)',
              ),
              Tab(
                icon: const Icon(Icons.category),
                text: _isLoadingStats
                    ? 'Categories'
                    : 'Categories ($_totalCategories)',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            LessonsListScreen(onDataChanged: _loadStats),
            CategoriesListScreen(onDataChanged: _loadStats),
          ],
        ),
      ),
    );
  }
}

