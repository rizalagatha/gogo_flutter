// lib/data/models/open_job_model.dart

class OpenJob {
  final int id;
  final int? detailId; // <-- DIUBAH kembali ke int agar cocok dengan tkegiatan.id
  final String tujuan;
  final String customer;
  final String status;
  final String noplat;
  final String tglKerja; // <-- DITAMBAHKAN
  final String jamKerja; // <-- DITAMBAHKAN

  OpenJob({
    required this.id,
    this.detailId, 
    required this.tujuan,
    required this.customer,
    required this.status,
    required this.noplat,
    required this.tglKerja,
    required this.jamKerja,
  });

  factory OpenJob.fromJson(Map<String, dynamic> json) {
    return OpenJob(
      id: json['id'] ?? 0, // <-- Menerima int
      detailId: json['id'] != null ? int.parse(json['id'].toString()) : null,
      tujuan: json['tujuan'] ?? 'Tanpa Tujuan',
      customer: json['customer'] ?? '',
      status: json['status'] ?? 'Terjadwal',
      noplat: json['noplat'] ?? '-',
      tglKerja: json['tglKerja'] ?? '-', // <-- DITAMBAHKAN
      jamKerja: json['jamKerja'] ?? '-', // <-- DITAMBAHKAN
    );
  }
}
