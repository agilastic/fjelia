import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_ext.dart';
import '../../providers/hrv_reminder_provider.dart';
import '../../providers/missed_workout_provider.dart';
import '../../services/missed_workout_reminder_service.dart';
import '../../utils/log.dart';
import '../home/home_screen.dart';

const _mint = Color(0xFF70F3C8);
const _lilac = Color(0xFFC5B4FF);
const _muted = Color(0xFFAAAEB8);

/// Last onboarding step: the evening reminder for a planned workout that is
/// still open. On by default; the time can be changed here or later.
class MissedWorkoutOnboardingScreen extends ConsumerStatefulWidget {
  const MissedWorkoutOnboardingScreen({super.key});

  @override
  ConsumerState<MissedWorkoutOnboardingScreen> createState() =>
      _MissedWorkoutOnboardingScreenState();
}

class _MissedWorkoutOnboardingScreenState
    extends ConsumerState<MissedWorkoutOnboardingScreen> {
  MissedWorkoutSettings _settings = const MissedWorkoutSettings();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    MissedWorkoutSettings.load().then((s) {
      if (mounted) setState(() => _settings = s);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _settings.hour, minute: _settings.minute),
    );
    if (picked == null) return;
    setState(
      () => _settings = _settings.copyWith(
        minutes: picked.hour * 60 + picked.minute,
      ),
    );
  }

  /// Saves the choice, asks for notifications only when the reminder stays
  /// on, then opens the app.
  Future<void> _continue() async {
    setState(() => _saving = true);
    try {
      await ref.read(missedWorkoutSettingsProvider.notifier).save(_settings);
      if (_settings.enabled) {
        await ref.read(localNotificationGatewayProvider).requestPermission();
        await ref.read(missedWorkoutReminderProvider).reconcile();
      }
    } catch (e) {
      log('[Onboarding] missed-workout reminder: $e');
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final time = TimeOfDay(
      hour: _settings.hour,
      minute: _settings.minute,
    ).format(context);
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: const Color(0xFF101416),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-1.1, -1),
              radius: 1.2,
              colors: [Color(0xFF1F2A44), Color(0xFF101416)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'FJELIA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3.8,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.onbReminderTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1.4,
                                height: 1.12,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              l10n.onbReminderSubtitle,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _NotificationPreview(
                              time: time,
                              enabled: _settings.enabled,
                              animate: !reduceMotion,
                            ),
                            const SizedBox(height: 24),
                            _Panel(
                              child: Column(
                                children: [
                                  SwitchListTile(
                                    key: const ValueKey(
                                      'onboarding-missed-switch',
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                    secondary: const Icon(
                                      Icons.nightlight_round,
                                      color: _lilac,
                                    ),
                                    title: Text(
                                      l10n.onbReminderToggle,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    activeThumbColor: _mint,
                                    activeTrackColor: _mint.withAlpha(90),
                                    value: _settings.enabled,
                                    onChanged: _saving
                                        ? null
                                        : (v) => setState(
                                            () => _settings = _settings
                                                .copyWith(enabled: v),
                                          ),
                                  ),
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOutCubic,
                                    child: _settings.enabled
                                        ? ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: const Icon(
                                              Icons.schedule_rounded,
                                              color: _muted,
                                            ),
                                            title: Text(l10n.onbReminderTime),
                                            trailing: _TimeChip(
                                              time: time,
                                              onTap: _saving ? null : _pickTime,
                                            ),
                                          )
                                        : const SizedBox(
                                            width: double.infinity,
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _footer(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF101416),
      border: Border(top: BorderSide(color: Colors.white.withAlpha(14))),
    ),
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          key: const ValueKey('onboarding-missed-continue'),
          onPressed: _saving ? null : _continue,
          style: FilledButton.styleFrom(
            backgroundColor: _mint,
            foregroundColor: const Color(0xFF09291E),
            disabledBackgroundColor: _mint.withAlpha(100),
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: _saving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _mint,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.l10n.continueLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        Text(
          context.l10n.onbReminderFootnote,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF818B92),
            fontSize: 10,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  // A Material, not a coloured box: the rows inside keep their tap ripple.
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withAlpha(10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: Colors.white.withAlpha(18)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: child,
    ),
  );
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.time, this.onTap});
  final String time;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _mint.withAlpha(28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _mint.withAlpha(90)),
      ),
      child: Text(
        time,
        style: const TextStyle(
          color: _mint,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    ),
  );
}

/// An evening sky with the reminder as it will appear: it slides in, then
/// its three answers follow one after the other.
class _NotificationPreview extends StatelessWidget {
  const _NotificationPreview({
    required this.time,
    required this.enabled,
    required this.animate,
  });
  final String time;
  final bool enabled, animate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ExcludeSemantics(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: enabled ? 1 : .35,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 236,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1B2140), Color(0xFF151A2B)],
              ),
            ),
            child: Stack(
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: _SkyPainter()),
                ),
                Positioned(
                  left: 20,
                  top: 16,
                  child: Text(
                    time,
                    style: TextStyle(
                      color: Colors.white.withAlpha(220),
                      fontSize: 44,
                      fontWeight: FontWeight.w200,
                      letterSpacing: -1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: animate ? 1600 : 0),
                    builder: (context, t, _) {
                      // The card first, then each answer a little later.
                      double phase(double from, double to) => Curves.easeOutBack
                          .transform(((t - from) / (to - from)).clamp(0, 1));
                      final card = phase(0, .45);
                      return Opacity(
                        opacity: card.clamp(0, 1),
                        child: Transform.translate(
                          offset: Offset(0, 40 * (1 - card)),
                          child: _Card(
                            title: l10n.missedWorkoutTitle,
                            body: l10n.missedWorkoutBody(
                              l10n.onbExampleWorkout,
                            ),
                            now: l10n.nowLabel,
                            actions: [
                              (l10n.stillToday, phase(.45, .7)),
                              (l10n.moveWorkoutAction, phase(.55, .8)),
                              (l10n.skip, phase(.65, .9)),
                            ],
                          ),
                        ),
                      );
                    },
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

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.body,
    required this.now,
    required this.actions,
  });
  final String title, body, now;
  final List<(String, double)> actions;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withAlpha(30),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withAlpha(26)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: const LinearGradient(colors: [_mint, _lilac]),
              ),
              child: const Icon(
                Icons.directions_run_rounded,
                size: 15,
                color: Color(0xFF09291E),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'FJELIA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Colors.white70,
              ),
            ),
            const Spacer(),
            Text(now, style: const TextStyle(fontSize: 11, color: _muted)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          body,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: Colors.white70),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final (i, (label, t)) in actions.indexed) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Opacity(
                  opacity: t.clamp(0, 1),
                  child: Transform.scale(
                    scale: .8 + .2 * t,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: i == 0
                            ? _mint.withAlpha(40)
                            : Colors.white.withAlpha(22),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: i == 0 ? _mint : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}

/// A soft moon and a scatter of stars, fixed so it looks the same each time.
class _SkyPainter extends CustomPainter {
  const _SkyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(7);
    final star = Paint()..color = Colors.white;
    for (var i = 0; i < 28; i++) {
      final o = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height * .45,
      );
      star.color = Colors.white.withAlpha(40 + random.nextInt(120));
      canvas.drawCircle(o, .6 + random.nextDouble() * .9, star);
    }
    final moon = Offset(size.width - 52, 46);
    canvas.drawCircle(
      moon,
      46,
      Paint()
        ..shader = RadialGradient(
          colors: [_lilac.withAlpha(70), _lilac.withAlpha(0)],
        ).createShader(Rect.fromCircle(center: moon, radius: 46)),
    );
    canvas.drawCircle(moon, 15, Paint()..color = const Color(0xFFEDE7FF));
    canvas.drawCircle(
      moon.translate(6, -4),
      13,
      Paint()..color = const Color(0xFF1B2140),
    );
  }

  @override
  bool shouldRepaint(covariant _SkyPainter oldDelegate) => false;
}
