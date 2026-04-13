import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/task_provider.dart';
import '../services/file_service.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/signature_dock.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

/// Root shell with the "Liquid Glass" Signature Dock.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FileService.requestInitialPermissions();
    });
  }

  static const _tabs = <Widget>[
    HomeScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent, 
        extendBody: true,
        body: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
        bottomNavigationBar: SignatureDock(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            DockItem(
              icon: Icons.grid_view_outlined,
              activeIcon: Icons.grid_view_rounded,
              label: 'Studio',
            ),
            DockItem(
              icon: Icons.auto_awesome_motion_outlined,
              activeIcon: Icons.auto_awesome_motion_rounded,
              label: 'History',
            ),
            DockItem(
              icon: Icons.tune_outlined,
              activeIcon: Icons.tune_rounded,
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}








