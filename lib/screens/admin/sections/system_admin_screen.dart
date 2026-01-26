import 'package:flutter/material.dart';
import '../../../services/admin_service.dart';

class SystemAdminScreen extends StatefulWidget {
  const SystemAdminScreen({super.key});

  @override
  State<SystemAdminScreen> createState() => _SystemAdminScreenState();
}

class _SystemAdminScreenState extends State<SystemAdminScreen> {
  bool _maintenanceMode = false;
  bool _welcomeMessageEnabled = true;
  String _welcomeMessage = '';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final maintenance = await AdminService.getSetting('maintenance_mode');
      final welcome = await AdminService.getSetting('welcome_message');

      setState(() {
        _maintenanceMode = (maintenance as Map<String, dynamic>?)?['enabled'] as bool? ?? false;
        _welcomeMessageEnabled = (welcome as Map<String, dynamic>?)?['enabled'] as bool? ?? true;
        _welcomeMessage = (welcome)?['message'] as String? ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    }
  }

  Future<void> _saveMaintenanceMode(bool value) async {
    setState(() => _isSaving = true);
    try {
      await AdminService.updateSetting('maintenance_mode', {'enabled': value});
      setState(() {
        _maintenanceMode = value;
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? 'Maintenance mode enabled' : 'Maintenance mode disabled'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  Future<void> _saveWelcomeMessage() async {
    setState(() => _isSaving = true);
    try {
      await AdminService.updateSetting('welcome_message', {
        'enabled': _welcomeMessageEnabled,
        'message': _welcomeMessage,
      });
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome message saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  Future<void> _sendNotification() async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String selectedType = 'info';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Send Notification'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    label: Text('Title'),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    label: Text('Message'),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    label: Text('Type'),
                    border: OutlineInputBorder(),
                  ),
                  items: ['info', 'warning', 'success', 'error']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedType = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    messageController.text.isNotEmpty) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        await AdminService.sendBroadcastNotification(
          title: titleController.text,
          message: messageController.text,
          type: selectedType,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification sent to all users'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send notification: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Administration'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Maintenance Mode Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Maintenance Mode',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Switch(
                        value: _maintenanceMode,
                        onChanged: _isSaving ? null : _saveMaintenanceMode,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When enabled, the app will be in maintenance mode and users will see a maintenance message.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Welcome Message Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Message',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Welcome Message'),
                    value: _welcomeMessageEnabled,
                    onChanged: (value) {
                      setState(() => _welcomeMessageEnabled = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      label: Text('Message'),
                      border: OutlineInputBorder(),
                      hintText: 'Welcome to LaNet! Start your language learning journey today.',
                    ),
                    maxLines: 3,
                    enabled: _welcomeMessageEnabled,
                    controller: TextEditingController(text: _welcomeMessage),
                    onChanged: (value) => _welcomeMessage = value,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _isSaving ? null : _saveWelcomeMessage,
                    child: const Text('Save Welcome Message'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Notifications Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Broadcast Notification',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Send a notification to all users',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(Icons.notifications),
                    label: const Text('Send Notification'),
                    onPressed: _sendNotification,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // System Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const ListTile(
                    title: Text('App Version'),
                    subtitle: Text('1.0.0'),
                    leading: Icon(Icons.info),
                  ),
                  const ListTile(
                    title: Text('Database'),
                    subtitle: Text('Supabase'),
                    leading: Icon(Icons.storage),
                  ),
                  const ListTile(
                    title: Text('Storage'),
                    subtitle: Text('Supabase Storage'),
                    leading: Icon(Icons.cloud_upload),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

