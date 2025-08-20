// File: models/visit_detail.dart

class VisitDetail {
  final int id;
  final String customerName;
  final double latitude;
  final double longitude;

  VisitDetail({
    required this.id,
    required this.customerName,
    required this.latitude,
    required this.longitude,
  });

  factory VisitDetail.fromJson(Map<String, dynamic> json) {
    return VisitDetail(
      id: json['id'],
      customerName: json['customer'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}
