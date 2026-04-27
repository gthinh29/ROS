class AppConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost',
  );
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'ws://localhost/ws',
  );
}
