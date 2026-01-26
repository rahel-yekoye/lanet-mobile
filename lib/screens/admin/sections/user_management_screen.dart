import 'package:flutter/material.dart';
import '../../../models/admin_models.dart';
import '../../../services/admin_service.dart';
import 'user_detail_dialog.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<AdminUser> _users = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  int _currentPage = 0;
  final int _pageSize = 20;
  int _totalUsersCount = 0; // Total users count from database

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load total users count from analytics (only if not searching)
      if (_searchQuery.isEmpty) {
        try {
          final analytics = await AdminService.getAnalytics();
          _totalUsersCount = analytics['totalUsers'] as int? ?? 0;
        } catch (e) {
          debugPrint('Error fetching total users count: $e');
          // Continue with user list loading even if count fails
        }
      }

      // Load users list
      final usersData = await AdminService.getUsers(
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );

      setState(() {
        _users = usersData.map((u) => AdminUser.fromJson(u)).toList();
        // If searching, show search results count but don't reset total
        // The total users count should remain at 19 (or whatever it was)
        // Only update if we got results and want to show "X results found"
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBlock(AdminUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.blocked ? 'Unblock User' : 'Block User'),
        content: Text(
          user.blocked
              ? 'Are you sure you want to unblock ${user.email}?'
              : 'Are you sure you want to block ${user.email}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(user.blocked ? 'Unblock' : 'Block'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await AdminService.toggleUserBlock(user.id, !user.blocked);
      if (success) {
        _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                user.blocked ? 'User unblocked' : 'User blocked',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update user'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalLessonsCompleted = _users.fold<int>(
      0,
      (sum, user) => sum + user.lessonsCompleted,
    );
    // Always show the total users count from database (19)
    // When searching, the count stays the same, only the list changes
    final totalUsers = _totalUsersCount;

    return Scaffold(
      body: Column(
        children: [
          // Summary Cards
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    'Total Users',
                    totalUsers.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    'Lessons Completed',
                    totalLessonsCompleted.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by email or name...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      helperText: 'Shows all registered users (students and admins)',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _currentPage = 0;
                      });
                      // Debounce search
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (_searchQuery == value && mounted) {
                          _loadUsers();
                        }
                      });
                    },
                    onSubmitted: (_) => _loadUsers(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadUsers,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          // Users list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error Loading Users',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _loadUsers,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _users.isEmpty
                        ? const Center(child: Text('No users found'))
                        : ListView.builder(
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: user.blocked
                                        ? Colors.red.shade100
                                        : Colors.teal.shade100,
                                    child: Icon(
                                      user.blocked
                                          ? Icons.block
                                          : Icons.person,
                                      color: user.blocked
                                          ? Colors.red
                                          : Colors.teal,
                                    ),
                                  ),
                                  title: Text(
                                    user.email,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (user.name != null && user.name!.isNotEmpty)
                                        Text(
                                          user.name!,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Chip(
                                            label: Text(
                                              user.role.toUpperCase(),
                                              style: const TextStyle(fontSize: 11),
                                            ),
                                            labelStyle: TextStyle(
                                              color: user.role == 'admin'
                                                  ? Colors.purple
                                                  : Colors.blue,
                                            ),
                                            backgroundColor: user.role == 'admin'
                                                ? Colors.purple.shade50
                                                : Colors.blue.shade50,
                                          ),
                                          const SizedBox(width: 8),
                                          Chip(
                                            label: Text(
                                              '${user.lessonsCompleted} lessons',
                                              style: const TextStyle(fontSize: 11),
                                            ),
                                            labelStyle: const TextStyle(color: Colors.green),
                                            backgroundColor: Colors.green.shade50,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Time: ${(user.totalTimeSeconds / 60).toStringAsFixed(0)} min',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (user.preferredLanguage != null)
                                        Text(
                                          'Language: ${user.preferredLanguage}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.info_outline),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => UserDetailDialog(user: user),
                                          );
                                        },
                                        tooltip: 'View Details',
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          user.blocked
                                              ? Icons.check_circle
                                              : Icons.block,
                                          color: user.blocked
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                        onPressed: () => _toggleBlock(user),
                                        tooltip: user.blocked
                                            ? 'Unblock'
                                            : 'Block',
                                      ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => UserDetailDialog(user: user),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
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
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

