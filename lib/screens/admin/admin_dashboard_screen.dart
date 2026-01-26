import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/admin_service.dart';
import 'sections/user_management_screen.dart';
import 'sections/content_management_screen.dart';
import 'sections/analytics_screen.dart';
import 'sections/system_admin_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    try {
      final isAdmin = await AdminService.isAdmin();
      if (!mounted) return;
      
      setState(() {
        _isAdmin = isAdmin;
        _isLoading = false;
      });

      if (!isAdmin) {
        if (mounted) {
          context.go('/home');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access denied. Admin privileges required.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isAdmin = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking admin access: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        context.go('/home');
      }
    }
  }

  final List<AdminSection> _sections = [
    AdminSection(
      title: 'User Management',
      icon: Icons.people,
      screen: const UserManagementScreen(),
    ),
    AdminSection(
      title: 'Content Management',
      icon: Icons.library_books,
      screen: const ContentManagementScreen(),
    ),
    AdminSection(
      title: 'Analytics',
      icon: Icons.analytics,
      screen: const AnalyticsScreen(),
    ),
    AdminSection(
      title: 'System Admin',
      icon: Icons.settings,
      screen: const SystemAdminScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text('Access Denied'),
        ),
      );
    }

    final isDesktop = MediaQuery.of(context).size.width >= 600;

    if (isDesktop) {
      return _buildDesktopLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: _sections
                .map((section) => NavigationRailDestination(
                      icon: Icon(section.icon),
                      label: Text(section.title),
                    ))
                .toList(),
            leading: Column(
              children: [
                const SizedBox(height: 16),
                IconButton(
                  icon: const Icon(Icons.home),
                  onPressed: () => context.go('/home'),
                  tooltip: 'Back to Home',
                ),
                const SizedBox(height: 8),
                const Divider(),
              ],
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Admin Dashboard',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          // Main content
          Expanded(
            child: _sections[_selectedIndex].screen,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      body: _sections[_selectedIndex].screen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: _sections
            .map((section) => NavigationDestination(
                  icon: Icon(section.icon),
                  label: section.title,
                ))
            .toList(),
      ),
      appBar: AppBar(
        title: Text(_sections[_selectedIndex].title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
    );
  }
}

class AdminSection {
  final String title;
  final IconData icon;
  final Widget screen;

  AdminSection({
    required this.title,
    required this.icon,
    required this.screen,
  });
}

