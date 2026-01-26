import 'package:flutter/material.dart';
import '../../../models/admin_models.dart';
import '../../../services/admin_service.dart';

class UserDetailDialog extends StatefulWidget {
  final AdminUser user;

  const UserDetailDialog({super.key, required this.user});

  @override
  State<UserDetailDialog> createState() => _UserDetailDialogState();
}

class _UserDetailDialogState extends State<UserDetailDialog> {
  List<Map<String, dynamic>> _completedLessons = [];
  bool _isLoadingLessons = true;

  @override
  void initState() {
    super.initState();
    _loadUserLessons();
  }

  Future<void> _loadUserLessons() async {
    setState(() => _isLoadingLessons = true);
    try {
      final lessons = await AdminService.getUserCompletedLessons(widget.user.id);
      setState(() {
        _completedLessons = lessons;
        _isLoadingLessons = false;
      });
    } catch (e) {
      setState(() => _isLoadingLessons = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading lessons: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.name ?? 'No Name',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        widget.user.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 32),
            
            // User Stats
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildStatCard(
                  context,
                  'Role',
                  widget.user.role.toUpperCase(),
                  Icons.person,
                  Colors.blue,
                ),
                _buildStatCard(
                  context,
                  'Lessons Completed',
                  widget.user.lessonsCompleted.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatCard(
                  context,
                  'Total Time',
                  '${(widget.user.totalTimeSeconds / 60).toStringAsFixed(0)} min',
                  Icons.timer,
                  Colors.orange,
                ),
                if (widget.user.preferredLanguage != null)
                  _buildStatCard(
                    context,
                    'Language',
                    widget.user.preferredLanguage!,
                    Icons.language,
                    Colors.purple,
                  ),
                _buildStatCard(
                  context,
                  'Status',
                  widget.user.blocked ? 'Blocked' : 'Active',
                  widget.user.blocked ? Icons.block : Icons.check_circle,
                  widget.user.blocked ? Colors.red : Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Completed Lessons List
            Text(
              'Completed Lessons (${_completedLessons.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoadingLessons
                  ? const Center(child: CircularProgressIndicator())
                  : _completedLessons.isEmpty
                      ? const Center(
                          child: Text('No lessons completed yet'),
                        )
                      : ListView.builder(
                          itemCount: _completedLessons.length,
                          itemBuilder: (context, index) {
                            final lesson = _completedLessons[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.book, color: Colors.teal),
                                title: Text(lesson['title'] ?? 'Unknown Lesson'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (lesson['category'] != null)
                                      Text('Category: ${lesson['category']}'),
                                    if (lesson['score'] != null)
                                      Text('Score: ${lesson['score']}/100'),
                                    if (lesson['completed_at'] != null)
                                      Text(
                                        'Completed: ${_formatDate(lesson['completed_at'])}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    try {
      final dt = date is String ? DateTime.parse(date) : date as DateTime;
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return date.toString();
    }
  }
}

