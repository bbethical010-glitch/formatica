import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// A premium glass container with BackdropFilter refraction,
/// specular highlights, and prototype-matched 'Liquid Glass' aesthetics.
class LiquidGlassContainer extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Color? borderColor;
  final double specularOpacity;

  const LiquidGlassContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 20.0,
    this.blur = 28.0, // Prototype standard
    this.color,
    this.borderColor,
    this.specularOpacity = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color ?? (isDark ? AppColors.darkGlassBg : AppColors.lightGlassBg),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? (isDark 
                  ? Colors.white.withOpacity(0.1) 
                  : Colors.black.withOpacity(0.05)),
                width: 1.0,
              ),
            ),
            child: Stack(
              children: [
                // Inner Specular Highlight
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(isDark ? specularOpacity : 0.4),
                          Colors.white.withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.5],
                      ),
                    ),
                  ),
                ),
                if (child != null) child!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The atmospheric background using generated mesh assets.
class MeshBackground extends StatelessWidget {
  final Widget child;

  const MeshBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Stack(
      children: [
        // Premium Mesh Asset
        Positioned.fill(
          child: Image.asset(
            isDark ? 'assets/images/mesh_dark.png' : 'assets/images/mesh_light.png',
            fit: BoxFit.cover,
          ),
        ),
        
        // Subtle Overlay to ensure readability
        Positioned.fill(
          child: Container(
            color: isDark 
              ? Colors.black.withOpacity(0.2) 
              : Colors.white.withOpacity(0.1),
          ),
        ),
        
        // Content
        Positioned.fill(child: child),
      ],
    );
  }
}
