// lib/data/models/checkout_job_model.dart

class CheckoutJob {
  final String nomor;
  final String tipeJadwal;
  final String uraian;
  final String jamKerja;
  final String userPeminta;
  final String tglKerja;

  CheckoutJob({
    required this.nomor,
    required this.tipeJadwal,
    required this.uraian,
    required this.jamKerja,
    required this.userPeminta,
    required this.tglKerja,
  });

  factory CheckoutJob.fromJson(Map<String, dynamic> json) {
    return CheckoutJob(
      nomor: json['pd_nomor'] ?? '',
      tipeJadwal: json['pd_tipejadwal'] ?? '',
      uraian: json['uraian'] ?? '',
      jamKerja: json['pd_jamkerja'] ?? '',
      userPeminta: json['pd_userpeminta'] ?? '',
      tglKerja: json['pd_tglKerja'] ?? '',
    );
  }
}
