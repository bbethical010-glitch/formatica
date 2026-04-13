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
    const double dockWidth = 240.0;
    final itemWidth = (dockWidth - 32) / items.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Center(
        child: LiquidGlassContainer(
          borderRadius: 32,
          width: dockWidth,
          height: 64,
          blur: 32,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Active Runner
              AnimatedPositioned(
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                left: currentIndex * itemWidth,
                width: itemWidth,
                height: 48,
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryIndigo,
                        AppColors.primaryIndigo.withOpacity(0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryIndigo.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = index == currentIndex;
                  
                  return GestureDetector(
                    onTap: () => onTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: itemWidth,
                      height: 64,
                      child: Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected ? Colors.white : AppColors.darkTextSecondary.withOpacity(0.5),
                        size: 22,
                      ),
                    ),
                  );
                }),
              ),
            ],
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
