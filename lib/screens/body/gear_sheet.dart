import 'package:fjelia_views/fjelia_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_ext.dart';
import '../../providers/body_views_provider.dart';
import '../../theme/fjelia_style.dart';
import '../../widgets/app_widgets.dart';

const _accent = [Color(0xFF00D4A0), Color(0xFF6FA8FF)];

Color _wearColor(GearWear w) => switch (w) {
  GearWear.fine => const Color(0xFF00D4A0),
  GearWear.soon => const Color(0xFFFFB13D),
  GearWear.due => const Color(0xFFFF4D8D),
  GearWear.retired => muted,
};

String _kindName(BuildContext context, String kind) => switch (kind) {
  'shoes' => context.l10n.gearKindShoes,
  'bike' => context.l10n.gearKindBike,
  _ => context.l10n.gearKindOther,
};

/// Load page: the gear in use, how far each has gone. Opens the gear sheet.
class GearCard extends ConsumerWidget {
  const GearCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gear = ref.watch(gearProvider).valueOrNull ?? const <GearItem>[];
    final inUse = [
      for (final g in gear)
        if (g.retiredAt == null) g,
    ];
    return SectionCard(
      title: context.l10n.gearTitle,
      accent: _accent,
      onTap: () => showAppSheet(context, const GearSheet()),
      child: inUse.isEmpty
          ? Text(
              context.l10n.gearEmpty,
              style: TextStyle(fontSize: 13, color: fjInk70),
            )
          : Column(
              children: [
                for (final g in inUse.take(3))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(child: Text(g.name)),
                        Text(
                          '${g.km.round()} km',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _wearColor(g.wear),
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

/// All gear, with adding, editing and retiring.
class GearSheet extends ConsumerWidget {
  const GearSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final gear = ref.watch(gearProvider);
    return SheetPage(
      title: l.gearTitle,
      actions: [
        IconButton(
          tooltip: l.gearAdd,
          icon: const Icon(Icons.add),
          onPressed: () => _edit(context, ref),
        ),
      ],
      child: gear.when(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => DataError(e),
        data: (items) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (items.isEmpty) ...[
              Text(l.gearEmpty, style: TextStyle(color: fjInk70)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => _edit(context, ref),
                child: Text(l.gearAdd),
              ),
            ],
            for (final g in items) _GearTile(item: g),
          ],
        ),
      ),
    );
  }
}

class _GearTile extends ConsumerWidget {
  const _GearTile({required this.item});
  final GearItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final limit = item.retireAtKm;
    final edits = ref.read(gearEditsProvider);
    return SectionCard(
      title: item.name,
      accent: _accent,
      onTap: () => _edit(context, ref, item: item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              _kindName(context, item.kind),
              ?item.brand,
              l.gearActivities(item.activities),
            ].join(' · '),
            style: TextStyle(fontSize: 12, color: fjInk70),
          ),
          const SizedBox(height: 6),
          Text(
            '${item.km.round()} km',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _wearColor(item.wear),
            ),
          ),
          if (limit != null) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: (item.km / limit).clamp(0, 1),
              color: _wearColor(item.wear),
              backgroundColor: fjInk10,
              minHeight: 6,
            ),
            const SizedBox(height: 4),
            Text(switch (item.wear) {
              GearWear.due => l.gearDue(limit.round()),
              GearWear.retired => l.gearRetired,
              _ => l.gearLeft((limit - item.km).round(), limit.round()),
            }, style: TextStyle(fontSize: 12, color: fjInk70)),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () async {
                item.retiredAt == null
                    ? await edits.retire(item.id)
                    : await edits.reactivate(item.id);
                ref.invalidate(gearProvider);
              },
              child: Text(
                item.retiredAt == null ? l.gearRetire : l.gearUseAgain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _edit(BuildContext context, WidgetRef ref, {GearItem? item}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _GearForm(item: item),
      ),
    ).then((_) => ref.invalidate(gearProvider));

class _GearForm extends ConsumerStatefulWidget {
  const _GearForm({this.item});
  final GearItem? item;
  @override
  ConsumerState<_GearForm> createState() => _GearFormState();
}

class _GearFormState extends ConsumerState<_GearForm> {
  late final _name = TextEditingController(text: widget.item?.name ?? '');
  late final _brand = TextEditingController(text: widget.item?.brand ?? '');
  late final _start = TextEditingController(
    text: (widget.item?.startKm ?? 0).round().toString(),
  );
  late final _retire = TextEditingController(
    text: widget.item?.retireAtKm?.round().toString() ?? '',
  );
  late var _kind = widget.item?.kind ?? 'shoes';
  late var _default = widget.item?.isDefault ?? true;

