import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../core/theme/mb_colors.dart';
import '../shared/widgets/mb_wordmark.dart';
import 'app.dart';

/// Takes over from the native splash — same mark, same size, same colour, so
/// the hand-off is invisible — and animates it while [boot] runs (Firebase,
/// DI, session restore). Logo only: no text.
///
/// Swaps to [MolBhavApp] once [boot] completes *and* the entrance has played
/// once, so a fast boot never flashes a half-started animation. A failed boot
/// shows a retry button instead of crashing on a blank screen.
class BootSplash extends StatefulWidget {
  const BootSplash({super.key, required this.boot});

  /// Must be safe to call again after a failure.
  final Future<void> Function() boot;

  /// Matches `molbhav_splash_mark.png`: 440 px on a 1152 px canvas rendered
  /// at 4x by flutter_native_splash → 110 logical px.
  static const markSize = 110.0;

  static const _entrance = Duration(milliseconds: 700);
  static const _breath = Duration(milliseconds: 1400);

  @override
  State<BootSplash> createState() => _BootSplashState();
}

class _BootSplashState extends State<BootSplash> with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: BootSplash._entrance,
  );
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: BootSplash._breath,
  );

  /// 1.0 → 0.92 → 1.06 → 1.0: a small "pop" that starts from the native
  /// splash's exact size.
  late final Animation<double> _pop = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.92,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 25,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.92,
        end: 1.06,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.06,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 35,
    ),
  ]).animate(_entrance);

  bool _ready = false;
  bool _failed = false;

  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_revealed) return;
    _revealed = true;
    // Decode the mark first, then drop the native splash and animate — the
    // native one shows the same mark, so the swap is seamless. A decode error
    // must not keep the native splash up forever.
    precacheImage(const AssetImage(MbWordmark.markAsset), context).whenComplete(
      () {
        FlutterNativeSplash.remove();
        if (!mounted) return;
        _entrance.forward().whenComplete(() {
          if (mounted && !_ready) _breath.repeat();
        });
      },
    );
  }

  Future<void> _start() async {
    // Called from initState too, where setState would assert.
    if (_failed) setState(() => _failed = false);
    try {
      await Future.wait([
        widget.boot(),
        Future<void>.delayed(BootSplash._entrance),
      ]);
      if (!mounted) return;
      _breath.stop();
      setState(() => _ready = true);
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'boot',
          context: ErrorDescription('while starting the app'),
        ),
      );
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      child: _ready ? const MolBhavApp() : _splash(context),
    );
  }

  Widget _splash(BuildContext context) {
    const colors = MbColors.light;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Directionality(
      key: const ValueKey('boot-splash'),
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: colors.surface,
        child: Center(
          child: SizedBox.square(
            dimension: BootSplash.markSize * 2.2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!reduceMotion && !_failed)
                  AnimatedBuilder(
                    animation: _breath,
                    builder: (context, _) => _Ripple(
                      progress: _breath.value,
                      color: colors.molGreen,
                    ),
                  ),
                AnimatedBuilder(
                  animation: Listenable.merge([_entrance, _breath]),
                  builder: (context, child) {
                    if (reduceMotion) return child!;
                    // Gentle breathing between 1.0 and 1.04 while loading:
                    // a 0 → 1 → 0 triangle wave, eased.
                    final wave = 1 - (_breath.value * 2 - 1).abs();
                    final breath = 1 + 0.04 * Curves.easeInOut.transform(wave);
                    final scale = _pop.value * breath;
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Image.asset(
                    MbWordmark.markAsset,
                    width: BootSplash.markSize,
                    height: BootSplash.markSize,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                ),
                if (_failed)
                  Align(
                    alignment: Alignment.bottomCenter,
                    // Above MaterialApp there is no Material/Overlay, so no
                    // IconButton or tooltip — a plain, labelled tap target.
                    child: Semantics(
                      button: true,
                      label: 'Retry',
                      child: GestureDetector(
                        onTap: _start,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.refresh_rounded,
                            size: 32,
                            color: colors.molGreen,
                          ),
                        ),
                      ),
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

/// A soft brand-green ring that grows out from behind the mark and fades.
class _Ripple extends StatelessWidget {
  const _Ripple({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeOut.transform(progress);
    // Fade in over the first 15% so each ring doesn't pop on at full strength.
    final fadeIn = (progress / 0.15).clamp(0.0, 1.0);
    return Opacity(
      opacity: fadeIn * (1 - t) * 0.35,
      child: Container(
        width: BootSplash.markSize * (1.0 + 1.1 * t),
        height: BootSplash.markSize * (1.0 + 1.1 * t),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
      ),
    );
  }
}
