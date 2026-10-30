// lib/features/permintaan_driver/screens/permintaan_driver_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../data/models/user_model.dart';
import '../../../../config.dart';
import '../widgets/spk_search_sheet.dart';

class PermintaanDriverScreen extends StatefulWidget {
  final User user;
  const PermintaanDriverScreen({super.key, required this.user});

  @override
  State<PermintaanDriverScreen> createState() => _PermintaanDriverScreenState();
}

enum HariKerja { hariIni, besok }

/// Satu baris "Barang/Dokumen yang dibawa".
class _DetailItem {
  String spk = '';
  String spkNama = ''; // hanya untuk tampilan
  final TextEditingController ketController = TextEditingController();
  final TextEditingController penerimaController = TextEditingController();

  bool get isKosong =>
      spk.isEmpty &&
      ketController.text.trim().isEmpty &&
      penerimaController.text.trim().isEmpty;

  void dispose() {
    ketController.dispose();
    penerimaController.dispose();
  }
}

class _PermintaanDriverScreenState extends State<PermintaanDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true; // memuat waktu server
  bool _isSaving = false; // proses simpan
  String? _loadError;

  final _tipeJadwalController = TextEditingController();
  final _customerController = TextEditingController();
  final _pengambilanController = TextEditingController();
  final _picController = TextEditingController();
  final _uraianController = TextEditingController();

  final List<_DetailItem> _items = [_DetailItem()];

  DateTime _tanggalPermintaan = DateTime.now();
  TimeOfDay _waktuPermintaan = TimeOfDay.now();
  String? _tipeJadwal;
  TimeOfDay _jamKerja = const TimeOfDay(hour: 8, minute: 0);
  String? _status;
  HariKerja _hariKerja = HariKerja.hariIni;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  @override
  void dispose() {
    _tipeJadwalController.dispose();
    _customerController.dispose();
    _pengambilanController.dispose();
    _picController.dispose();
    _uraianController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  void _updateTipeJadwal() {
    String newTipeJadwal;

    if (_hariKerja == HariKerja.besok) {
      newTipeJadwal = 'Terjadwal';
    } else {
      final jam = _waktuPermintaan.hour;
      final menit = _waktuPermintaan.minute;

      if (jam > 13 || (jam == 13 && menit >= 30)) {
        newTipeJadwal = 'Keterlaluan';
      } else if (jam >= 10) {
        newTipeJadwal = 'Tidak Terjadwal';
      } else {
        newTipeJadwal = 'Terjadwal';
      }
    }

    setState(() {
      _tipeJadwal = newTipeJadwal;
      _tipeJadwalController.text = newTipeJadwal;
    });
  }

  Future<void> _fetchInitialData() async {
    try {
      final response = await http
          .get(Uri.parse('${Config.baseUrl}/permintaan/form-data'))
          .timeout(const Duration(seconds: 15));
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final serverDateTime = DateTime.parse(data['server_time']).toLocal();
        if (!mounted) return;
        setState(() {
          _tanggalPermintaan = serverDateTime;
          _waktuPermintaan = TimeOfDay.fromDateTime(serverDateTime);
          _isLoading = false;
          _loadError = null;
        });
        _updateTipeJadwal();
        return;
      }
      throw Exception(data['message'] ?? 'Gagal memuat form.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Gagal memuat form. Periksa koneksi Anda.';
      });
    }
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    _fetchInitialData();
  }

  // ---------- Detail (Barang/Dokumen yang dibawa) ----------

  void _addItem() => setState(() => _items.add(_DetailItem()));

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    final item = _items.removeAt(index);
    setState(() {});
    // Controller baru boleh dibuang setelah frame selesai
    WidgetsBinding.instance.addPostFrameCallback((_) => item.dispose());
  }

  Future<void> _pilihSpk(_DetailItem item) async {
    final hasil = await showSpkSearchSheet(context);
    if (hasil == null || !mounted) return;
    setState(() {
      item.spk = hasil['Nomor']?.toString() ?? '';
      item.spkNama = hasil['Nama']?.toString() ?? '';
    });
  }

  // ---------- Simpan ----------

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    DateTime tglKerja = _tanggalPermintaan;
    if (_hariKerja == HariKerja.besok) {
      tglKerja = tglKerja.add(const Duration(days: 1));
    }

    final items = _items
        .where((i) => !i.isKosong)
        .map((i) => {
              'spk': i.spk,
              'keterangan': i.ketController.text.trim(),
              'penerima': i.penerimaController.text.trim(),
            })
        .toList();

    final Map<String, dynamic> formData = {
      // Nomor dibuat oleh server saat simpan
      'pd_tanggal': DateFormat('yyyy-MM-dd').format(_tanggalPermintaan),
      'pd_tipejadwal': _tipeJadwal,
      'pd_pengambilan': _pengambilanController.text,
      'pd_customer': _customerController.text,
      'pd_pic': _picController.text,
      'pd_uraian': _uraianController.text,
      'pd_jamkerja':
          '${_jamKerja.hour.toString().padLeft(2, '0')}:${_jamKerja.minute.toString().padLeft(2, '0')}:00',
      'pd_status': _status,
      'pd_jamminta':
          '${_waktuPermintaan.hour.toString().padLeft(2, '0')}:${_waktuPermintaan.minute.toString().padLeft(2, '0')}:00',
      'pd_userpeminta': widget.user.nama,
      'pd_tglkerja': DateFormat('yyyy-MM-dd').format(tglKerja),
      'items': items,
    };

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final response = await http
          .post(
            Uri.parse('${Config.baseUrl}/permintaan'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(formData),
          )
          .timeout(const Duration(seconds: 20));
      final data = json.decode(response.body);

      if (!mounted) return;

      if (data['success'] == true) {
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content:
                Text('Permintaan ${data['nomor'] ?? ''} berhasil disimpan!'),
          ),
        );
      } else {
        _showSnackbar(data['message'] ?? 'Gagal menyimpan permintaan',
            isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Tidak dapat terhubung. Periksa koneksi Anda.',
          isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input Permintaan Driver')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _retry,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('Nomor: otomatis saat disimpan'),
          const SizedBox(height: 16),
          Text(
              'Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(_tanggalPermintaan)}'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _tipeJadwalController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Tipe Jadwal',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.08),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _customerController,
            decoration: const InputDecoration(
                labelText: 'Customer', border: OutlineInputBorder()),
            validator: (value) =>
                value!.isEmpty ? 'Customer tidak boleh kosong' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pengambilanController,
            decoration: const InputDecoration(
                labelText: 'Pengambilan', border: OutlineInputBorder()),
            validator: (value) =>
                value!.isEmpty ? 'Pengambilan tidak boleh kosong' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _picController,
            decoration: const InputDecoration(
                labelText: 'PIC', border: OutlineInputBorder()),
            validator: (value) =>
                value!.isEmpty ? 'PIC tidak boleh kosong' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _uraianController,
            decoration: const InputDecoration(
                labelText: 'Uraian', border: OutlineInputBorder()),
            maxLines: 3,
            validator: (value) =>
                value!.isEmpty ? 'Uraian tidak boleh kosong' : null,
          ),
          const SizedBox(height: 16),
          const Text('Jam Kerja'),
          Row(
            children: [
              Expanded(child: Text(_jamKerja.format(context))),
              IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: () async {
                  final pickedTime = await showTimePicker(
                      context: context, initialTime: _jamKerja);
                  if (pickedTime != null) {
                    setState(() => _jamKerja = pickedTime);
                  }
                },
              ),
              Radio<HariKerja>(
                  value: HariKerja.hariIni,
                  groupValue: _hariKerja,
                  onChanged: (v) => setState(() {
                        _hariKerja = v!;
                        _updateTipeJadwal();
                      })),
              const Text('Hari Ini'),
              Radio<HariKerja>(
                  value: HariKerja.besok,
                  groupValue: _hariKerja,
                  onChanged: (v) => setState(() {
                        _hariKerja = v!;
                        _updateTipeJadwal();
                      })),
              const Text('Besok'),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(
                labelText: 'Status', border: OutlineInputBorder()),
            items: ['Top Urgent', 'Urgent', 'Tidak'].map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (value) => setState(() => _status = value),
            validator: (value) => value == null ? 'Pilih status' : null,
          ),

          // ----- Barang/Dokumen yang dibawa -----
          const SizedBox(height: 24),
          Text(
            'Barang/Dokumen yang dibawa',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < _items.length; i++) _buildItemCard(i, _items[i]),
          OutlinedButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
            label: const Text('Tambah Barang/Dokumen'),
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : _submitForm,
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(int index, _DetailItem item) {
    final hasSpk = item.spk.isNotEmpty;

    return Card(
      key: ObjectKey(item), // menjaga isi field saat ada baris yang dihapus
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Item ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Hapus item',
                  icon: const Icon(Icons.delete_outline),
                  onPressed:
                      _items.length > 1 ? () => _removeItem(index) : null,
                ),
              ],
            ),
            InkWell(
              onTap: () => _pilihSpk(item),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'SPK / Memo / SO (opsional)',
                  border: const OutlineInputBorder(),
                  suffixIcon: hasSpk
                      ? IconButton(
                          tooltip: 'Hapus SPK',
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() {
                            item.spk = '';
                            item.spkNama = '';
                          }),
                        )
                      : const Icon(Icons.search),
                ),
                child: hasSpk
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.spk,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (item.spkNama.isNotEmpty)
                            Text(
                              item.spkNama,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      )
                    : Text(
                        'Ketuk untuk cari SPK',
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: item.ketController,
              decoration: const InputDecoration(
                  labelText: 'Keterangan', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: item.penerimaController,
              decoration: const InputDecoration(
                  labelText: 'Penerima (opsional)',
                  border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
    );
  }
}
