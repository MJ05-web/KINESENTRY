import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppChrome extends StatefulWidget {
  const AppChrome({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.safeTop = true,
    this.safeBottom = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool safeTop;
  final bool safeBottom;

  @override
  State<AppChrome> createState() => _AppChromeState();
}

class _AppChromeState extends State<AppChrome>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppThemeColors.isDark(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final phase = _controller.value * math.pi * 2;
        final primary = dark
            ? const Color(0xFF081729)
            : const Color(0xFFF7FBFF);
        final secondary = dark
            ? const Color(0xFF09142A)
            : const Color(0xFFF1F7FF);
        final tertiary = dark
            ? const Color(0xFF08111F)
            : const Color(0xFFF4F7FB);

        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.9 + (math.sin(phase) * .2), -1),
                  end: Alignment(1, 0.9 + (math.cos(phase) * .2)),
                  colors: [primary, secondary, tertiary],
                ),
              ),
            ),
            _GlowOrb(
              alignment: Alignment(-0.95 + (math.sin(phase) * .16), -0.88),
              color: AppThemeColors.accent(context).withValues(alpha: dark ? .26 : .18),
              size: 260,
            ),
            _GlowOrb(
              alignment: Alignment(0.92, -0.25 + (math.cos(phase) * .18)),
              color: AppThemeColors.glow(context).withValues(alpha: dark ? .22 : .14),
              size: 220,
            ),
            _GlowOrb(
              alignment: Alignment(-0.15 + (math.cos(phase) * .24), 1.05),
              color: AppThemeColors.accentSecondary(context)
                  .withValues(alpha: dark ? .20 : .12),
              size: 280,
            ),
            SafeArea(
              top: widget.safeTop,
              bottom: widget.safeBottom,
              child: Padding(
                padding: widget.padding,
                child: widget.child,
              ),
            ),
          ],
        );
      },
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 24,
    this.borderColor,
    this.glowColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? borderColor;
  final Color? glowColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final glow = glowColor ?? AppThemeColors.accent(context).withValues(alpha: .12);
    final border = borderColor ?? AppThemeColors.border(context);

    final panel = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: padding,
          decoration: BoxDecoration(
            color: AppThemeColors.panel(context),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: glow,
                blurRadius: 28,
                spreadRadius: 1,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return panel;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: panel,
    );
  }
}

class AccentHeadline extends StatefulWidget {
  const AccentHeadline({
    super.key,
    required this.title,
    this.subtitle,
    this.center = false,
  });

  final String title;
  final String? subtitle;
  final bool center;

  @override
  State<AccentHeadline> createState() => _AccentHeadlineState();
}

class _AccentHeadlineState extends State<AccentHeadline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final align = widget.center ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textAlign = widget.center ? TextAlign.center : TextAlign.start;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final glow = 8 + (_controller.value * 8);
        return Column(
          crossAxisAlignment: align,
          children: [
            ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: [
                    AppThemeColors.textPrimary(context),
                    AppThemeColors.accent(context),
                    AppThemeColors.accentSecondary(context),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds);
              },
              child: Text(
                widget.title,
                textAlign: textAlign,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  height: 1.02,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  shadows: [
                    Shadow(
                      color: AppThemeColors.accent(context).withValues(alpha: .25),
                      blurRadius: glow,
                    ),
                  ],
                ),
              ),
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.subtitle!,
                textAlign: textAlign,
                style: TextStyle(
                  color: AppThemeColors.textSecondary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.alignment,
    required this.color,
    required this.size,
  });

  final Alignment alignment;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color,
                color.withValues(alpha: .0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
