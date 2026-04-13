import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// A high-fidelity glass container matching the Liquid Glass design system.
/// Features backdrop blur, specular highlights, and theme-adaptive refraction.
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

  const LiquidGlassContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 24.0,
    this.blur = 28.0,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          if (isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: CustomPaint(
            painter: AsymmetricGlassBorder(borderRadius: borderRadius, isDark: isDark),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: color ?? (isDark ? Colors.white.withOpacity(0.07) : Colors.white.withOpacity(0.82)),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class MeshBackground extends StatefulWidget {
  final Widget child;

  const MeshBackground({super.key, required this.child});

  @override
  State<MeshBackground> createState() => _MeshBackgroundState();
}

class _MeshBackgroundState extends State<MeshBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: MeshPainter(
            animationValue: _controller.value,
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class MeshPainter extends CustomPainter {
  final double animationValue;
  final bool isDark;

  MeshPainter({required this.animationValue, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    
    // Background base
    canvas.drawRect(
      rect,
      Paint()..color = isDark ? AppColors.bg : AppColors.lightBg,
    );

    if (isDark) {
      // Prototype Mesh Dark
      _drawRadial(canvas, size, const Offset(0, 0), 0.5, const Color(0xFF1A1B3A));
      _drawRadial(canvas, size, Offset(size.width, 0), 0.5, const Color(0xFF2D1633));
      _drawRadial(canvas, size, Offset(size.width * 0.5, size.height), 0.6, const Color(0xFF0F1628));
    } else {
      // Prototype Mesh Light
      _drawRadial(canvas, size, const Offset(0, 0), 0.5, const Color(0xFFE8E4FF));
      _drawRadial(canvas, size, Offset(size.width, 0), 0.5, const Color(0xFFFFE4EC));
      _drawRadial(canvas, size, Offset(size.width * 0.5, size.height), 0.6, const Color(0xFFF0F4FF));
    }
  }

  void _drawRadial(Canvas canvas, Size size, Offset center, double radiusFactor, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withOpacity(0.6), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: size.shortestSide * radiusFactor * 2.5));
    
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant MeshPainter oldDelegate) => 
      oldDelegate.animationValue != animationValue || oldDelegate.isDark != isDark;
}

class AsymmetricGlassBorder extends CustomPainter {
  final double borderRadius;
  final bool isDark;

  AsymmetricGlassBorder({required this.borderRadius, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );
    
    // Prototype: border-top: 1px solid rgba(255,255,255,0.15); border-left: 1px solid rgba(255,255,255,0.1);
    // We simulate this with a sweep gradient or a linear gradient highlight
    paint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(isDark ? 0.18 : 0.6),
        Colors.white.withOpacity(isDark ? 0.08 : 0.3),
        Colors.transparent,
      ],
      stops: const [0.0, 0.4, 0.9],
    ).createShader(rrect.outerRect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
