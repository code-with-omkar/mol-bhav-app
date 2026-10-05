import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/mb_dimens.dart';
import '../../core/weather/weather_models.dart';

/// Animated weather badge overlay showing temperature and weather condition emoji.
/// Typically composed over a location chip.
///
/// Animates in from top-right with fade-in and slight scale effect.
class WeatherBadge extends StatefulWidget {
  const WeatherBadge({
    super.key,
    required this.weather,
    this.backgroundColor,
    this.textColor,
  });

  final CurrentWeather weather;

  /// Optional custom background color; defaults to theme onHero with 16% alpha.
  final Color? backgroundColor;

  /// Optional custom text color; defaults to theme onHero.
  final Color? textColor;

  @override
  State<WeatherBadge> createState() => _WeatherBadgeState();
}

class _WeatherBadgeState extends State<WeatherBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _slideIn;
  late final Animation<double> _scaleIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.7, curve: Curves.easeOut),
      ),
    );

    _slideIn = Tween<double>(begin: -20, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.7, curve: Curves.easeOut),
      ),
    );

    _scaleIn = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.7, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final onHero = c.inkOnHero;

    final bgColor = widget.backgroundColor ?? onHero.withValues(alpha: 0.16);
    final textColor = widget.textColor ?? onHero;

    return FadeTransition(
      opacity: _fadeIn,
      child: Transform.translate(
        offset: Offset(_slideIn.value, 0),
        child: ScaleTransition(
          scale: _scaleIn,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(MbRadius.pill),
              border: Border.all(
                color: textColor.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  CurrentWeather.weatherCodeToEmoji(widget.weather.weatherCode),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.weather.temperature.round()}°',
                  style: t.caption.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
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

/// Loading skeleton for weather badge while data is being fetched.
class WeatherBadgeSkeleton extends StatefulWidget {
  const WeatherBadgeSkeleton({
    super.key,
    this.backgroundColor,
  });

  final Color? backgroundColor;

  @override
  State<WeatherBadgeSkeleton> createState() => _WeatherBadgeSkeletonState();
}

class _WeatherBadgeSkeletonState extends State<WeatherBadgeSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final bgColor = widget.backgroundColor ?? c.inkOnHero.withValues(alpha: 0.16);

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        final opacity = 0.5 + (0.3 * (1 - (_shimmer.value - 0.5).abs() * 2));
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor.withValues(alpha: opacity * 0.16),
            borderRadius: BorderRadius.circular(MbRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 16, height: 16, color: bgColor.withValues(alpha: opacity * 0.4)),
              const SizedBox(width: 4),
              Container(width: 28, height: 14, color: bgColor.withValues(alpha: opacity * 0.4)),
            ],
          ),
        );
      },
    );
  }
}
