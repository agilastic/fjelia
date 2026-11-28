import 'dart:async';

import 'package:fjelia_views/fjelia_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/body_views_provider.dart';
import '../../theme/fjelia_style.dart';
import '../../widgets/app_widgets.dart';

const _accent = [Color(0xFF9D7BFF), Color(0xFF6FA8FF)];

String diaryKindLabel(AppLocalizations l, DiaryKind k) => switch (k) {
  DiaryKind.activity => l.diaryKindActivity,
  DiaryKind.session => l.diaryKindSession,
  DiaryKind.feeling => l.diaryKindFeeling,
  DiaryKind.coachNote => l.diaryKindCoach,
  DiaryKind.absence => l.diaryKindAbsence,
  DiaryKind.ecg => l.diaryKindEcg,
};

/// Load page: the newest notes. Opens the diary.
class DiaryCard extends ConsumerWidget {
  const DiaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(diaryProvider('')).valueOrNull ?? const [];
    return SectionCard(
      title: context.l10n.diaryTitle,
      accent: _accent,
      onTap: () => showAppSheet(context, const DiarySheet()),
      child: notes.isEmpty
          ? Text(
              context.l10n.diaryEmpty,
              style: TextStyle(fontSize: 13, color: fjInk70),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final n in notes.take(2))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      '${DateFormat.MMMd().format(n.at)} · ${n.text}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Every note the athlete wrote, newest first, searchable.
class DiarySheet extends ConsumerStatefulWidget {
  const DiarySheet({super.key});
  @override
  ConsumerState<DiarySheet> createState() => _DiarySheetState();
}

class _DiarySheetState extends ConsumerState<DiarySheet> {
  var _query = '';
  Timer? _typing;

  @override
  void dispose() {
    _typing?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final notes = ref.watch(diaryProvider(_query));
    return SheetPage(
      title: l.diaryTitle,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l.diarySearch,
              ),
              onChanged: (v) {
                _typing?.cancel();
                _typing = Timer(
                  const Duration(milliseconds: 250),
                  () => setState(() => _query = v),
                );
              },
            ),
          ),
          Expanded(
            child: notes.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => DataError(e),
              data: (entries) => entries.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _query.isEmpty ? l.diaryEmpty : l.diaryNoResults,
                        style: TextStyle(color: fjInk70),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final e in entries)
                          SectionCard(
                            accent: _accent,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  [
                                    DateFormat.yMMMd().format(e.at),
                                    ?e.title,
                                    if (e.effort case final r?)
                                      l.diaryEffort(r),
                                    diaryKindLabel(l, e.kind),
                                  ].join(' · '),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: fjInk70,
                                  ),
                                ),
                                if (e.text.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(e.text),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
