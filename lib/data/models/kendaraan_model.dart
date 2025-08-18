// lib/data/models/kendaraan_model.dart

class Kendaraan {
  final String noplat;
  final String keterangan;

  Kendaraan({
    required this.noplat,
    required this.keterangan,
  });

  factory Kendaraan.fromJson(Map<String, dynamic> json) {
    return Kendaraan(
      noplat: json['noplat'] ?? '',
      keterangan: json['keterangan'] ?? '',
    );
  }
}
