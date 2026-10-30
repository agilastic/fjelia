const localQwenModelId = 'mlx-community/Qwen3.5-2B-MLX-4bit';
const localQwenRevision = '93760be4f1f69842a46bc13dbdc0f19e291392a3';

class LocalModelFile {
  const LocalModelFile(this.name, this.bytes, [this.sha256Hex]);
  final String name;
  final int bytes;
  final String? sha256Hex;
}

/// A pinned snapshot: an interrupted or changed download cannot be activated.
const localQwenFiles = [
  LocalModelFile('config.json', 3113),
  LocalModelFile('chat_template.jinja', 7755),
  LocalModelFile('tokenizer_config.json', 1139),
  LocalModelFile(
    'tokenizer.json',
    19989343,
    '87a7830d63fcf43bf241c3c5242e96e62dd3fdc29224ca26fed8ea333db72de4',
  ),
  LocalModelFile('vocab.json', 6722759),
  LocalModelFile('model.safetensors.index.json', 81722),
  LocalModelFile('preprocessor_config.json', 390),
  LocalModelFile('processor_config.json', 1300),
  LocalModelFile('video_preprocessor_config.json', 385),
  LocalModelFile(
    'model.safetensors',
    1722271785,
    '713fe7e5d3c3965f7106b0d0ee17615f7869c23c8d327996df8c1196fbcf07d5',
  ),
];

/// One optional, pinned model with its own installation directory.
class LocalModelSpec {
  const LocalModelSpec({
    required this.id,
    required this.revision,
    required this.label,
    required this.directoryName,
    required this.minimumMemoryBytes,
    required this.files,
    this.requiresIPhone18 = false,
  });

  final String id, revision, label, directoryName;
  final int minimumMemoryBytes;
  final bool requiresIPhone18;
  final List<LocalModelFile> files;
  int get totalBytes => files.fold(0, (total, file) => total + file.bytes);
  int get minimumMemoryGb => (minimumMemoryBytes / 1e9).ceil();
}

const localQwen4bModelId = 'mlx-community/Qwen3.5-4B-MLX-4bit';
const localQwen4bRevision = '32f3e8ecf65426fc3306969496342d504bfa13f3';
const localQwen4bFiles = [
  LocalModelFile('chat_template.jinja', 7756),
  LocalModelFile('config.json', 3366),
  LocalModelFile(
    'model.safetensors',
    3034300695,
    '5fb9acd0246866381cf8c5c354c6db1019f6498eec4ccb4f5edcc71ffeacb2db',
  ),
  LocalModelFile('model.safetensors.index.json', 101944),
  LocalModelFile('preprocessor_config.json', 390),
  LocalModelFile('processor_config.json', 1300),
  LocalModelFile(
    'tokenizer.json',
    19989343,
    '87a7830d63fcf43bf241c3c5242e96e62dd3fdc29224ca26fed8ea333db72de4',
  ),
  LocalModelFile('tokenizer_config.json', 1139),
  LocalModelFile('video_preprocessor_config.json', 385),
  LocalModelFile('vocab.json', 6722759),
];

const localQwen2b = LocalModelSpec(
  id: localQwenModelId,
  revision: localQwenRevision,
  label: 'Qwen3.5-2B',
  directoryName: 'qwen35_2b_mlx4',
  minimumMemoryBytes: 3500000000,
  files: localQwenFiles,
);
const localQwen4b = LocalModelSpec(
  id: localQwen4bModelId,
  revision: localQwen4bRevision,
  label: 'Qwen3.5-4B',
  directoryName: 'qwen35_4b_mlx4',
  minimumMemoryBytes: 7500000000,
  requiresIPhone18: true,
  files: localQwen4bFiles,
);
const localQwenModels = [localQwen2b, localQwen4b];

LocalModelSpec localModelSpec(String modelId) => localQwenModels.firstWhere(
  (model) => model.id == modelId,
  orElse: () => throw ArgumentError.value(modelId, 'modelId'),
);
