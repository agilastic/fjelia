/// One body-composition measurement from the Renpho cloud API. Wraps the raw
/// JSON and exposes typed getters using Renpho's field names.
class RenphoMeasurement {
  const RenphoMeasurement(this.raw);

  factory RenphoMeasurement.fromJson(Map<String, dynamic> json) =>
      RenphoMeasurement(json);

  final Map<String, dynamic> raw;

  /// Renpho reports `timeStamp` (or `time_stamp`) in seconds.
  DateTime get timestamp {
    final ts = (raw['timeStamp'] ?? raw['time_stamp']) as num;
    return DateTime.fromMillisecondsSinceEpoch(ts.toInt() * 1000).toLocal();
  }

  String? get scaleName => raw['scaleName']?.toString();
  double? get weight => _doubleValue('weight');
  double? get bmi => _doubleValue('bmi');
  double? get bodyFat => _doubleValue('bodyfat');
  double? get bodyWater => _doubleValue('water');
  double? get muscleMass => _doubleValue('muscle');
  double? get boneMass => _doubleValue('bone');
  double? get bmr => _doubleValue('bmr');
  double? get visceralFat => _doubleValue('visfat');
  double? get subcutaneousFat => _doubleValue('subfat');
  double? get protein => _doubleValue('protein');
  double? get bodyAge => _doubleValue('bodyage');
  double? get leanBodyMass => _doubleValue('sinew');
  double? get fatFreeWeight => _doubleValue('fatFreeWeight');
  double? get waistCm => _doubleValue('waistCm');
  int? get heartRate => _intValue('heartRate');
  double? get cardiacIndex => _doubleValue('cardiacIndex');
  String? get bodyShape => raw['bodyShape']?.toString();

  double? _doubleValue(String key) => (raw[key] as num?)?.toDouble();
  int? _intValue(String key) => (raw[key] as num?)?.toInt();
}
