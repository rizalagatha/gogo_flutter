class Config {
  // Ambil dari --dart-define, kalau gak ada pakai default (misal localhost)
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://45.127.134.179:4000/api',
  );
}
