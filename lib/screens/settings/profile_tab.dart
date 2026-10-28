import '../../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/user_profile_provider.dart';
import '../../widgets/app_widgets.dart';
import 'hr_zones_tab.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => SheetPage(
    title: context.l10n.profile,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          child: Column(
            children: [
              for (final e in [
                (
                  context.l10n.basics,
                  ref.watch(userProfileProvider).valueOrNull?.birthYear == null
                      ? context.l10n.birthYearHeightWaist
                      : '${ref.watch(userProfileProvider).valueOrNull!.birthYear} · age ${ref.watch(userProfileProvider).valueOrNull!.age?.round()}',
                  0,
                ),
                (context.l10n.habits, context.l10n.smokingAlcohol, 1),
                (context.l10n.clinicalLab, context.l10n.hba1cLipidsKidney, 2),
              ])
                ListTile(
                  title: Text(e.$1),
                  subtitle: Text(
                    e.$2,
                    style: const TextStyle(fontSize: 11, color: muted),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: [Colors.lightBlue, Colors.orange, mint][e.$3],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      [
                        Icons.person_outline,
                        Icons.local_fire_department,
                        Icons.science_outlined,
                      ][e.$3],
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: muted,
                  ),
                  onTap: () =>
                      showAppSheet(context, ProfileEditor(section: e.$3)),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class ProfileEditor extends ConsumerWidget {
  const ProfileEditor({super.key, required this.section});
  final int section;
  @override
  Widget build(BuildContext context, WidgetRef ref) => SheetPage(
    title: [
      context.l10n.basics,
      context.l10n.habits,
      context.l10n.clinicalLab,
    ][section],
    child: ref
        .watch(userProfileProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => DataError(e),
          data: (p) {
            Future<void> save(String key, Object? value) =>
                runUiAction(context, () async {
                  final current = await ref.read(userProfileProvider.future);
                  await ref
                      .read(userProfileProvider.notifier)
                      .save(
                        UserProfile.fromJson({...current.toJson(), key: value}),
                      );
                });
            Widget number(
              String label,
              String key, {
              String unit = '',
              bool integer = false,
              num? min,
              num? max,
            }) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 10, color: muted),
                  ),
                  const SizedBox(height: 5),
                  TextFormField(
                    key: ValueKey(key),
                    initialValue: p.toJson()[key]?.toString(),
                    style: const TextStyle(fontSize: 13),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: !integer,
                    ),
                    decoration: InputDecoration(suffixText: unit),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (s) {
                      if (s == null || s.isEmpty) return null;
                      final n = num.tryParse(s.replaceAll(',', '.'));
                      return n == null ||
                              (min != null && n < min) ||
                              (max != null && n > max)
                          ? context.l10n.enterAValidValue
                          : null;
                    },
                    onChanged: (s) {
                      final n = num.tryParse(s.replaceAll(',', '.'));
                      if (s.isEmpty) {
                        save(key, null);
                      } else if (n != null &&
                          (min == null || n >= min) &&
                          (max == null || n <= max)) {
                        save(key, integer ? n.toInt() : n.toDouble());
                      }
                    },
                  ),
                  if (key == 'birthYear' && p.age != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        context.l10n.ageRound(p.age?.round() ?? ""),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            );
            Widget options(
              String label,
              String key,
              Map<String, String> values,
            ) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(
                  label,
                  color: section == 1
                      ? Colors.orange
                      : section == 2
                      ? mint
                      : Colors.lightBlue,
                ),
                Row(
                  children: [
                    for (final e in values.entries)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              minimumSize: const Size(0, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: p.toJson()[key] == e.key
                                  ? Colors.lightBlue.withValues(alpha: .13)
                                  : const Color(0xFF282828),
                              side: BorderSide(
                                color: p.toJson()[key] == e.key
                                    ? Colors.lightBlue.withValues(alpha: .6)
                                    : Colors.transparent,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: () => save(key, e.key),
                            child: Text(
                              e.value,
                              style: TextStyle(
                                fontSize: 10,
                                color: p.toJson()[key] == e.key
                                    ? Colors.lightBlue
                                    : muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            );
            return ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              children: [
                if (section == 0) ...[
                  SectionLabel(context.l10n.basics),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: number(
                          context.l10n.birthYear,
                          'birthYear',
                          integer: true,
                          min: 1900,
                          max: DateTime.now().year,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: number(
                          context.l10n.height,
                          'heightCm',
                          unit: 'cm',
                          min: 50,
                          max: 260,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: number(
                          context.l10n.waist,
                          'waistCm',
                          unit: 'cm',
                          min: 20,
                          max: 300,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    context.l10n.updateWaistMonthlyUsedFor,
                    style: TextStyle(fontSize: 9, color: muted),
                  ),
                  SectionLabel(context.l10n.hrZones),
                  SectionCard(
                    onTap: () => showAppSheet(context, const HrZonesTab()),
                    child: const HrZonesPreview(),
                  ),
                  options(context.l10n.sex, 'sex', {
                    'm': context.l10n.male,
                    'f': context.l10n.female,
                    if (p.sex == 'x') 'x': context.l10n.other,
                  }),
                ],
                if (section == 1) ...[
                  options(context.l10n.smoking, 'smokingStatus', {
                    'never': context.l10n.never,
                    'former': context.l10n.former,
                    'current': context.l10n.current,
                  }),
                  if (p.smokingStatus == 'former')
                    number(
                      context.l10n.yearsSinceQuit,
                      'yearsSinceQuit',
                      unit: 'y',
                      integer: true,
                      min: 0,
                      max: 100,
                    ),
                  if (p.smokingStatus == 'current')
                    number(
                      context.l10n.cigarettesPerDay,
                      'cigarettesPerDay',
                      integer: true,
                      min: 0,
                      max: 100,
                    ),
                  SectionLabel(context.l10n.alcohol),
                  number(
                    context.l10n.standardDrinksPerMonth,
                    'alcoholDrinksPerMonth',
                    integer: true,
                    min: 0,
                  ),
                  Text(
                    context.l10n.t1Drink033L,
                    style: TextStyle(fontSize: 10, color: muted),
                  ),
                ],
                if (section == 2) ...[
                  SectionLabel(context.l10n.clinicalLabsOptional),
                  SectionLabel(context.l10n.glycemic),
                  number(
                    context.l10n.hba1c,
                    'hba1cPercent',
                    unit: '%',
                    min: 2,
                    max: 20,
                  ),
                  Text(
                    context.l10n.optimalForLongevity48,
                    style: TextStyle(fontSize: 9, color: muted),
                  ),
                  options(context.l10n.diabetes, 'diabetesType', {
                    'none': context.l10n.none,
                    'prediabetes': context.l10n.prediabetes,
                    'type1': context.l10n.type1,
                    'type2': context.l10n.type2,
                  }),
                  SectionLabel(context.l10n.lipids),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: number(
                          context.l10n.apob,
                          'apoB',
                          unit: 'mg/dL',
                          min: 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: number(
                          context.l10n.hdlCholesterol,
                          'hdlCholesterol',
                          unit: 'mg/dL',
                          min: 0,
                        ),
                      ),
                    ],
                  ),
                  number(
                    context.l10n.ldlCholesterol,
                    'ldlCholesterol',
                    unit: 'mg/dL',
                    min: 0,
                  ),
                  Text(
                    context.l10n.apobReplacesLdlWhenBoth,
                    style: TextStyle(fontSize: 9, color: muted),
                  ),
                  SectionLabel(context.l10n.inflammationKidney),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: number('hs-CRP', 'hsCrp', unit: 'mg/L', min: 0),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: number('eGFR', 'eGfr', min: 0)),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  context.l10n.changesAreSavedAutomatically,
                  style: TextStyle(color: muted, fontSize: 10),
                ),
              ],
            );
          },
        ),
  );
}
