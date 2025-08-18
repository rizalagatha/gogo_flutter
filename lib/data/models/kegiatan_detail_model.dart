// File: lib/data/models/kegiatan_detail_model.dart

class KegiatanDetail {
  final String noplat;
  final String tujuan;
  final String status;
  final String? note;
  final String namaDriver;

  KegiatanDetail({
    required this.noplat,
    required this.tujuan,
    required this.status,
    this.note,
    required this.namaDriver,
  });

  factory KegiatanDetail.fromJson(Map<String, dynamic> json) {
    return KegiatanDetail(
      noplat: json['noplat'] ?? '',
      tujuan: json['tujuan'] ?? '',
      status: json['isplan'] ?? '',
      note: json['keterangan'],
      namaDriver: json['kar_nama'] ?? '',
    );
  }
}