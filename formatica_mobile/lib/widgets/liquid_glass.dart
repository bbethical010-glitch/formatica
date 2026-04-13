import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// A premium glass container with BackdropFilter refraction,
/// specular highlights, and a signature 'Void' aesthetics.
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
    this.blur = 28.0,
    this.color,
    this.borderColor,
    this.specularOpacity = 0.2,
  });

  @override
  Widget build(BuildContext context) {
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
              color: color ?? AppColors.darkGlassBg,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? AppColors.specularHighlight.withOpacity(specularOpacity),
                width: 0.5,
              ),
            ),
            child: Stack(
              children: [
                // Specular Highlight (Top-left inner glow)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(specularOpacity),
                          Colors.white.withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.4],
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

/// The atmospheric background for the Formatica studio.
/// Represents 'Layer 0' with a deep void and shifting light sources.
class MeshBackground extends StatelessWidget {
  final Widget child;

  const MeshBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Void
        Positioned.fill(
          child: Container(color: AppColors.darkBg),
        ),
        
        // Ambient Light Source 1 (Indigo Glow)
        Positioned(
          top: -100,
          right: -100,
          child: _AmbientGlow(
            color: AppColors.primaryIndigo.withOpacity(0.15),
            size: 400,
          ),
        ),
        
        // Ambient Light Source 2 (Accent Glow)
        Positioned(
          bottom: -50,
          left: -50,
          child: _AmbientGlow(
            color: AppColors.videoPurple.withOpacity(0.1),
            size: 300,
          ),
        ),
        
        // Content
        Positioned.fill(child: child),
      ],
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  final Color color;
  final double size;

  const _AmbientGlow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withOpacity(0.0),
          ],
        ),
      ),
    );
  }
}








