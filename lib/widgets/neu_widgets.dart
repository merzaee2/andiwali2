import 'package:flutter/material.dart';

class NeuContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final Color? color;

  const NeuContainer({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16.0),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = color ?? Theme.of(context).scaffoldBackgroundColor;

    final lightShadow = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final darkShadow = isDark ? Colors.black.withValues(alpha: 0.5) : Colors.grey.shade400;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: lightShadow,
            offset: const Offset(-4, -4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: darkShadow,
            offset: const Offset(4, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: child,
    );
  }
}

class NeuButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;

  const NeuButton({super.key, required this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: NeuContainer(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: child,
      ),
    );
  }
}