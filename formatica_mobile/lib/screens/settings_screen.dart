import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'dart:ui';

import '../app.dart';
import '../core/theme.dart';
import '../services/file_service.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/top_bar.dart';
import '../widgets/theme_face_toggle.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _storageUsed = 0;
  int _totalFiles = 0;
  bool _loadingStorage = true;
  PermissionStatus _storageStatus = PermissionStatus.denied;
  bool _loadingPermission = true;

  @override
  void initState() {
    super.initState();
    _loadInfo();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _loadingPermission = true);
    final status = await FileService.getStoragePermissionStatus();
    if (mounted) {
      setState(() {
        _storageStatus = status;
        _loadingPermission = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    await FileService.ensureStoragePermission(context);
    await _checkPermissions();
  }

  Future<void> _loadInfo() async {
    final stats = await FileService.getStorageStats();
    if (mounted) {
      setState(() {
        _storageUsed = stats['size'] ?? 0;
        _totalFiles = stats['count'] ?? 0;
        _loadingStorage = false;
      });
    }
  }

  Future<void> _toggleTheme() async {
    final isDark = themeNotifier.value == ThemeMode.dark;
    final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
    themeNotifier.value = newMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', isDark ? 'light' : 'dark');
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: StudioTopBar(
          title: 'Environment',
          onBack: () => Navigator.pop(context),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('COGNOMEN'),
                const SizedBox(height: 16),
                _settingItem(
                  isDark: isDark,
                  icon: Icons.dark_mode_rounded,
                  title: 'NOCTURNAL PROTOCOL',
                  subtitle: 'DARK MODE UI INTERFACE',
                  trailing: ThemeFaceToggle(
                    isDark: isDark,
                    onToggle: _toggleTheme,
                  ),
                ),
                
                const SizedBox(height: 40),
                _sectionLabel('PROCESSING CORE'),
                const SizedBox(height: 16),
                _infoCard(
                  isDark: isDark,
                  icon: Icons.offline_bolt_rounded,
                  color: AppColors.imageCyan,
                  title: 'HYBRID ENGINE',
                  content: 'MEDIA PROCESSING RUNS ON-DEVICE. DOCUMENTS REQUIRE SECURE EXTERNAL COMPILATION.',
                ),
                const SizedBox(height: 12),
                _infoCard(
                  isDark: isDark,
                  icon: Icons.security_rounded,
                  color: AppColors.docIndigo,
                  title: 'ENCLAVE SECURITY',
                  content: 'DATA IS ISOLATED PER SESSION. NO PERSISTENT TELEMETRY COLLECTED.',
                ),

                const SizedBox(height: 40),
                _sectionLabel('VAULT ARCHITECTURE'),
                const SizedBox(height: 16),
                _settingItem(
                  isDark: isDark,
                  icon: Icons.folder_open_rounded,
                  title: 'ROOT DIRECTORY',
                  subtitle: 'INTERNAL STORAGE / FORMATICA',
                  trailing: IconButton(
                    icon: Icon(Icons.open_in_new_rounded, size: 18, color: isDark ? Colors.white24 : Colors.black26),
                    onPressed: () async {
                      final dir = await FileService.getBaseDirectory();
                      await FileService.showInFolder(dir.path);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _folderStructureVisual(isDark),

                const SizedBox(height: 40),
                _sectionLabel('RESOURCES'),
                const SizedBox(height: 16),
                _settingItem(
                  isDark: isDark,
                  icon: Icons.analytics_rounded,
                  title: 'STORAGE CONSUMPTION',
                  subtitle: _loadingStorage ? 'CALCULATING...' : '${FileService.formatFileSize(_storageUsed)} IN $_totalFiles ENTITIES',
                  onTap: _showStorageDashboard,
                  trailing: GestureDetector(
                    onTap: _confirmClearStorage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.audioRose.withOpacity(0.1),
                      ),
                      child: Text(
                        'PURGE', 
                        style: AppTextStyles.studioLabel.copyWith(
                          color: AppColors.audioRose, 
                          fontSize: 9, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
                _sectionLabel('AUTHORIZATIONS'),
                const SizedBox(height: 16),
                _permissionCard(isDark),

                const SizedBox(height: 40),
                _sectionLabel('IDENTIFICATION'),
                const SizedBox(height: 16),
                _infoCard(
                  isDark: isDark,
                  icon: Icons.info_outline_rounded,
                  color: AppColors.docIndigo,
                  title: 'FORMATICA BUILD v2.0.0',
                  content: 'NINE SYSTEM TOOLS ACTIVE. LIQUID GLASS INTERFACE ENABLED.',
                ),
                
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.studioLabel.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: AppColors.docIndigo.withOpacity(0.8),
      ),
    );
  }

  Widget _settingItem({required bool isDark, required IconData icon, required String title, required String subtitle, Widget? trailing, VoidCallback? onTap}) {
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      blur: 25,
      color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 20, color: isDark ? Colors.white54 : Colors.black45),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? Colors.white : Colors.black87, 
                      fontSize: 13, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? Colors.white38 : Colors.black26, 
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _infoCard({required bool isDark, required IconData icon, required Color color, required String title, required String content}) {
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      blur: 15,
      color: color.withOpacity(0.05),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.studioLabel.copyWith(
                    color: color, 
                    fontSize: 11, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? Colors.white60 : Colors.black54, 
                    fontSize: 12, 
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _folderStructureVisual(bool isDark) {
    final subdirs = ['DOCUMENTS', 'PDFS', 'AUDIO', 'VIDEOS', 'IMAGES'];
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      blur: 10,
      color: isDark ? Colors.white.withOpacity(0.01) : Colors.black.withOpacity(0.01),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VAULT HIERARCHY', 
            style: AppTextStyles.studioLabel.copyWith(
              fontSize: 9, 
              color: isDark ? Colors.white24 : Colors.black26, 
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          for (final dir in subdirs)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.subdirectory_arrow_right_rounded, 
                    size: 14, 
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    dir, 
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 11, 
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _permissionCard(bool isDark) {
    final isGranted = _storageStatus.isGranted;
    final color = isGranted ? AppColors.imageCyan : AppColors.compressOrange;

    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      blur: 25,
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded, size: 20, color: color),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PHYSICAL STORAGE', 
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark ? Colors.white : Colors.black87, 
                        fontSize: 13, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isGranted ? 'ACCESS GRANTED' : 'PENDING AUTHORIZATION', 
                      style: AppTextStyles.studioLabel.copyWith(
                        color: color, 
                        fontSize: 10, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isGranted)
                GestureDetector(
                  onTap: _storageStatus.isPermanentlyDenied ? () => AppSettings.openAppSettings() : _requestPermission,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.docIndigo, 
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'ALLOW', 
                      style: AppTextStyles.studioLabel.copyWith(
                        color: Colors.white, 
                        fontSize: 11, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'FORMATICA REQUIRES WRITE PRIVILEGES TO EXPORT GENERATED ASSETS TO THE SYSTEM DOWNLOADS ENCLAVE.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? Colors.white24 : Colors.black26, 
              fontSize: 11, 
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _showStorageDashboard() {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), 
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle, 
                  color: AppColors.docIndigo.withOpacity(0.1),
                ),
                child: const Icon(Icons.storage_rounded, size: 40, color: AppColors.docIndigo),
              ),
              const SizedBox(height: 24),
              Text(
                'STORAGE METRICS', 
                style: AppTextStyles.studioLabel.copyWith(
                  color: Colors.white, 
                  letterSpacing: 2, 
                  fontSize: 12, 
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              _metricRow('VOLUME USED', FileService.formatFileSize(_storageUsed)),
              const SizedBox(height: 16),
              _metricRow('TOTAL ENTITIES', '$_totalFiles'),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05), 
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'CLOSE', 
                      style: AppTextStyles.studioLabel.copyWith(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label, 
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white38, fontSize: 11),
        ),
        Text(
          value, 
          style: AppTextStyles.headlineSmall.copyWith(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _confirmClearStorage() {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), 
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          title: Text(
            'Data Purge', 
            style: AppTextStyles.headlineSmall.copyWith(color: Colors.white, fontSize: 18),
          ),
          content: Text(
            'Delete all files in the Formatica vault? This action is irreversible.', 
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: Text(
                'CANCEL', 
                style: AppTextStyles.studioLabel.copyWith(color: Colors.white38),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final dir = await FileService.getBaseDirectory();
                  if (await dir.exists()) {
                    await dir.delete(recursive: true);
                    await dir.create(recursive: true);
                  }
                  await _loadInfo();
                } catch (e) {}
              },
              child: Text(
                'PURGE ALL', 
                style: AppTextStyles.studioLabel.copyWith(color: AppColors.audioRose),
              ),
            ),
          ],
        ),
      ),
    );
  }
}








