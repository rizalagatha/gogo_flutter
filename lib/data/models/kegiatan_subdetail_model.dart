// lib/data/models/kegiatan_subdetail_model.dart

class KegiatanSubDetail {
  final int id;
  final String customer;
  final String jam;
  final double? latitude;
  final double? longitude;
  final String? fotoUrl;

  KegiatanSubDetail({
    required this.id,
    required this.customer,
    required this.jam,
    this.latitude,
    this.longitude,
    this.fotoUrl,
  });

  factory KegiatanSubDetail.fromJson(Map<String, dynamic> json) {
    // parsing latitude & longitude yang masih string
    double lat = 0.0;
    double lng = 0.0;
    if (json['latitude'] != null) {
      lat = double.tryParse(json['latitude'].toString()) ?? 0.0;
    }
    if (json['longitude'] != null) {
      lng = double.tryParse(json['longitude'].toString()) ?? 0.0;
    }

    return KegiatanSubDetail(
      id: json['id'] ?? 0,
      customer: json['customer'] ?? '',
      jam: json['jam'] ?? '',
      latitude: lat,
      longitude: lng,
      fotoUrl: json['foto']?.toString(),
    );
  }
}