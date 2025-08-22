// lib/data/models/selectable_driver_model.dart

class SelectableDriver {
  final String kode;
  final String nama;

  SelectableDriver({
    required this.kode,
    required this.nama,
  });

  factory SelectableDriver.fromJson(Map<String, dynamic> json) {
    return SelectableDriver(
      kode: json['kar_kode'] ?? '',
      nama: json['kar_nama'] ?? 'Tanpa Nama',
    );
  }
}
