// lib/data/models/selectable_job_model.dart

class SelectableJob {
  final String nomor;
  final String tipeJadwal;
  final String customer;
  final String uraian;

  SelectableJob({
    required this.nomor,
    required this.tipeJadwal,
    required this.customer,
    required this.uraian,
  });

  factory SelectableJob.fromJson(Map<String, dynamic> json) {
    return SelectableJob(
      nomor: json['pd_nomor'] ?? '',
      tipeJadwal: json['pd_tipejadwal'] ?? '',
      customer: json['pd_customer'] ?? '',
      uraian: json['pd_uraian'] ?? '',
    );
  }
}
