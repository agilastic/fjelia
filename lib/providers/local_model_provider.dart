import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/local_model_service.dart';

final localModelServiceProvider = Provider.family<LocalModelService, String>((
  ref,
  modelId,
) {
  final service = LocalModelService(model: localModelSpec(modelId));
  ref.onDispose(service.cancelDownload);
  return service;
});

final localModelProvider =
    AsyncNotifierProvider.family<LocalModelNotifier, LocalModelStatus, String>(
      LocalModelNotifier.new,
    );

class LocalModelNotifier extends FamilyAsyncNotifier<LocalModelStatus, String> {
  late String _modelId;
  LocalModelService get _service =>
      ref.read(localModelServiceProvider(_modelId));

  @override
  Future<LocalModelStatus> build(String modelId) {
    _modelId = modelId;
    return _service.inspect();
  }

  Future<void> download() async {
    final initial = state.valueOrNull;
    if (initial == null || !initial.supported || initial.downloading) return;
    state = AsyncData(initial.copyWith(downloading: true));
    var lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);
    try {
      await _service.download((bytes, total) {
        final now = DateTime.now();
        if (bytes < total && now.difference(lastUpdate).inMilliseconds < 150) {
          return;
        }
        lastUpdate = now;
        state = AsyncData(
          initial.copyWith(downloading: true, downloadedBytes: bytes),
        );
      });
      state = AsyncData(await _service.inspect());
    } catch (e) {
      final current = await _service.inspect();
      state = AsyncData(
        current.copyWith(
          error: e is LocalModelException && e.code == 'cancelled'
              ? null
              : 'download',
        ),
      );
    }
  }

  void cancelDownload() => _service.cancelDownload();

  Future<void> remove() async {
    if (state.valueOrNull?.downloading ?? false) return;
    await _service.remove();
    state = AsyncData(await _service.inspect());
  }
}
