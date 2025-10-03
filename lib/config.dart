class Config {
  // Ambil dari --dart-define, kalau gak ada pakai default (misal localhost)
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://103.94.238.252:4000/api',
  );
}
