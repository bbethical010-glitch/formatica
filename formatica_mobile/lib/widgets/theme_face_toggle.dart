import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme.dart';

class ThemeFaceToggle extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggle;

  const ThemeFaceToggle({
    super.key,
    required this.isDark,
    required this.onToggle,
  });

  @override
  State<ThemeFaceToggle> createState() => _ThemeFaceToggleState();
}

class _ThemeFaceToggleState extends State<ThemeFaceToggle> with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _eyeScale;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _eyeScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.1), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: 1.0), weight: 50),
    ]).animate(_blinkController);

    _startBlinkTimer();
  }

  void _startBlinkTimer() async {
    while (mounted) {
      await Future.delayed(Duration(seconds: 3 + math.Random().nextInt(4)));
      if (mounted) _blinkController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        width: 96,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: widget.isDark 
                ? AppColors.primary.withOpacity(0.2) 
                : const Color(0xFFFFC83C).withOpacity(0.4),
            width: 1.5,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.isDark
                ? [const Color(0xFF1A1F3A), const Color(0xFF2D1F4A)]
                : [const Color(0xFF87CEEB), const Color(0xFFFFD580)],
          ),
        ),
        child: Stack(
          children: [
            // Stars (Dark mode)
            if (widget.isDark) ..._buildStars(),
            
            // Clouds (Light mode)
            if (!widget.isDark) ..._buildClouds(),

            // Face Ball
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              left: widget.isDark ? 4 : 48 + 4,
              top: 4,
              child: _FaceBall(isDark: widget.isDark, eyeScale: _eyeScale),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStars() {
    final random = math.Random(42);
    return List.generate(5, (index) {
      return Positioned(
        left: random.nextDouble() * 80,
        top: random.nextDouble() * 40,
        child: Container(
          width: 2,
          height: 2,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
      );
    });
  }

  List<Widget> _buildClouds() {
    return [
      Positioned(
        left: 10,
        top: 20,
        child: _CloudPuff(size: 15),
      ),
      Positioned(
        left: 25,
        top: 10,
        child: _CloudPuff(size: 20),
      ),
    ];
  }
}

class _FaceBall extends StatelessWidget {
  final bool isDark;
  final Animation<double> eyeScale;

  const _FaceBall({required this.isDark, required this.eyeScale});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.5) : const Color(0xFFFFC800).withOpacity(0.8),
            blurRadius: isDark ? 12 : 14,
            offset: const Offset(0, 3),
          ),
        ],
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: isDark
              ? [const Color(0xFFD0D8F0), const Color(0xFF8A90C8)]
              : [const Color(0xFFFFF7A0), const Color(0xFFFFCC00)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Eyes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(scale: eyeScale, child: _Eye(isDark: isDark)),
                const SizedBox(width: 8),
                ScaleTransition(scale: eyeScale, child: _Eye(isDark: isDark)),
              ],
            ),
            const SizedBox(height: 2),
            // Smile
            CustomPaint(
              size: const Size(12, 4),
              painter: _SmilePainter(isDark: isDark),
            ),
          ],
        ),
      ),
    );
  }
}

class _Eye extends StatelessWidget {
  final bool isDark;
  const _Eye({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D3449) : const Color(0xFF8B4513).withOpacity(0.8),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SmilePainter extends CustomPainter {
  final bool isDark;
  _SmilePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? const Color(0xFF2D3449) : const Color(0xFF8B4513).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size.width / 2, size.height * 1.5, size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _CloudPuff extends StatelessWidget {
  final double size;
  const _CloudPuff({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size / 1.5,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(size),
      ),
    );
  }
}
