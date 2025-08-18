// lib/data/models/monitoring_model.dart

class MonitoringData {
  final String namaKaryawan;
  final String keterangan;

  MonitoringData({
    required this.namaKaryawan,
    required this.keterangan,
  });

  factory MonitoringData.fromJson(Map<String, dynamic> json) {
    return MonitoringData(
      namaKaryawan: json['kar_nama'] ?? '',
      keterangan: json['keterangan'] ?? 'Status tidak diketahui',
    );
  }
}
