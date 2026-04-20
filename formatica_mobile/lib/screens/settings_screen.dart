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
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: StudioTopBar(
        title: 'Settings',
        onBack: () => Navigator.pop(context),
      ),
      body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SECTION 1 - APPEARANCE
                _sectionLabel('APPEARANCE'),
                _glassCard(
                  children: [
                    _settingRow(
                      icon: Icons.dark_mode_outlined,
                      iconColor: Colors.indigoAccent,
                      label: 'Theme',
                      sublabel: isDark ? 'Dark Mode Active' : 'Light Mode Active',
                      trailing: ThemeFaceToggle(
                        isDark: isDark,
                        onToggle: _toggleTheme,
                      ),
                    ),
                    _divider(),
                    _settingRow(
                      icon: Icons.palette_outlined,
                      iconColor: Colors.indigoAccent,
                      label: 'Accent Color',
                      sublabel: 'Highlight used across tools',
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          _colorDot(AppColors.docIndigo, true),
                          _colorDot(AppColors.audioRose, false),
                          _colorDot(AppColors.mergeTeal, false),
                          _colorDot(AppColors.compressOrange, false),
                          _colorDot(AppColors.videoPurple, false),
                        ],
                      ),
                    ),
                    _divider(),
                    _settingRow(
                      icon: Icons.vibration_outlined,
                      iconColor: AppColors.videoPurple,
                      label: 'Haptic Feedback',
                      sublabel: 'Micro-vibrations on interactions',
                      trailing: _toggle(true),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                // SECTION 2 - OUTPUT
                _sectionLabel('OUTPUT'),
                _glassCard(
                  children: [
                    _settingRow(
                      icon: Icons.folder_outlined,
                      iconColor: AppColors.mergeTeal,
                      label: 'Output Folder',
                      sublabel: '/Documents/Formatica',
                      sublabelColor: AppColors.mergeTeal,
                      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                    ),
                    _divider(),
                    _settingRow(
                      icon: Icons.folder_open_outlined,
                      iconColor: AppColors.mergeTeal,
                      label: 'Open After Convert',
                      sublabel: 'Show output file when done',
                      trailing: _toggle(true),
                    ),
                    _divider(),
                    _settingRow(
                      icon: Icons.file_copy_outlined,
                      iconColor: AppColors.greySlate,
                      label: 'Overwrite Existing Files',
                      sublabel: 'Replace files with same name',
                      trailing: _toggle(false),
                    ),
                    _divider(),
                    _settingRow(
                      icon: Icons.storage_outlined,
                      iconColor: AppColors.greySlate,
                      label: 'Storage Used',
                      sublabel: 'Output folder size',
                      trailing: Text(
                        FileService.formatFileSize(_storageUsed),
                        style: const TextStyle(color: AppColors.mergeTeal, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(52, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: 0.35,
                              minHeight: 4,
                              backgroundColor: Colors.white.withOpacity(0.08),
                              valueColor: const AlwaysStoppedAnimation(AppColors.docIndigo),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${FileService.formatFileSize(_storageUsed)} of ~360 MB available',
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                // SECTION 3 - PROCESSING
                _sectionLabel('PROCESSING'),
                _glassCard(
                  children: [
                    _settingRow(
                      icon: Icons.bolt_outlined,
                      iconColor: AppColors.compressOrange,
                      label: 'Hardware Acceleration',
                      sublabel: 'FFmpeg mobile optimizations',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _badge('Recommended', AppColors.mergeTeal),
                          const SizedBox(width: 8),
                          _toggle(true),
                        ],
                      ),
                    ),
                    _divider(),
                    _settingRow(
                      icon: Icons.videocam_outlined,
                      iconColor: AppColors.compressOrange,
                      label: 'Default Video Quality',
                      sublabel: 'CRF value for compression',
                      trailing: const Text('CRF 23', style: TextStyle(color: AppColors.compressOrange, fontWeight: FontWeight.bold)),
                    ),
                    _divider(),
                    _settingRow(
                      icon: Icons.audiotrack_outlined,
                      iconColor: AppColors.audioRose,
                      label: 'Default Audio Bitrate',
                      sublabel: 'For Extract Audio operations',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('192k', style: TextStyle(color: AppColors.audioRose, fontWeight: FontWeight.bold)),
                          Icon(Icons.chevron_right, color: Colors.white24),
                        ],
                      ),
                    ),
                    _divider(),
                    _settingRow(
                      icon: Icons.layers_outlined,
                      iconColor: AppColors.videoPurple,
                      label: 'Parallel Conversions',
                      sublabel: 'Max simultaneous operations',
                      trailing: _stepper(2),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                // SECTION 4 - PRIVACY
                _sectionLabel('PRIVACY'),
                _guaranteeBanner(),
                const SizedBox(height: 12),
                _glassCard(
                  children: [
                    _settingRow(
                      icon: Icons.history_outlined,
                      iconColor: AppColors.docIndigo,
                      label: 'Save Conversion Log',
                      sublabel: 'Remember recent file operations',
                      trailing: _toggle(true),
                    ),
                    _divider(),
                    _settingRow(
                      icon: Icons.bar_chart_outlined,
                      iconColor: AppColors.greySlate,
                      label: 'Usage Analytics',
                      sublabel: 'Anonymous crash reports only',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Disabled', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                          const SizedBox(width: 8),
                          _toggle(false),
                        ],
                      ),
                    ),
                    _divider(),
                    _settingRow(
                      icon: Icons.history_toggle_off_outlined,
                      iconColor: AppColors.audioRose,
                      label: 'Clear Conversion History',
                      sublabel: '$_totalFiles entries will be removed',
                      onTap: _confirmClearStorage,
                      trailing: const Text('Clear', style: TextStyle(color: AppColors.audioRose, fontWeight: FontWeight.bold)),
                    ),
                    _divider(),
                    _settingRow(
                      icon: Icons.delete_sweep_outlined,
                      iconColor: AppColors.audioRose,
                      label: 'Clear Temp Files',
                      sublabel: 'Free up 18 MB of cached data',
                      trailing: const Text('Clear', style: TextStyle(color: AppColors.audioRose, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                // SECTION 5 - NOTIFICATIONS
                _sectionLabel('NOTIFICATIONS'),
                _glassCard(
                  children: [
                    _settingRow(
                      icon: Icons.notifications_none_outlined,
                      iconColor: AppColors.docIndigo,
                      label: 'Conversion Complete',
                      sublabel: 'Notify when a file finishes',
                      trailing: _toggle(true),
                    ),
                    _divider(),
                    _settingRow(
                      icon: Icons.error_outline_rounded,
                      iconColor: AppColors.audioRose,
                      label: 'Failed Conversions',
                      sublabel: 'Alert when a job encounters an error',
                      trailing: _toggle(true),
                    ),
                    _divider(),
                    _settingRow(
                      icon: Icons.sync_outlined,
                      iconColor: AppColors.videoPurple,
                      label: 'Background Processing',
                      sublabel: 'Continue converting when app is minimized',
                      trailing: _toggle(true),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                // SECTION 6 - ABOUT
                _sectionLabel('ABOUT'),
                _appIdentityCard(),
                const SizedBox(height: 12),
                _glassCard(
                  children: [
                    _settingRow(
                      icon: Icons.new_releases_outlined,
                      iconColor: AppColors.docIndigo,
                      label: "What's New",
                      sublabel: 'Version 2.1.0 release notes',
                      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                    ),
                    _divider(),
                    _settingRow(
                      icon: Icons.policy_outlined,
                      iconColor: AppColors.greySlate,
                      label: 'Privacy Policy',
                      sublabel: 'How we handle your data',
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: Colors.white24),
                    ),
                    _divider(),
                    _settingRow(
                      icon: Icons.code_outlined,
                      iconColor: AppColors.greySlate,
                      label: 'Open Source Licenses',
                      sublabel: 'FFmpeg, LibreOffice, and more',
                      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                    ),
                    _divider(),
                    _settingRow(
                      icon: Icons.star_outline_rounded,
                      iconColor: Colors.amber,
                      label: 'Rate Formatica',
                      sublabel: 'Leave a review on the Play Store',
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: Colors.white24),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                // DANGER ZONE
                _sectionLabel('DANGER ZONE', isDanger: true),
                _glassCard(
                  borderColor: AppColors.audioRose.withOpacity(0.2),
                  children: [
                    _settingRow(
                      icon: Icons.settings_backup_restore_outlined,
                      iconColor: Colors.amber,
                      label: 'Reset to Defaults',
                      sublabel: 'Restore all preferences',
                      trailing: _ghostPill('Reset', Colors.amber),
                    ),
                    _divider(),
                    _settingRow(
                      icon: Icons.delete_forever_outlined,
                      iconColor: AppColors.audioRose,
                      label: 'Clear All App Data',
                      sublabel: 'Removes history, cache, and settings',
                      trailing: _ghostPill('Clear All', AppColors.audioRose),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Formatica Studio · Android 8.0+',
                        style: TextStyle(color: Colors.white.withOpacity(0.18), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All processing is local. Zero cloud.',
                        style: TextStyle(color: Colors.white.withOpacity(0.12), fontSize: 10),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, {bool isDanger = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: AppTextStyles.studioLabel.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.6,
          color: isDanger ? AppColors.audioRose.withOpacity(0.7) : AppColors.onSurfaceVar.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _glassCard({required List<Widget> children, Color? borderColor}) {
    return LiquidGlassContainer(
      padding: EdgeInsets.zero,
      blur: 24,
      borderRadius: 16,
      borderColor: borderColor ?? AppColors.ghostBorderStrong,
      color: Colors.white.withOpacity(0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _settingRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String sublabel,
    Color? sublabelColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Color(0xFFDAE2FD), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sublabel,
                    style: TextStyle(
                      color: sublabelColor ?? Colors.white.withOpacity(0.4),
                      fontSize: 11,
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

  Widget _divider() {
    return Divider(height: 1, thickness: 1, color: Colors.white.withOpacity(0.06), indent: 52);
  }

  Widget _toggle(bool value) {
    return SizedBox(
      width: 44,
      height: 26,
      child: Switch(
        value: value,
        onChanged: (_) {},
        activeColor: Colors.white,
        activeTrackColor: AppColors.docIndigo,
        inactiveThumbColor: Colors.white60,
        inactiveTrackColor: Colors.white.withOpacity(0.15),
      ),
    );
  }

  Widget _colorDot(Color color, bool active) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: active ? Border.all(color: Colors.white, width: 2) : null,
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _stepper(int value) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.remove, size: 14, color: AppColors.docIndigo),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const Icon(Icons.add, size: 14, color: AppColors.docIndigo),
        ],
      ),
    );
  }

  Widget _ghostPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _guaranteeBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '100% On-Device',
                  style: TextStyle(color: Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Your files never leave this device.',
                  style: TextStyle(color: const Color(0xFF10B981).withOpacity(0.7), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _appIdentityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.docIndigo, AppColors.videoPurple]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: AppColors.docIndigo.withOpacity(0.3), blurRadius: 8),
              ],
            ),
            child: const Center(
              child: Text(
                'F',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Formatica Studio',
                  style: TextStyle(color: Color(0xFFDAE2FD), fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _badge('v2.1.0', AppColors.docIndigo),
                    const SizedBox(width: 8),
                    _badge('Android', AppColors.greySlate),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
          title: const Text(
            'Data Purge', 
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          content: const Text(
            'Delete all files in the Formatica vault? This action is irreversible.', 
            style: TextStyle(color: Colors.white70),
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
