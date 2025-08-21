// lib/data/models/selectable_job_model.dart

class SelectableJob {
  final String nomor;
  final String peminta;
  final String? pengambilan;
  final String? pic;
  final String customer;
  final String uraian;
  final String tipeJadwal;
  final String tglKerja;
  final String jamKerja;
  final String status;
  final String? driver;

  SelectableJob({
    required this.nomor,
    required this.peminta,
    this.pengambilan,
    this.pic,
    required this.customer,
    required this.uraian,
    required this.tipeJadwal,
    required this.tglKerja,
    required this.jamKerja,
    required this.status,
    this.driver,
  });

  factory SelectableJob.fromJson(Map<String, dynamic> json) {
    return SelectableJob(
      nomor: json['pd_nomor'] ?? '',
      peminta: json['peminta'] ?? '-',
      pengambilan: json['pengambilan'],
      pic: json['pic'],
      customer: json['customer'] ?? '-',
      uraian: json['uraian'] ?? '-',
      tipeJadwal: json['tipeJadwal'] ?? '-',
      tglKerja: json['tglKerja'] ?? '-',
      jamKerja: json['jamKerja'] ?? '-',
      status: json['status'] ?? '-',
      driver: json['driver'],
    );
  }
}
