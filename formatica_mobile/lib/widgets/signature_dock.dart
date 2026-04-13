import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'liquid_glass.dart';

class SignatureDock extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<DockItem> items;

  const SignatureDock({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.only(bottom: 20.0),
      alignment: Alignment.bottomCenter,
      child: LiquidGlassContainer(
        borderRadius: 32,
        width: 240,
        height: 64,
        blur: 28,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = index == currentIndex;
            
            return GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: isSelected 
                      ? AppColors.primaryContainer.withOpacity(isDark ? 0.25 : 0.12)
                      : Colors.transparent,
                  boxShadow: isSelected && isDark ? [
                    BoxShadow(
                      color: AppColors.primaryContainer.withOpacity(0.3),
                      blurRadius: 14,
                    )
                  ] : null,
                ),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected 
                      ? (isDark ? AppColors.primary : AppColors.primaryContainer)
                      : (isDark ? AppColors.white.withOpacity(0.4) : Colors.black.withOpacity(0.4)),
                  size: 22,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class DockItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const DockItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}








