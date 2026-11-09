import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/fjelia_pro.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/ai_coach_provider.dart';
import '../../providers/fjelia_pro_provider.dart';
import '../../services/ai_coach_settings.dart';
import '../../theme/fjelia_style.dart';
import '../../widgets/app_widgets.dart';
import '../ai_coach/ai_coach_screen.dart' show coachGradient;

/// The AI coach's colours, so Pro reads as part of the coach.
const _accent = coachGradient;

/// FjeliaPro: what it gives, the two subscriptions with their App Store
/// prices, buying, restoring and managing, and the terms Apple requires.
class FjeliaProSheet extends ConsumerStatefulWidget {
  const FjeliaProSheet({super.key});
  @override
  ConsumerState<FjeliaProSheet> createState() => _FjeliaProSheetState();
}

class _FjeliaProSheetState extends ConsumerState<FjeliaProSheet> {
  String chosen = proYearlyProductId;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pro = ref.watch(fjeliaProProvider);
    final active = pro.activeAt(ref.watch(proClockProvider)());
    final products = ref.watch(proProductsProvider);
    final usesFjeliaAi =
        ref.watch(aiCoachSettingsProvider).valueOrNull?.provider ==
        AiProvider.freeAi;
    ref.listen(fjeliaProProvider, (before, now) {
      final clock = ref.read(proClockProvider);
      if (before?.activeAt(clock()) != true && now.activeAt(clock())) {
        ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(SnackBar(content: Text(l.proWelcome)));
      }
    });
    return SheetPage(
      title: 'FjeliaPro',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Hero(),
          Text(
            l.proTagline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: fjInk70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            accent: _accent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (icon, text) in [
                  (Icons.bolt_outlined, l.proBenefitCoach),
                  (Icons.today_outlined, l.proBenefitPlanCheck),
                  (Icons.insights_outlined, l.proBenefitReview),
                  (Icons.flag_outlined, l.proBenefitRacePlan),
                  (Icons.leaderboard_outlined, l.proBenefitStats),
                  (Icons.psychology_alt_outlined, l.proBenefitMemory),
                  (Icons.monitor_heart_outlined, l.proBenefitEcg),
                  (Icons.copy_outlined, l.proBenefitCopy),
                ])
                  _Benefit(icon: icon, text: text),
              ],
            ),
          ),
          if (active)
            SectionCard(
              key: const ValueKey('pro-active'),
              child: Row(
                children: [
                  const Icon(Icons.verified_outlined, color: mint),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.proActiveUntil(
                        DateFormat.yMMMd().format(pro.access!.expiresAt),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            )
          else
            products.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => _Note(l.proUnavailable),
              data: (list) => list.isEmpty
                  ? _Note(l.proUnavailable)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final p in list)
                          _Plan(
                            key: ValueKey('pro-plan-${p.id}'),
                            product: p,
                            yearly: p.id == proYearlyProductId,
                            picked: p.id == chosen,
                            onTap: () => setState(() => chosen = p.id),
                          ),
                        const SizedBox(height: 4),
                        FilledButton(
                          key: const ValueKey('pro-buy'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                          onPressed: pro.busy
                              ? null
                              : () => ref
                                    .read(fjeliaProProvider.notifier)
                                    .buy(
                                      // Not firstWhere(orElse:): the list
                                      // is StoreKit's own subtype, and a
                                      // fallback typed ProductDetails
                                      // fails at run time.
                                      list
                                              .where((p) => p.id == chosen)
                                              .firstOrNull ??
                                          list.last,
                                    ),
                          child: pro.busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l.proSubscribe),
                        ),
                      ],
                    ),
            ),
          if (pro.problem case final problem?)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                switch (problem) {
                  ProProblem.store => l.proProblemStore,
                  ProProblem.service => l.proProblemService,
                  ProProblem.nothingToRestore => l.proProblemNothing,
                  ProProblem.notActive => l.proProblemNotActive,
                },
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.orange, fontSize: 13),
              ),
            ),
          if (active && !usesFjeliaAi)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _Note(l.proUsesFjeliaAi),
            ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              if (active)
                TextButton(
                  onPressed: () => launchUrl(
                    proManageUri,
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Text(l.proManage),
                ),
              TextButton(
                key: const ValueKey('pro-restore'),
                onPressed: pro.busy
                    ? null
                    : () => ref.read(fjeliaProProvider.notifier).restore(),
                child: Text(l.proRestore),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l.proAutoRenew,
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 11, height: 1.4),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton(
                onPressed: () => launchUrl(
                  proTermsUri,
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(l.proTerms),
              ),
              TextButton(
                onPressed: () => launchUrl(
                  proPrivacyUri,
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(l.proPrivacy),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The coach's glowing orb, here with Pro's bolt, and the title in the
/// coach's gradient: the same entrance as the empty coach chat.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 14),
    child: Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutBack,
          builder: (context, t, child) =>
              Transform.scale(scale: .6 + .4 * t, child: child),
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _accent,
              ),
              boxShadow: [
                BoxShadow(
                  color: _accent.first.withValues(alpha: .5),
                  blurRadius: 26,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: _accent.last.withValues(alpha: .3),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.bolt_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const GradientTitle('FjeliaPro', colors: _accent, size: 22),
      ],
    ),
  );
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: LinearGradient(
            colors: [for (final c in _accent) fjAccent(c)],
          ).createShader,
          child: Icon(icon, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, height: 1.35, color: fjInk),
          ),
        ),
      ],
    ),
  );
}

/// One subscription as a card like the app's sections. The chosen one gets
/// the coach's edge and glow, the yearly one a small gradient tag.
class _Plan extends StatelessWidget {
  const _Plan({
    super.key,
    required this.product,
    required this.yearly,
    required this.picked,
    required this.onTap,
  });
  final ProductDetails product;
  final bool yearly, picked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (picked)
              BoxShadow(
                color: _accent.first.withValues(
                  alpha: Fjelia.light ? .12 : .22,
                ),
                blurRadius: 18,
                spreadRadius: -4,
              ),
          ],
        ),
        child: Material(
          color: panel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: picked
                ? BorderSide(color: fjAccent(_accent.first), width: 1.5)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: picked ? fjGlow(_accent, strength: .8) : null,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Icon(
                      picked
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: picked ? fjAccent(_accent.first) : muted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                yearly ? l.proYearly : l.proMonthly,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: fjInk,
                                ),
                              ),
                              if (yearly) ...[
                                const SizedBox(width: 8),
                                GradientTitle(
                                  l.proBestValue,
                                  colors: const [mint, Color(0xFF3EE0FF)],
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            yearly
                                ? l.proPerYear(product.price)
                                : l.proPerMonth(product.price),
                            style: TextStyle(fontSize: 13, color: fjInk70),
                          ),
                        ],
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

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(color: muted, fontSize: 13),
    ),
  );
}