  @override
  void dispose() {
    for (final c in [_name, _brand, _start, _retire]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final edits = ref.read(gearEditsProvider);
    final start = double.tryParse(_start.text.replaceAll(',', '.')) ?? 0;
    final retire = double.tryParse(_retire.text.replaceAll(',', '.'));
    final name = _name.text.trim().isEmpty
        ? _kindName(context, _kind)
        : _name.text.trim();
    final brand = _brand.text.trim().isEmpty ? null : _brand.text.trim();
    final item = widget.item;
    if (item == null) {
      await edits.add(
        kind: _kind,
        name: name,
        brand: brand,
        sports: switch (_kind) {
          'shoes' => const ['running'],
          'bike' => const ['cycling'],
          _ => const [],
        },
        isDefault: _default,
        startKm: start,
        retireAtKm: retire,
      );
    } else {
      await edits.update(
        item.id,
        name: name,
        brand: brand ?? '',
        isDefault: _default,
        startKm: start,
        retireAtKm: retire ?? 0,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.item == null ? l.gearAdd : l.gearEdit,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (widget.item == null) ...[
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'shoes', label: Text(l.gearKindShoes)),
                  ButtonSegment(value: 'bike', label: Text(l.gearKindBike)),
                  ButtonSegment(value: 'other', label: Text(l.gearKindOther)),
                ],
                selected: {_kind},
                onSelectionChanged: (s) => setState(() => _kind = s.first),
              ),
            ],
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: l.gearName),
            ),
            TextField(
              controller: _brand,
              decoration: InputDecoration(labelText: l.gearBrand),
            ),
            TextField(
              controller: _start,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l.gearStartKm),
            ),
            TextField(
              controller: _retire,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l.gearRetireAt),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _default,
              onChanged: (v) => setState(() => _default = v),
              title: Text(l.gearDefault),
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: _save, child: Text(l.save)),
          ],
        ),
      ),
    );
  }
}

/// Which gear an activity was done with, and a menu to choose another.
class ActivityGearPicker extends ConsumerWidget {
  const ActivityGearPicker({super.key, required this.activityId});
  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gear = ref.watch(gearProvider).valueOrNull ?? const <GearItem>[];
    if (gear.isEmpty) return const SizedBox.shrink();
    final current = ref.watch(activityGearProvider(activityId)).valueOrNull;
    return Row(
      children: [
        Icon(Icons.hiking, size: 16, color: fjInk70),
        const SizedBox(width: 6),
        Text(context.l10n.gearTitle, style: TextStyle(color: fjInk70)),
        const Spacer(),
        DropdownButton<String>(
          value: current ?? '',
          underline: const SizedBox.shrink(),
          items: [
            DropdownMenuItem(value: '', child: Text(context.l10n.gearNone)),
            for (final g in gear)
              if (g.retiredAt == null || g.id == current)
                DropdownMenuItem(value: g.id, child: Text(g.name)),
          ],
          onChanged: (id) async {
            await ref
                .read(gearEditsProvider)
                .link(activityId, id == null || id.isEmpty ? null : id);
            ref.invalidate(gearProvider);
          },
        ),
      ],
    );
  }
}
