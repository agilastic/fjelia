import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

void registerLocalModelLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      ['MLX Swift and local model dependencies'],
      await rootBundle.loadString(
        'assets/licenses/local-model-dependencies.txt',
      ),
    );
    yield LicenseEntryWithLineBreaks([
      'Qwen3.5',
    ], await rootBundle.loadString('assets/licenses/qwen35.txt'));
  });
}
