// lib/data/models/history_perawatan_model.dart

class HistoryPerawatan {
  final String tujuan;
  final String tanggal;
  final String bengkel;
  final int biaya;
  final int km;

  HistoryPerawatan({
    required this.tujuan,
    required this.tanggal,
    required this.bengkel,
    required this.biaya,
    required this.km,
  });

  factory HistoryPerawatan.fromJson(Map<String, dynamic> json) {
    return HistoryPerawatan(
      tujuan: json['tujuan'] ?? 'Lainnya',
      tanggal: json['tanggal'] ?? '-',
      bengkel: json['bengkel'] ?? '-',
      biaya: json['biaya'] ?? 0,
      km: json['KM'] ?? 0,
    );
  }
}