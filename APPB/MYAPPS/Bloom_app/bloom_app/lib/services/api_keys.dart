// API keys — embedded at compile time via --dart-define.
// Never stored in plaintext files committed to git.
const String groqApiKey = String.fromEnvironment(
  'GROQ_API_KEY',
  defaultValue: '',
);
