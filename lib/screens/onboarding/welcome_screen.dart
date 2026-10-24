import 'package:flutter/material.dart';

import 'connect_devices_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (Navigator.of(context).canPop())
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              tooltip: 'Close',
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        const SizedBox(height: 48),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D4A0).withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF00D4A0).withAlpha(90),
                            ),
                          ),
                          child: const Icon(
                            Icons.monitor_heart,
                            size: 30,
                            color: Color(0xFF00D4A0),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Know your body.\nTrain smarter.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'All your health devices. One intelligent view.',
                          style: TextStyle(
                            color: Color(0xFFCCCCCC),
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 44),
                        const _FeatureCard(
                          icon: Icons.favorite_rounded,
                          color: Color(0xFF00D4A0),
                          title: 'Are you ready to train today?',
                          subtitle: 'HRV · Recovery Score · Resting HR',
                        ),
                        const SizedBox(height: 12),
                        const _FeatureCard(
                          icon: Icons.bedtime_rounded,
                          color: Color(0xFF4FC3F7),
                          title: 'Did you actually recover last night?',
                          subtitle: 'Sleep Stages · Deep Sleep · SpO₂',
                        ),
                        const SizedBox(height: 12),
                        const _FeatureCard(
                          icon: Icons.monitor_heart_rounded,
                          color: Color(0xFFFF8C00),
                          title: 'Is your blood pressure under control?',
                          subtitle: 'Continuous BP · Night Dipping · Trends',
                        ),
                        const SizedBox(height: 12),
                        const _FeatureCard(
                          icon: Icons.bolt_rounded,
                          color: Color(0xFFFFCC00),
                          title: 'How hard did you push this week?',
                          subtitle: 'Training Load · TRIMP · Strain Score',
                        ),
                        const SizedBox(height: 12),
                        const _FeatureCard(
                          icon: Icons.monitor_weight_rounded,
                          color: Color(0xFF00D4A0),
                          title: 'Is your body composition improving?',
                          subtitle: 'Weight · Body Fat · Muscle Mass',
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00D4A0),
                            foregroundColor: Colors.black,
                            textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ConnectDevicesScreen(),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Get Started'),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Your data stays on your device. Always private.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
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

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
