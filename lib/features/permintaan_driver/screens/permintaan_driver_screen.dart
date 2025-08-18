// lib/features/permintaan_driver/screens/permintaan_driver_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../data/models/user_model.dart';
import '../../../../config.dart'; 

class PermintaanDriverScreen extends StatefulWidget {
  final User user;
  const PermintaanDriverScreen({super.key, required this.user});

  @override
  State<PermintaanDriverScreen> createState() => _PermintaanDriverScreenState();
}

enum HariKerja { hariIni, besok }

class _PermintaanDriverScreenState extends State<PermintaanDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  final _tipeJadwalController = TextEditingController();
  final _customerController = TextEditingController();
  final _pengambilanController = TextEditingController();
  final _picController = TextEditingController();
  final _uraianController = TextEditingController();

  String _nomor = 'Loading...';
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
    super.dispose();
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
      final response =
          await http.get(Uri.parse('${Config.baseUrl}/permintaan/form-data'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final serverDateTime = DateTime.parse(data['server_time']).toLocal();
          setState(() {
            _nomor = data['new_kode'];
            _tanggalPermintaan = serverDateTime;
            _waktuPermintaan = TimeOfDay.fromDateTime(serverDateTime);
            _isLoading = false;
            _updateTipeJadwal();
          });
        }
      }
    } catch (e) {
      /* Handle error */
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    DateTime tglKerja = _tanggalPermintaan;
    if (_hariKerja == HariKerja.besok) {
      tglKerja = tglKerja.add(const Duration(days: 1));
    }

    final Map<String, dynamic> formData = {
      'pd_nomor': _nomor,
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
    };

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/permintaan'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(formData),
      );
      final data = json.decode(response.body);
      if (mounted) {
        if (data['success'] == true) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permintaan berhasil disimpan!')),
          );
        } else {
          /* Tampilkan error */
        }
      }
    } catch (e) {
      /* Tampilkan error */
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input Permintaan Driver')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Text('Nomor: $_nomor'),
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
                      fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
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
                        labelText: 'Pengambilan',
                        border: OutlineInputBorder()),
                    validator: (value) => value!.isEmpty
                        ? 'Pengambilan tidak boleh kosong'
                        : null,
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
                    items: ['Top Urgent', 'Urgent', 'Tidak']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                          value: value, child: Text(value));
                    }).toList(),
                    onChanged: (value) => setState(() => _status = value),
                    validator: (value) =>
                        value == null ? 'Pilih status' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    child: const Text('Save'),
                  )
                ],
              ),
            ),
    );
  }
}
