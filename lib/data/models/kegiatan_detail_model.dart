class KegiatanDetail {
  final int id;
  final String nomorMinta;
  final String noplat;
  final String tujuan;
  final String status;
  final String? keterangan;
  final String namaDriver;
  final String? pdNomor;
  final String? pdTanggal;
  final String? pdCustomer;
  final String? pdUraian;
  final String? pdTipejadwal;
  final String? pdStatus;
  final String? pdJamminta;
  final String? pdUserpeminta;
  final String? pdDriver;
  final String? pdTglkerja;
  final String? pdPenerima;
  final String? pdPengambilan;
  final String? pdPic;

  KegiatanDetail({
    required this.id,
    required this.nomorMinta,
    required this.noplat,
    required this.tujuan,
    required this.status,
    required this.keterangan,
    required this.namaDriver,
    this.pdNomor,
    this.pdTanggal,
    this.pdCustomer,
    this.pdUraian,
    this.pdTipejadwal,
    this.pdStatus,
    this.pdJamminta,
    this.pdUserpeminta,
    this.pdDriver,
    this.pdTglkerja,
    this.pdPenerima,
    this.pdPengambilan,
    this.pdPic,
  });

  factory KegiatanDetail.fromJson(Map<String, dynamic> json) {
    return KegiatanDetail(
      id: json['id'],
      nomorMinta: json['nomor_minta'],
      noplat: json['noplat'],
      tujuan: json['tujuan'],
      status: json['status'],
      keterangan: json['keterangan'],
      namaDriver: json['namaDriver'],
      pdNomor: json['pd_nomor'],
      pdTanggal: json['pd_tanggal'],
      pdCustomer: json['pd_customer'],
      pdUraian: json['pd_uraian'],
      pdTipejadwal: json['pd_tipejadwal'],
      pdStatus: json['pd_status'],
      pdJamminta: json['pd_jamminta'],
      pdUserpeminta: json['pd_userpeminta'],
      pdDriver: json['pd_driver'],
      pdTglkerja: json['pd_tglkerja'],
      pdPenerima: json['pd_penerima'],
      pdPengambilan: json['pd_pengambilan'],
      pdPic: json['pd_pic'],
    );
  }
}
