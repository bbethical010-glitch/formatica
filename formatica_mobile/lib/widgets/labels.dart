import 'package:flutter/material.dart';
import 'liquid_glass.dart';
import '../core/theme.dart';

class OnDeviceBadge extends StatelessWidget {
  const OnDeviceBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return LiquidGlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 16,
      blur: 12,
      color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.imageCyan,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: AppColors.imageCyan, blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'ON-DEVICE PROCESSING · PRIVATE',
            style: AppTextStyles.studioLabel.copyWith(
              fontSize: 10,
              color: isDark ? AppColors.darkTextSecondary.withOpacity(0.7) : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}
