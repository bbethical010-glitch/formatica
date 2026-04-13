import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'liquid_glass.dart';

class GlassChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? activeColor;

  const GlassChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = activeColor ?? AppColors.primaryIndigo;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected 
              ? color 
              : (isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08)),
            width: 1.5,
          ),
          color: isSelected 
            ? color.withOpacity(0.15) 
            : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.02)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: isSelected ? color : (isDark ? Colors.white54 : Colors.black45),
          ),
        ),
      ),
    );
  }
}

class QualityPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? activeColor;

  const QualityPill({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = activeColor ?? AppColors.primaryIndigo;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
            border: Border.all(
              color: isSelected ? color.withOpacity(0.4) : Colors.transparent,
              width: 1.0,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: isSelected ? color : (isDark ? Colors.white24 : Colors.black26),
            ),
          ),
        ),
      ),
    );
  }
}
