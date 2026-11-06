class TrainingDevice {
  const TrainingDevice({required this.id, required this.name, this.rssi = 0});
  final String id, name;
  final int rssi;
  Map<String, Object> toJson() => {'id': id, 'name': name};
  factory TrainingDevice.fromJson(Map<String, dynamic> json) =>
      TrainingDevice(id: json['id'] as String, name: json['name'] as String);
}
