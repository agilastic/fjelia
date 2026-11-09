/// The FjeliaPro analyses the large model writes from the training context.
enum ProAnalysisKind { planCheck, weekReview, racePlan, season }

/// The coach's instructions for the FjeliaPro analyses. The private package
/// supplies them; every other build has none, as it never offers FjeliaPro.
abstract class ProAnalysisPrompts {
  /// Whether this build can write the analyses.
  bool get isAvailable;

  /// The system instructions for [kind], in English and without the answer
  /// language (the app appends it); empty when not available.
  String instructions(ProAnalysisKind kind);

  /// The instructions for the morning revision: the coach reworks today's
  /// session (or swaps it within the week) and writes the push, answering in
  /// the app's JSON format; empty when not available.
  String get morningRevision;
}
