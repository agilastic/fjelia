import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The Fjelia mark with its name, the same image as the launch screens of
/// iOS and Android, so the hand-over from them does not jump.
const startupLockup = 'assets/branding/splash-lockup.png';

class StartupSplash extends StatefulWidget {
  const StartupSplash({super.key, required this.onMinimumElapsed});

  final VoidCallback onMinimumElapsed;

  @override
  State<StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends State<StartupSplash> {
  Timer? _timer;
  bool _started = false;

  void _startMinimumDisplay() {
    if (_started) return;
    _started = true;
    // Count visible time after the decoded lockup's first frame is painted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _timer = Timer(const Duration(seconds: 2), () {
        if (mounted) widget.onMinimumElapsed();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: ColoredBox(
      color: Colors.black,
      child: Center(
        child: Image.asset(
          startupLockup,
          semanticLabel: 'Fjelia',
          filterQuality: FilterQuality.medium,
          frameBuilder: (context, child, frame, synchronous) {
            if (synchronous || frame != null) _startMinimumDisplay();
            return child;
          },
          errorBuilder: (context, error, stack) {
            _startMinimumDisplay();
            return const Text(
              'FJELIA',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 9,
              ),
            );
          },
        ),
      ),
    ),
  );
}
