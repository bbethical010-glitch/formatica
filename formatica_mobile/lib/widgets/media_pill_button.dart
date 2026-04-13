import 'package:flutter/material.dart';
import '../core/theme.dart';

class MediaPillButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color accentColor;
  final IconData? icon;
  final bool isLoading;

  const MediaPillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.accentColor = AppColors.docIndigo,
    this.icon,
    this.isLoading = false,
  });

  @override
  State<MediaPillButton> createState() => _MediaPillButtonState();
}

class _MediaPillButtonState extends State<MediaPillButton> with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovering ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9999),
              color: widget.accentColor.withOpacity(_isHovering ? 0.35 : 0.18),
              boxShadow: _isHovering ? [
                BoxShadow(
                  color: widget.accentColor.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ] : [],
              border: Border.all(
                color: widget.accentColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.accentColor,
                    ),
                  )
                else if (widget.icon != null) ...[
                  Icon(widget.icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label.toUpperCase(),
                  style: AppTextStyles.studioLabel.copyWith(
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}








