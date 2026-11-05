part of 'database.dart';

extension SummaryMetricPersistence on AppDatabase {
  Future<Map<String, SummaryMetricOrigin>> getMetricOrigins(
    String table,
    DateTime date,
  ) async {
    final rows =
        await (select(summaryMetricOrigins)..where(
              (t) =>
                  t.summaryTable.equals(table) &
                  t.date.equals(AppDatabase._dayStart(date)),
            ))
            .get();
    return {for (final row in rows) row.metric: row};
  }

  Future<void> _mergeSummary<T>(
    TableInfo<Table, T> table,
    DateTime date,
    Map<String, Expression> candidates,
    SourceGroup group, {
    Map<String, String> metricSources = const {},
  }) async {
    final order = await _metricPriorityReader(group);
    final day = AppDatabase._dayStart(date);
    final end = DateTime(day.year, day.month, day.day + 1);
    await transaction(() async {
      final existing = await customSelect(
        'SELECT * FROM "${table.actualTableName}" WHERE date >= ? AND date < ? LIMIT 1',
        variables: [
          Variable.withInt(day.millisecondsSinceEpoch ~/ 1000),
          Variable.withInt(end.millisecondsSinceEpoch ~/ 1000),
        ],
      ).getSingleOrNull();
      final origins = await getMetricOrigins(table.actualTableName, day);
      final sourceExpression = candidates['source'];
      final rowSource = sourceExpression is Variable
          ? sourceExpression.value as String?
          : null;
      final patch = <String, Expression>{};
      final writes = <SummaryMetricOriginsCompanion>[];
      String sourceOf(String key) =>
          metricSources[key] ??
          rowSource ??
          (key == 'computed_energie' ? 'computed' : 'unknown');
      bool accepts(String key) {
        final source = sourceOf(key);
        final previous = origins[key]?.source ?? 'unknown';
        // An empty night (0 s asleep, score 0) is no measurement: another
        // source's real night may replace it.
        final stored = existing?.data[key];
        final hasValue =
            stored != null &&
            !(table.actualTableName == 'sleep_records' && stored == 0);
        return !hasValue ||
            source == 'computed' ||
            source == 'manual' ||
            (source != 'unknown' && previous == 'unknown') ||
            shouldOverwrite(previous, source, order);
      }

      // A night's stages are one measurement: totals, window, timeline and
      // curves all come from the same source. Otherwise one watch's totals
      // end up under another's timeline.
      final night = table.actualTableName == 'sleep_records'
          ? _nightColumns
          : const <String>{};
      final total = candidates['total_sleep_seconds'];
      final nightAccepted =
          night.isNotEmpty &&
          total is Variable &&
          total.value != null &&
          accepts('total_sleep_seconds');
      for (final key in night) {
        if (!nightAccepted) break;
        final expression = candidates[key];
        if (expression is Variable && expression.value != null) continue;
        // The new night has none: the old source's must go with it.
        if (existing?.data[key] == null) continue;
        patch[key] = const Variable<Object>(null);
        writes.add(
          SummaryMetricOriginsCompanion.insert(
            summaryTable: table.actualTableName,
            date: day,
            metric: key,
            source: sourceOf('total_sleep_seconds'),
            quality: 'observed',
            updatedAt: DateTime.now(),
          ),
        );
      }
      for (final entry in candidates.entries) {
        if (['id', 'date', 'source'].contains(entry.key)) continue;
        final expression = entry.value;
        if (expression is! Variable || expression.value == null) continue;
        final source = sourceOf(entry.key);
        final accept = night.contains(entry.key) && total is Variable
            ? nightAccepted
            : accepts(entry.key);
        if (!accept) continue;
        patch[entry.key] = expression;
        writes.add(
          SummaryMetricOriginsCompanion.insert(
            summaryTable: table.actualTableName,
            date: day,
            metric: entry.key,
            source: source,
            quality: source == 'unknown'
                ? 'unknown'
                : source == 'computed'
                ? 'derived'
                : 'observed',
            updatedAt: DateTime.now(),
          ),
        );
      }
      if (patch.isEmpty) {
        if (existing == null) {
          await into(
            table,
          ).insert(RawValuesInsertable<T>({'date': Variable<DateTime>(day)}));
        }
        return;
      }
      final sources = {
        for (final e in origins.entries)
          if (!patch.containsKey(e.key)) e.value.source,
        for (final w in writes) w.source.value,
      };
      patch['source'] = Variable<String>(
        sources.length == 1 ? sources.single : 'mixed',
      );
      if (existing == null) {
        patch['date'] = Variable<DateTime>(day);
        await into(table).insert(RawValuesInsertable<T>(patch));
      } else {
        final idColumn = table.columnsByName['id'] as GeneratedColumn<int>;
        await (update(table)
              ..where((_) => idColumn.equals(existing.read<int>('id'))))
            .write(RawValuesInsertable<T>(patch));
      }
      await batch(
        (b) => b.insertAllOnConflictUpdate(summaryMetricOrigins, writes),
      );
    });
  }

  /// The columns of one night's stage measurement, see [_mergeSummary].
  static const _nightColumns = {
    'total_sleep_seconds',
    'deep_sleep_seconds',
    'light_sleep_seconds',
    'rem_sleep_seconds',
    'awake_sleep_seconds',
    'sleep_start',
    'sleep_end',
    'phases_json',
    'night_curves_json',
  };

  Future<void> _backfillUnknownMetricOrigins() async {
    // A legacy row's last source cannot prove where each existing field came from.
    for (final TableInfo table in [hrvRecords, sleepRecords, wellnessRecords]) {
      final rows = await customSelect(
        'SELECT * FROM "${table.actualTableName}"',
      ).get();
      for (final row in rows) {
        for (final field in row.data.entries) {
          if (['id', 'date', 'source'].contains(field.key) ||
              field.value == null) {
            continue;
          }
          await into(summaryMetricOrigins).insert(
            SummaryMetricOriginsCompanion.insert(
              summaryTable: table.actualTableName,
              date: AppDatabase._dayStart(
                DateTime.fromMillisecondsSinceEpoch(
                  row.read<int>('date') * 1000,
                ),
              ),
              metric: field.key,
              source: 'unknown',
              quality: 'legacy_unknown',
              updatedAt: DateTime.now(),
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }
      }
    }
  }
}
