import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/sms_reader/presentation/sms_ledger_screen.dart';
import '../features/voice_entry/presentation/voice_entry_screen.dart';
import '../features/manual_entry/presentation/manual_entry_screen.dart';

/// Main home screen with bottom navigation.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    DashboardScreen(),
    SmsLedgerScreen(),
    VoiceEntryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Request SMS permission
    final smsStatus = await Permission.sms.request();
    if (smsStatus.isDenied && mounted) {
      _showPermissionDialog('SMS', 'read your bank messages to auto-track expenses');
    }

    // Request microphone permission for voice entry
    final micStatus = await Permission.microphone.request();
    if (micStatus.isDenied && mounted) {
      _showPermissionDialog('Microphone', 'use voice commands to add expenses');
    }
  }

  void _showPermissionDialog(String permission, String reason) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permission Permission Required'),
        content: Text(
          'This app needs $permission permission to $reason. '
          'Please grant the permission in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _openManualEntry() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ManualEntryScreen()),
    );
    
    // Refresh dashboard if expense was added
    if (result == true && _currentIndex == 0) {
      setState(() {}); // Trigger rebuild to refresh dashboard
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.sms_outlined),
            selectedIcon: Icon(Icons.sms),
            label: 'SMS',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_outlined),
            selectedIcon: Icon(Icons.mic),
            label: 'Voice',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openManualEntry,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}
