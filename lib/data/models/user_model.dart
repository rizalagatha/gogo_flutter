// lib/data/models/user_model.dart

class User {
  final String kode;
  final String nama;
  final bool isDriver;

  User({required this.kode, required this.nama, required this.isDriver});

  factory User.fromJson(Map<String, dynamic> json) {
    final isDriverValue = json['kar_isdriver'];
    final isDriverBool = isDriverValue.toString() == '1';

    return User(
      kode: json['kar_kode'] ?? '',
      nama: json['kar_nama'] ?? '',
      isDriver: isDriverBool,
    );
  }
}