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
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, left: 16, right: 16),
      child: Center(
        child: UnconstrainedBox(
          child: LiquidGlassContainer(
            borderRadius: 34,
            width: items.length * 70.0 + 32, // Dynamic width based on items
            height: 68,
            blur: 40, // Heaviest refraction
            specularOpacity: 0.3,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Active Capsule Runner (The "Glow")
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack, // Springy energy
                  left: currentIndex * 70.0,
                  width: 58,
                  height: 44,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryIndigo.withOpacity(1.0),
                          AppColors.videoPurple.withOpacity(0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryIndigo.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Icons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final isSelected = index == currentIndex;
                    
                    return GestureDetector(
                      onTap: () => onTap(index),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: 70,
                        height: 68,
                        child: Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected ? Colors.white : AppColors.darkTextSecondary,
                          size: 26,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
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








