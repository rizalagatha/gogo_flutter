// lib/data/models/history_perawatan_model.dart

class HistoryPerawatan {
  final int id;
  final String tujuan;
  final String keterangan;

  HistoryPerawatan({
    required this.id,
    required this.tujuan,
    required this.keterangan,
  });

  factory HistoryPerawatan.fromJson(Map<String, dynamic> json) {
    return HistoryPerawatan(
      id: int.tryParse(json['id'].toString()) ?? 0,
      tujuan: json['tujuan'] ?? '',
      keterangan: json['ket'] ?? '',
    );
  }
}
