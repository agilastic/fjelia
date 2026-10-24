import 'dart:async';

import 'package:flutter/material.dart';

String startupArtwork(DateTime now) {
  if (now.hour >= 22 || now.hour < 5) {
    return 'assets/splash/fjelia-splash-night.png';
  }
  if (now.hour < 9) return 'assets/splash/fjelia-splash-sunrise.png';
  if (now.hour >= 18) return 'assets/splash/fjelia-splash-sunset.png';
  if (now.month == 12 || now.month <= 2) {
    return 'assets/splash/fjelia-splash-winter.png';
  }
  return 'assets/splash/fjelia-splash.png';
}

class StartupSplash extends StatefulWidget {
  const StartupSplash({super.key, required this.onMinimumElapsed});

  final VoidCallback onMinimumElapsed;

  @override
  State<StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends State<StartupSplash> {
  late final String _asset = startupArtwork(DateTime.now());
  Timer? _timer;
  bool _started = false;

  void _startMinimumDisplay() {
    if (_started) return;
    _started = true;
    // Count visible time after the decoded artwork's first frame is painted.
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
  Widget build(BuildContext context) => Scaffold(
    body: SizedBox.expand(
      child: Image.asset(
        _asset,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        frameBuilder: (context, child, frame, synchronous) {
          if (synchronous || frame != null) _startMinimumDisplay();
          return child;
        },
        errorBuilder: (context, error, stack) {
          _startMinimumDisplay();
          return const Center(child: Text('FJELIA'));
        },
      ),
    ),
  );
}
