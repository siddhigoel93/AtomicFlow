import 'package:flutter/material.dart';
import '../../../habits/presentation/widgets/bottom_nav.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Preferences'),
          Card(
            elevation: 0,
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(Icons.notifications_outlined, color: Theme.of(context).colorScheme.primary),
                  title: const Text('Habit Reminders', style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text('Get notified to complete your daily habits'),
                  value: _notificationsEnabled,
                  onChanged: (val) {
                    setState(() => _notificationsEnabled = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Support & Info'),
          Card(
            elevation: 0,
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.blue),
                  title: const Text('App Version', style: TextStyle(fontWeight: FontWeight.w500)),
                  trailing: const Text('1.0.0', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.favorite_outline, color: Colors.red),
                  title: const Text('About AtomicFlow', style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text('Built with love for building habits'),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(selectedIndex: 3),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
