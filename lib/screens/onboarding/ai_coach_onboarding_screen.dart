import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_ext.dart';
import '../../providers/ai_coach_provider.dart';
import '../../services/ai_coach_settings.dart';
import '../../services/local_model_catalog.dart';
import '../../widgets/app_widgets.dart' show showAppSheet;
import '../settings/ai_settings_tab.dart';
import 'training_plan_onboarding_screen.dart';

const _mint = Color(0xFF70F3C8);
const _lilac = Color(0xFFC5B4FF);
const _muted = Color(0xFFAAAEB8);

/// An explicit choice before the coach is enabled. Merely viewing this step
/// neither changes the selected provider nor sends data to a cloud service.
class AiCoachOnboardingScreen extends ConsumerStatefulWidget {
  const AiCoachOnboardingScreen({super.key});

  @override
  ConsumerState<AiCoachOnboardingScreen> createState() =>
      _AiCoachOnboardingScreenState();
}

class _AiCoachOnboardingScreenState
    extends ConsumerState<AiCoachOnboardingScreen> {
  AiCoachSettings? _settings;
  AiProvider? _savedProvider;
  AiProvider? _selected;
  bool _freeAvailable = false;
  bool _appleAvailable = false;
  bool _loading = true;
  bool _saving = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool preserveDraft = false}) async {
    try {
      final store = ref.read(aiCoachSettingsStoreProvider);
      final settings = await ref.read(aiCoachSettingsProvider.future);
      final saved = await store.readSavedProvider();
      final freeAvailable = await store.readApiKey(AiProvider.freeAi) != null;
      var appleAvailable = false;
      try {
        appleAvailable = await ref.read(
          appleIntelligenceAvailabilityProvider,
        )();
      } catch (_) {
        // Unsupported devices still offer Free AI and the other providers.
      }
      if (!mounted) return;
      setState(() {
        final unchanged =
            preserveDraft &&
            saved == _savedProvider &&
            settings.provider == _settings?.provider &&
            settings.model == _settings?.model &&
            settings.enabled == _settings?.enabled;
        if (!unchanged) {
          _selected = !settings.enabled
              ? null
              : saved != null
              ? settings.provider
              : freeAvailable
              ? AiProvider.freeAi
              : appleAvailable
              ? AiProvider.appleIntelligence
              : null;
        }
        if (_selected == AiProvider.freeAi && !freeAvailable) _selected = null;
        if (_selected == AiProvider.appleIntelligence && !appleAvailable) {
          _selected = freeAvailable ? AiProvider.freeAi : null;
        }
        _settings = settings;
        _savedProvider = saved;
        _freeAvailable = freeAvailable;
        _appleAvailable = appleAvailable;
        _loading = false;
        _failed = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  String _label(AiProvider provider) => switch (provider) {
    AiProvider.freeAi => context.l10n.freeAi,
    AiProvider.appleIntelligence => context.l10n.appleIntelligence,
    AiProvider.localQwen => context.l10n.localQwen,
    AiProvider.openai => context.l10n.openai,
    _ => provider.name[0].toUpperCase() + provider.name.substring(1),
  };

  bool get _advancedSelected =>
      _selected != null &&
      _selected != AiProvider.freeAi &&
      _selected != AiProvider.appleIntelligence;

  bool get _needsConfiguration =>
      _advancedSelected && !(_settings?.copyWith(enabled: true).ready ?? false);

  Future<void> _configure() async {
    await showAppSheet<void>(context, const AiSettingsTab());
    if (!mounted) return;
    // Settings persist their own choices. Reload them when the sheet closes,
    // including custom model names and an explicit decision to disable AI.
    await _load(preserveDraft: true);
  }

  Future<void> _continue({bool withoutAi = false}) async {
    if (_saving) return;
    if (!withoutAi && _needsConfiguration) {
      await _configure();
      return;
    }
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      final notifier = ref.read(aiCoachSettingsProvider.notifier);
      final selected = withoutAi ? null : _selected;
      if (selected == null) {
        await notifier.setEnabled(false);
        await notifier.setBriefingMode(BriefingMode.static_);
      } else {
        final store = ref.read(aiCoachSettingsStoreProvider);
        final saved = await store.readSavedProvider();
        final previous = await ref.read(aiCoachSettingsProvider.future);
        if (previous.provider != selected || saved != selected) {
          await notifier.setProvider(selected);
        }
        final current = await ref.read(aiCoachSettingsProvider.future);
        if (current.provider != selected ||
            !current.copyWith(enabled: true).ready) {
          throw StateError('Selected coach is no longer available');
        }
        await notifier.setEnabled(true);
        if (saved == null ||
            (!previous.enabled &&
                previous.briefingMode == BriefingMode.static_)) {
          await notifier.setBriefingMode(BriefingMode.ai);
        }
      }
      if (!mounted) return;
      setState(() => _saving = false);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const TrainingPlanOnboardingScreen(),
        ),
      );
      if (mounted) await _load();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
    }
  }

  void _select(AiProvider provider) => setState(() {
    _selected = provider;
    _failed = false;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: const Color(0xFF101416),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(1.1, -1),
              radius: 1.1,
              colors: [Color(0xFF203C39), Color(0xFF101416)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  children: [
                    _header(),
                    Expanded(
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(color: _mint),
                            )
                          : _settings == null
                          ? _loadError()
                          : TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: Duration(
                                milliseconds: reduceMotion ? 0 : 700,
                              ),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) => Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 16 * (1 - value)),
                                  child: child,
                                ),
                              ),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  8,
                                  24,
                                  16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _hero(),
                                    const SizedBox(height: 20),
                                    Text(
                                      l10n.aiOnboardingChoose,
                                      style: const TextStyle(
                                        color: _muted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.6,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _CoachOption(
                                      key: const ValueKey('onboarding-free-ai'),
                                      title: l10n.freeAi,
                                      detail: l10n.aiOnboardingFreeDetail,
                                      description: l10n.aiOnboardingFreeBody,
                                      badge: _freeAvailable
                                          ? l10n.aiOnboardingRecommended
                                          : null,
                                      unavailable: _freeAvailable
                                          ? null
                                          : l10n.aiOnboardingUnavailable,
                                      icon: Icons.auto_awesome_rounded,
                                      accent: _mint,
                                      selected: _selected == AiProvider.freeAi,
                                      onTap: _saving || !_freeAvailable
                                          ? null
                                          : () => _select(AiProvider.freeAi),
                                    ),
                                    const SizedBox(height: 12),
                                    _CoachOption(
                                      key: const ValueKey(
                                        'onboarding-apple-ai',
                                      ),
                                      title: l10n.appleIntelligence,
                                      detail: l10n.aiOnboardingOnDevice,
                                      unavailable: _appleAvailable
                                          ? null
                                          : l10n.aiOnboardingUnavailable,
                                      icon: Icons.apple_rounded,
                                      accent: _lilac,
                                      selected:
                                          _selected ==
                                          AiProvider.appleIntelligence,
                                      onTap: _saving || !_appleAvailable
                                          ? null
                                          : () => _select(
                                              AiProvider.appleIntelligence,
                                            ),
                                    ),
                                    const SizedBox(height: 12),
                                    _CoachOption(
                                      key: const ValueKey('onboarding-more-ai'),
                                      title: _advancedSelected
                                          ? _label(_selected!)
                                          : l10n.aiOnboardingMore,
                                      detail: _advancedSelected
                                          ? _selected == AiProvider.localQwen
                                                ? localModelSpec(
                                                    _settings!.model,
                                                  ).label
                                                : _settings!.model
                                          : l10n.aiOnboardingMoreBody,
                                      icon: Icons.tune_rounded,
                                      accent: const Color(0xFF9FB8FF),
                                      selected: _advancedSelected,
                                      onTap: _saving ? null : _configure,
                                      disclosure: true,
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.verified_user_outlined,
                                          color: _mint,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 9),
                                        Expanded(
                                          child: Text(
                                            _selected?.isLocal == true
                                                ? l10n.aiOnboardingLocalBody
                                                : l10n.aiOnboardingConsent,
                                            style: const TextStyle(
                                              color: _muted,
                                              fontSize: 12,
                                              height: 1.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_failed) ...[
                                      const SizedBox(height: 16),
                                      Text(
                                        l10n.aiOnboardingError,
                                        style: const TextStyle(
                                          color: Color(0xFFFFB5A8),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                    ),
                    if (_settings != null) _footer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 24, 12),
    child: Column(
      children: [
        Row(
          children: [
            if (Navigator.of(context).canPop())
              IconButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                tooltip: context.l10n.back,
                icon: const Icon(Icons.arrow_back_rounded, size: 21),
              )
            else
              const SizedBox(width: 12, height: 48),
            const Text(
              'FJELIA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 3.8,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                context.l10n.aiOnboardingStep,
                textAlign: TextAlign.right,
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 4),
          child: Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: Container(
                  height: 3,
                  margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: index < 2
                        ? _mint.withAlpha(index == 0 ? 90 : 255)
                        : Colors.white.withAlpha(24),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _hero() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.aiOnboardingTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.4,
                height: 1.12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const _CoachOrb(),
        ],
      ),
      const SizedBox(height: 14),
      Text(
        context.l10n.aiOnboardingSubtitle,
        style: const TextStyle(color: _muted, fontSize: 14, height: 1.5),
      ),
    ],
  );

  Widget _loadError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.aiOnboardingError, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _loading = true;
                _failed = false;
              });
              ref.invalidate(aiCoachSettingsProvider);
              _load();
            },
            child: Text(context.l10n.retry),
          ),
        ],
      ),
    ),
  );

  Widget _footer() {
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101416),
        border: Border(top: BorderSide(color: Colors.white.withAlpha(14))),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            key: const ValueKey('onboarding-ai-continue'),
            onPressed: _saving ? null : _continue,
            style: FilledButton.styleFrom(
              backgroundColor: _mint,
              foregroundColor: const Color(0xFF09291E),
              disabledBackgroundColor: _mint.withAlpha(100),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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
                      Flexible(
                        child: Text(
                          _selected == null
                              ? l10n.aiOnboardingWithout
                              : _needsConfiguration
                              ? l10n.aiOnboardingConfigure
                              : l10n.aiOnboardingContinue(_label(_selected!)),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
          ),
          if (_selected != null)
            TextButton(
              key: const ValueKey('onboarding-without-ai'),
              onPressed: _saving ? null : () => _continue(withoutAi: true),
              style: TextButton.styleFrom(
                foregroundColor: _muted,
                minimumSize: const Size(48, 44),
              ),
              child: Text(
                l10n.aiOnboardingWithout,
                style: const TextStyle(fontSize: 12),
              ),
            )
          else
            const SizedBox(height: 12),
          Text(
            l10n.aiOnboardingChangeLater,
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
}

class _CoachOption extends StatelessWidget {
  const _CoachOption({
    super.key,
    required this.title,
    required this.detail,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
    this.description,
    this.badge,
    this.unavailable,
    this.disclosure = false,
  });

  final String title, detail;
  final String? description, badge, unavailable;
  final IconData icon;
  final Color accent;
  final bool selected, disclosure;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = unavailable != null;
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      child: AnimatedContainer(
        duration: Duration(
          milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 220,
        ),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: selected
                ? [accent.withAlpha(30), accent.withAlpha(9)]
                : [Colors.white.withAlpha(9), Colors.white.withAlpha(4)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? accent : Colors.white.withAlpha(22),
            width: 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withAlpha(12),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Opacity(
                opacity: disabled ? .5 : 1,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accent.withAlpha(18),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: accent.withAlpha(32)),
                      ),
                      child: Icon(icon, color: accent, size: 24),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (badge != null) ...[
                            Text(
                              badge!.toUpperCase(),
                              style: TextStyle(
                                color: accent,
                                fontSize: 9,
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                          ],
                          Text(
                            title,
                            style: TextStyle(
                              color: selected ? accent : Colors.white,
                              fontSize: disclosure ? 14 : 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            unavailable ?? detail,
                            style: TextStyle(
                              color: selected
                                  ? const Color(0xFFDBEBE5)
                                  : _muted,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                          if (description != null && !disabled) ...[
                            const SizedBox(height: 7),
                            Text(
                              description!,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Icon(
                        disclosure
                            ? Icons.arrow_forward_ios_rounded
                            : selected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: disclosure ? 15 : 21,
                        color: selected ? accent : Colors.white30,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Native vector art: an orbital coach symbol, without fabricated health data.
class _CoachOrb extends StatelessWidget {
  const _CoachOrb();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(
        milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 1200,
      ),
      curve: Curves.easeOutCubic,
      builder: (_, value, _) => SizedBox.square(
        dimension: 100,
        child: CustomPaint(painter: _OrbPainter(value)),
      ),
    ),
  );
}

class _OrbPainter extends CustomPainter {
  const _OrbPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(size.shortestSide / 116);
    canvas.translate(-center.dx, -center.dy);
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [_mint.withAlpha(42), _mint.withAlpha(0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, glow);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-.5 + .3 * progress);
    final orbit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8
      ..color = _mint.withAlpha(75);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 108, height: 75),
      orbit,
    );
    canvas.rotate(1.25);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 108, height: 75),
      orbit..color = _lilac.withAlpha(65),
    );
    canvas.restore();
    final core = Rect.fromCircle(center: center, radius: radius * .49);
    canvas.drawCircle(
      center,
      radius * .49,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8CFBD8), Color(0xFF00A980), Color(0xFF22524F)],
        ).createShader(core),
    );
    canvas.drawCircle(
      center,
      radius * .49,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withAlpha(100),
    );
    final star = Path();
    for (var i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + i * math.pi / 4;
      final length = i.isEven ? 17.0 : 6.0;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * length;
      if (i == 0) {
        star.moveTo(point.dx, point.dy);
      } else {
        star.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(star..close(), Paint()..color = const Color(0xFFE1FFF3));
    for (final (offset, color, dotRadius) in [
      (const Offset(43, -29), _lilac, 4.0),
      (const Offset(-43, 27), _mint, 3.0),
      (const Offset(-31, -41), Colors.white70, 1.8),
    ]) {
      canvas.drawCircle(center + offset, dotRadius, Paint()..color = color);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OrbPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
