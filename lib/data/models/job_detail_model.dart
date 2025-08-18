// lib/data/models/job_detail_model.dart

class JobDetail {
  final String nomor;
  final int noUrut;
  final String spk;
  final String keterangan;
  final String? penerima;

  JobDetail({
    required this.nomor,
    required this.noUrut,
    required this.spk,
    required this.keterangan,
    this.penerima,
  });

  factory JobDetail.fromJson(Map<String, dynamic> json) {
    return JobDetail(
      nomor: json['pdd_nomor'] ?? '',
      noUrut: int.tryParse(json['pdd_nourut'].toString()) ?? 0,
      spk: json['pdd_spk'] ?? '',
      keterangan: json['pdd_ket'] ?? '',
      penerima: json['pdd_penerima'],
    );
  }
}
