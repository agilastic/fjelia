/// Public service address, shared by requests and data-sharing descriptions.
const freeAiHost = 'ai.fjelia.com';
const freeAiInstallationIdStorageKey = 'free_ai_installation_id_v1';

const freeAiMaxAttempts = 3;
const freeAiRequestTimeout = Duration(seconds: 35);
// Includes all three attempts, retry pauses and response processing.
const freeAiGenerationTimeout = Duration(minutes: 2);

final freeAiChatCompletionsUri = Uri.https(
  freeAiHost,
  '/llm/v1/chat/completions',
);
