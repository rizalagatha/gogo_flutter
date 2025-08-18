// File: lib/data/models/kegiatan_subdetail_model.dart

class KegiatanSubDetail {
  final int id;
  final String customer;
  final String jam;

  KegiatanSubDetail({
    required this.id,
    required this.customer,
    required this.jam,
  });

  factory KegiatanSubDetail.fromJson(Map<String, dynamic> json) {
    return KegiatanSubDetail(
      id: json['id'] ?? 0,
      customer: json['customer'] ?? '',
      jam: json['jam'] ?? '',
    );
  }
}