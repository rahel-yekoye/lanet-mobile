import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/admin_models.dart';
import '../../../services/admin_service.dart';
import 'lesson_form_screen.dart';

class LessonsListScreen extends StatefulWidget {
  final VoidCallback? onDataChanged;
  
  const LessonsListScreen({super.key, this.onDataChanged});

  @override
  State<LessonsListScreen> createState() => _LessonsListScreenState();
}

class _LessonsListScreenState extends State<LessonsListScreen> {
  List<Lesson> _lessons = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String? _statusFilter;
  String? _languageFilter;
  int _currentPage = 1;
  final int _pageSize = 20;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await AdminService.getLessons(
        page: _currentPage,
        pageSize: _pageSize,
        status: _statusFilter,
        language: _languageFilter,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );

      setState(() {
        _lessons = result['lessons'] as List<Lesson>;
        _total = result['total'] as int;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteLesson(Lesson lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: Text('Are you sure you want to delete "${lesson.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminService.deleteLesson(lesson.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lesson deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadLessons();
          widget.onDataChanged?.call();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete lesson: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search and Filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    label: const Text('Search lessons'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => _searchQuery = '');
                              _loadLessons();
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                  onSubmitted: (_) => _loadLessons(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _statusFilter,
                        decoration: const InputDecoration(
                          label: Text('Status'),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All Statuses')),
                          DropdownMenuItem(value: 'draft', child: Text('Draft')),
                          DropdownMenuItem(value: 'published', child: Text('Published')),
                          DropdownMenuItem(value: 'archived', child: Text('Archived')),
                        ],
                        onChanged: (value) {
                          setState(() => _statusFilter = value);
                          _loadLessons();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _languageFilter,
                        decoration: const InputDecoration(
                          label: Text('Language'),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All Languages')),
                          DropdownMenuItem(value: 'Amharic', child: Text('Amharic')),
                          DropdownMenuItem(value: 'Tigrinya', child: Text('Tigrinya')),
                          DropdownMenuItem(value: 'Afaan Oromo', child: Text('Afaan Oromo')),
                        ],
                        onChanged: (value) {
                          setState(() => _languageFilter = value);
                          _loadLessons();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Lessons List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: $_error'),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _loadLessons,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _lessons.isEmpty
                        ? const Center(child: Text('No lessons found'))
                        : Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _lessons.length,
                                  itemBuilder: (context, index) {
                                    final lesson = _lessons[index];
                                    return _buildLessonCard(lesson);
                                  },
                                ),
                              ),
                              // Pagination
                              if (_total > _pageSize)
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.chevron_left),
                                        onPressed: _currentPage > 1
                                            ? () {
                                                setState(() => _currentPage--);
                                                _loadLessons();
                                              }
                                            : null,
                                      ),
                                      Text('Page $_currentPage of ${(_total / _pageSize).ceil()}'),
                                      IconButton(
                                        icon: const Icon(Icons.chevron_right),
                                        onPressed: _currentPage < (_total / _pageSize).ceil()
                                            ? () {
                                                setState(() => _currentPage++);
                                                _loadLessons();
                                              }
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/admin/lessons/new').then((_) {
            _loadLessons();
            widget.onDataChanged?.call();
          });
        },
        tooltip: 'Create New Lesson',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLessonCard(Lesson lesson) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(lesson.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lesson.description ?? 'No description'),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(lesson.language),
                  labelStyle: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(_getDifficultyLabel(lesson.difficulty)),
                  labelStyle: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(lesson.status.toUpperCase()),
                  labelStyle: const TextStyle(fontSize: 12),
                  backgroundColor: _getStatusColor(lesson.status),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              context.push('/admin/lessons/${lesson.id}').then((_) {
                _loadLessons();
                widget.onDataChanged?.call();
              });
            } else if (value == 'delete') {
              _deleteLesson(lesson);
            }
          },
        ),
        onTap: () {
          context.push('/admin/lessons/${lesson.id}').then((_) {
            _loadLessons();
            widget.onDataChanged?.call();
          });
        },
      ),
    );
  }

  String _getDifficultyLabel(int difficulty) {
    switch (difficulty) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Intermediate';
      case 3:
        return 'Advanced';
      default:
        return 'Unknown';
    }
  }

  Color? _getStatusColor(String status) {
    switch (status) {
      case 'published':
        return Colors.green.shade100;
      case 'draft':
        return Colors.orange.shade100;
      case 'archived':
        return Colors.grey.shade300;
      default:
        return null;
    }
  }
}

