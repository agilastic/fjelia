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
      for (final entry in candidates.entries) {
        if (['id', 'date', 'source'].contains(entry.key)) continue;
        final expression = entry.value;
        if (expression is! Variable || expression.value == null) continue;
        final source =
            metricSources[entry.key] ??
            rowSource ??
            (entry.key == 'computed_energie' ? 'computed' : 'unknown');
        final previous = origins[entry.key]?.source ?? 'unknown';
        final hasValue = existing?.data[entry.key] != null;
        final accept =
            !hasValue ||
            source == 'computed' ||
            source == 'manual' ||
            (source != 'unknown' && previous == 'unknown') ||
            shouldOverwrite(previous, source, order);
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
