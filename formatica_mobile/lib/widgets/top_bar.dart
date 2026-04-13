import 'package:flutter/material.dart';
import 'liquid_glass.dart';
import '../core/theme.dart';

class StudioTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;

  const StudioTopBar({
    super.key,
    required this.title,
    this.trailing,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: LiquidGlassContainer(
          height: 64,
          borderRadius: 20,
          blur: 24,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0D0D16),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: onBack == null ? 8 : 0),
                  child: Text(
                    title,
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontSize: 18,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0D0D16),
                    ),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(88);
}
