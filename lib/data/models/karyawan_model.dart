// lib/data/models/karyawan_model.dart

class Karyawan {
  final String kode;
  final String nama;

  Karyawan({required this.kode, required this.nama});

  factory Karyawan.fromJson(Map<String, dynamic> json) {
    return Karyawan(
      kode: json['kar_kode'] ?? '',
      nama: json['kar_nama'] ?? '',
    );
  }
}