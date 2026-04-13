import 'package:flutter/material.dart';
import 'dart:ui';
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
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.85),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.folder_open,
              color: AppColors.docIndigo,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: AppTextStyles.studioLabel.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
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
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.docIndigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.docIndigo.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.docIndigo,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'SYSTEM REQUIREMENT: FILE SYSTEM ACCESS IS NECESSARY FOR DATA PERSISTENCE.',
                      style: AppTextStyles.studioLabel.copyWith(
                        fontSize: 9, 
                        color: AppColors.docIndigo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          if (settingsButtonText != null && onSettingsTap != null)
            TextButton(
              onPressed: onSettingsTap,
              child: Text(
                settingsButtonText!.toUpperCase(),
                style: AppTextStyles.studioLabel.copyWith(
                  color: Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          TextButton(
            onPressed: onGrantTap,
            child: Text(
              'GRANT ACCESS',
              style: AppTextStyles.studioLabel.copyWith(
                color: AppColors.docIndigo,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
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
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.85),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.audioRose,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'ACCESS DENIED',
              style: AppTextStyles.studioLabel.copyWith(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Storage permission was denied. The system cannot persist extraction results without this authorization.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'RECOVERY SEQUENCE:',
              style: AppTextStyles.studioLabel.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white38,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 12),
            _buildStep('1', 'OPEN SETTINGS → APPS → FORMATICA', context),
            _buildStep('2', 'NAVIGATE TO PERMISSIONS', context),
            _buildStep('3', 'AUTHORIZE FILES AND MEDIA', context),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.audioRose.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.audioRose.withOpacity(0.2),
                ),
              ),
              child: Text(
                'ANDROID 11+ NOTICE: ACTIVATE "ALLOW MANAGEMENT OF ALL FILES"',
                textAlign: TextAlign.center,
                style: AppTextStyles.studioLabel.copyWith(
                  fontSize: 9,
                  color: AppColors.audioRose,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            onPressed: onCancelTap,
            child: Text(
              'CANCEL',
              style: AppTextStyles.studioLabel.copyWith(
                color: Colors.white24,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: onSettingsTap,
            child: Text(
              'OPEN MODULE',
              style: AppTextStyles.studioLabel.copyWith(
                color: AppColors.docIndigo,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.docIndigo.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: AppTextStyles.studioLabel.copyWith(
                  color: AppColors.docIndigo,
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.studioLabel.copyWith(
                fontSize: 10,
                color: Colors.white38,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}








