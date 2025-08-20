// lib/data/models/history_job_model.dart

class HistoryJob {
  final int id;
  final String tujuan;
  final String tanggal;
  final String jam;
  final String keterangan;

  HistoryJob({
    required this.id,
    required this.tujuan,
    required this.tanggal,
    required this.jam,
    required this.keterangan,
  });

  factory HistoryJob.fromJson(Map<String, dynamic> json) {
    return HistoryJob(
      id: int.tryParse(json['id'].toString()) ?? 0,
      tanggal: json['tanggal'] ?? '',
      tujuan: json['tujuan'] ?? '',
      jam: json['jam'] ?? '',
      keterangan: json['ket'] ?? '',
    );
  }
}
