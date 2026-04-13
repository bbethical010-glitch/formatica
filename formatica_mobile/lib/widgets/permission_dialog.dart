import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Permission request dialog with explanation and action buttons
class PermissionDialog extends StatelessWidget {
  final String title;
  final String description;
  final String? settingsButtonText;
  final VoidCallback? onSettingsTap;
  final VoidCallback onGrantTap;

  const PermissionDialog({
    super.key,
    required this.title,
    required this.description,
    this.settingsButtonText,
    this.onSettingsTap,
    required this.onGrantTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurfaceCard : AppColors.darkSurfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            Icons.folder_open,
            color: AppColors.primaryIndigo,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.displayLarge,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.darkTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryIndigo.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primaryIndigo.withAlpha(60),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppColors.primaryIndigo,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This permission is required to save your converted files to the Downloads folder.',
                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 12).copyWith(
                      color: AppColors.primaryIndigo,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (settingsButtonText != null && onSettingsTap != null)
          TextButton(
            onPressed: onSettingsTap,
            child: Text(
              settingsButtonText!,
              style: AppTextStyles.studioLabel.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.darkTextSecondary,
              ),
            ),
          ),
        FilledButton(
          onPressed: onGrantTap,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryIndigo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Grant Permission',
            style: AppTextStyles.studioLabel.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/// Permission denied dialog with settings shortcut
class PermissionDeniedDialog extends StatelessWidget {
  final VoidCallback onSettingsTap;
  final VoidCallback onCancelTap;

  const PermissionDeniedDialog({
    super.key,
    required this.onSettingsTap,
    required this.onCancelTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurfaceCard : AppColors.darkSurfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.audioRose,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text('Permission Required'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Storage permission was denied. The app cannot save files without this permission.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.darkTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'To enable it manually:',
            style: AppTextStyles.studioLabel.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildStep('1', 'Open Settings → Apps → Formatica', context),
          _buildStep('2', 'Tap "Permissions"', context),
          _buildStep('3', 'Enable "Files and media"', context),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.audioRose.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.audioRose.withAlpha(60),
              ),
            ),
            child: Text(
              'For Android 11+, select "Allow management of all files"',
              style: AppTextStyles.bodyMedium.copyWith(fontSize: 12).copyWith(
                color: AppColors.audioRose,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancelTap,
          child: Text(
            'Cancel',
            style: AppTextStyles.studioLabel.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.darkTextSecondary,
            ),
          ),
        ),
        FilledButton(
          onPressed: onSettingsTap,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryIndigo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Open Settings',
            style: AppTextStyles.studioLabel.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep(String number, String text, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primaryIndigo.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: AppTextStyles.bodyMedium.copyWith(fontSize: 12).copyWith(
                  color: AppColors.primaryIndigo,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(fontSize: 12).copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.darkTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}








