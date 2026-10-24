enum SummaryKind { recovery, sleep, wellness }

class MetricProvenance {
  const MetricProvenance({
    required this.source,
    required this.quality,
    required this.updatedAt,
  });
  final String source, quality;
  final DateTime updatedAt;
  bool get known => source != 'unknown';
}
