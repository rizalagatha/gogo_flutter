// lib/data/models/daftar_job_model.dart

class DaftarJob {
  final String nomor;
  final String customer;
  final String tipeJadwal;
  final String uraian;
  final String jamKerja;
  final String userPeminta;
  final String status;
  final String? driver;
  final String tglKerja;
  final String? pengambilan;
  final String? pic;

  DaftarJob({
    required this.nomor,
    required this.customer,
    required this.tipeJadwal,
    required this.uraian,
    required this.jamKerja,
    required this.userPeminta,
    required this.status,
    this.driver,
    required this.tglKerja,
    this.pengambilan,
    this.pic,
  });

  factory DaftarJob.fromJson(Map<String, dynamic> json) {
    return DaftarJob(
      nomor: json['pd_nomor'] ?? '',
      customer: json['pd_customer'] ?? '',
      tipeJadwal: json['pd_tipejadwal'] ?? '',
      uraian: json['pd_uraian'] ?? '',
      jamKerja: json['pd_jamkerja'] ?? '',
      userPeminta: json['pd_userpeminta'] ?? '',
      status: json['status'] ?? '',
      driver: json['pd_driver'],
      tglKerja: json['pd_tglKerja'] ?? '',
      pengambilan: json['pd_pengambilan'],
      pic: json['pd_pic'],
    );
  }
}
