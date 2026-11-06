import 'ftms.dart';
import 'training_device.dart';

String trainingUuid(String value) {
  final uuid = value.toLowerCase().replaceAll('-', '');
  if (uuid.length == 4) return uuid;
  if (uuid.length == 32 &&
      uuid.startsWith('0000') &&
      uuid.substring(8) == '00001000800000805f9b34fb') {
    return uuid.substring(4, 8);
  }
  return value.toLowerCase();
}

class TrainingGattCharacteristic {
  const TrainingGattCharacteristic({
    required this.uuid,
    this.read = false,
    this.write = false,
    this.notify = false,
    this.indicate = false,
  });
  final String uuid;
  final bool read, write, notify, indicate;
  bool get streams => notify || indicate;
  Map<String, Object> toJson() => {
    'uuid': trainingUuid(uuid),
    'read': read,
    'write': write,
    'notify': notify,
    'indicate': indicate,
  };
}

class TrainingGattService {
  const TrainingGattService(this.uuid, this.characteristics);
  final String uuid;
  final List<TrainingGattCharacteristic> characteristics;
  Map<String, Object> toJson() => {
    'uuid': trainingUuid(uuid),
    'characteristics': [for (final c in characteristics) c.toJson()],
  };
}

/// An inventory only: no characteristic values or account data are read.
class TrainingBleReport {
  const TrainingBleReport({required this.device, required this.services});
  final TrainingDevice device;
  final List<TrainingGattService> services;

  bool streams(String service, String characteristic) => services.any(
    (s) =>
        trainingUuid(s.uuid) == trainingUuid(service) &&
        s.characteristics.any(
          (c) =>
              trainingUuid(c.uuid) == trainingUuid(characteristic) && c.streams,
        ),
  );
  List<FtmsMachine> get machines => [
    for (final m in FtmsMachine.values)
      if (streams('1826', m.characteristic)) m,
  ];
  bool get runningSpeed => streams('1814', '2a53');
  bool get canRecord => machines.isNotEmpty || runningSpeed;
  Map<String, Object> toJson() => {
    'format': 'fjelia-training-ble-v1',
    'device': device.toJson(),
    'ftms_machines': [for (final m in machines) m.name],
    'running_speed_and_cadence': runningSpeed,
    'services': [for (final s in services) s.toJson()],
  };
}

class UnsupportedTrainingDevice implements Exception {
  const UnsupportedTrainingDevice(this.report);
  final TrainingBleReport report;
  @override
  String toString() => 'This console exposes no supported workout data.';
}
