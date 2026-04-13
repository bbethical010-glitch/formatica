import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

import '../app.dart';
import '../core/theme.dart';
import '../services/file_service.dart';
import '../widgets/liquid_glass.dart';

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

  @override
  Widget build(BuildContext context) {
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHeader(context),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _sectionLabel('COGNOMEN'),
                    const SizedBox(height: 16),
                    _settingItem(
                      icon: Icons.dark_mode_outlined,
                      title: 'NOCTURNAL PROTOCOL',
                      subtitle: 'DARK MODE UI',
                      trailing: Switch(
                        value: themeNotifier.value == ThemeMode.dark,
                        activeTrackColor: AppColors.primaryIndigo,
                        inactiveTrackColor: Colors.white10,
                        onChanged: (value) async {
                          final mode = value ? ThemeMode.dark : ThemeMode.light;
                          themeNotifier.value = mode;
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('theme', value ? 'dark' : 'light');
                          setState(() {});
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    _sectionLabel('PROCESSING CORE'),
                    const SizedBox(height: 16),
                    _infoCard(
                      icon: Icons.offline_bolt_outlined,
                      color: AppColors.imageCyan,
                      title: 'HYBRID ENGINE',
                      content: 'MEDIA PROCESSING RUNS ON-DEVICE. DOCUMENTS REQUIRE SECURE EXTERNAL COMPILATION.',
                    ),
                    const SizedBox(height: 12),
                    _infoCard(
                      icon: Icons.security_rounded,
                      color: AppColors.primaryIndigo,
                      title: 'ENCLAVE SECURITY',
                      content: 'DATA IS ISOLATED PER SESSION. NO PERSISTENT TELEMETRY COLLECTED.',
                    ),

                    const SizedBox(height: 40),
                    _sectionLabel('VAULT ARCHITECTURE'),
                    const SizedBox(height: 16),
                    _settingItem(
                      icon: Icons.folder_open_outlined,
                      title: 'ROOT DIRECTORY',
                      subtitle: 'FORMATICA /',
                      trailing: IconButton(
                        icon: const Icon(Icons.open_in_new, size: 18, color: Colors.white30),
                        onPressed: () async {
                          final dir = await FileService.getBaseDirectory();
                          await FileService.showInFolder(dir.path);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _folderStructureVisual(),

                    const SizedBox(height: 40),
                    _sectionLabel('RESOURCES'),
                    const SizedBox(height: 16),
                    _settingItem(
                      icon: Icons.analytics_outlined,
                      title: 'STORAGE CONSUMPTION',
                      subtitle: _loadingStorage ? 'CALCULATING...' : '${FileService.formatFileSize(_storageUsed)} IN $_totalFiles ENTITIES',
                      onTap: _showStorageDashboard,
                      trailing: TextButton(
                        onPressed: _confirmClearStorage,
                        child: Text('PURGE', style: GoogleFonts.outfit(color: AppColors.audioRose, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    const SizedBox(height: 40),
                    _sectionLabel('AUTHORIZATIONS'),
                    const SizedBox(height: 16),
                    _permissionCard(),

                    const SizedBox(height: 40),
                    _sectionLabel('IDENTIFICATION'),
                    const SizedBox(height: 16),
                    _infoCard(
                      icon: Icons.info_outline,
                      color: AppColors.primaryIndigo,
                      title: 'FORMATICA BUILD v2.0.0',
                      content: 'NINE SYSTEM TOOLS ACTIVE. LIQUID GLASS INTERFACE ENABLED.',
                    ),
                    
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Environment',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w300,
                fontSize: 32,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'CORE SYSTEM PREFERENCES',
              style: GoogleFonts.outfit(
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 11,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryIndigo.withOpacity(0.8),
      ),
    );
  }

  Widget _settingItem({required IconData icon, required String title, required String subtitle, Widget? trailing, VoidCallback? onTap}) {
    return LiquidGlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      blur: 20,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.white70),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10, letterSpacing: 0.5),
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

  Widget _infoCard({required IconData icon, required Color color, required String title, required String content}) {
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      blur: 15,
      color: color.withOpacity(0.03),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _folderStructureVisual() {
    final subdirs = ['DOCUMENTS', 'PDFS', 'AUDIO', 'VIDEOS', 'IMAGES'];
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      blur: 10,
      color: Colors.white.withOpacity(0.01),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VAULT HIERARCHY', style: GoogleFonts.outfit(fontSize: 9, letterSpacing: 1, color: Colors.white24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          for (final dir in subdirs)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.subdirectory_arrow_right_rounded, size: 14, color: Colors.white10),
                  const SizedBox(width: 8),
                  Text(dir, style: GoogleFonts.outfit(fontSize: 11, color: Colors.white30, letterSpacing: 0.5)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _permissionCard() {
    final isGranted = _storageStatus.isGranted;
    final color = isGranted ? AppColors.imageCyan : AppColors.compressOrange;

    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      blur: 25,
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 20, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PHYSICAL STORAGE', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    Text(isGranted ? 'ACCESS GRANTED' : 'PENDING AUTHORIZATION', style: GoogleFonts.outfit(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
              ),
              if (!isGranted)
                GestureDetector(
                  onTap: _storageStatus.isPermanentlyDenied ? () => AppSettings.openAppSettings() : _requestPermission,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.primaryIndigo, borderRadius: BorderRadius.circular(10)),
                    child: Text('ALLOW', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'FORMATICA REQUIRES WRITE PRIVILEGES TO EXPORT GENERATED ASSETS TO THE SYSTEM DOWNLOADS ENCLAVE.',
            style: GoogleFonts.outfit(color: Colors.white24, fontSize: 11, height: 1.4),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: BorderSide(color: Colors.white.withOpacity(0.1))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryIndigo.withOpacity(0.1)),
                child: const Icon(Icons.storage_rounded, size: 40, color: AppColors.primaryIndigo),
              ),
              const SizedBox(height: 24),
              Text('STORAGE METRICS', style: GoogleFonts.outfit(color: Colors.white, letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.bold)),
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
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                  child: Center(child: Text('CLOSE', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
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
        Text(label, style: GoogleFonts.outfit(color: Colors.white30, fontSize: 11, letterSpacing: 0.5)),
        Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white.withOpacity(0.1))),
          title: Text('Data Purge', style: GoogleFonts.outfit(color: Colors.white)),
          content: Text('Delete all files in the Formatica vault? This action is irreversible.', style: GoogleFonts.outfit(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.white30))),
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
              child: Text('PURGE ALL', style: GoogleFonts.outfit(color: AppColors.audioRose)),
            ),
          ],
        ),
      ),
    );
  }
}








