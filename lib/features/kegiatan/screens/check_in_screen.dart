// lib/features/kegiatan/screens/check_in_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../data/models/user_model.dart';
import 'select_job_screen.dart';
import '../../../data/models/selectable_job_model.dart';
import 'select_kendaraan_screen.dart';
import 'select_driver_screen.dart'; 
import '../../../data/models/selectable_driver_model.dart'; 
import '../../../../config.dart'; 

class CheckInScreen extends StatefulWidget {
  final User user;
  const CheckInScreen({super.key, required this.user});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Controllers
  final _noplatController = TextEditingController(); 
  final _nomorPermintaanController = TextEditingController();
  final _customerController = TextEditingController();
  final _uraianController = TextEditingController();
  final _statusController = TextEditingController();
  final _driverController = TextEditingController(); 

  // State
  String? _selectedJadwal;
  SelectableDriver? _selectedDriver; 

  @override
  void initState() {
    super.initState();
    // Jika bukan leader, langsung isi dengan nama sendiri
    if (widget.user.kode != '001') {
      _driverController.text = widget.user.nama;
    }
  }

  @override
  void dispose() {
    _noplatController.dispose();
    _nomorPermintaanController.dispose();
    _customerController.dispose();
    _uraianController.dispose();
    _statusController.dispose();
    _driverController.dispose(); // <-- Jangan lupa dispose
    super.dispose();
  }

  Future<void> _searchAndSelectKendaraan() async {
    final selectedNoplat = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const SelectKendaraanScreen()),
    );
    if (selectedNoplat != null) {
      setState(() => _noplatController.text = selectedNoplat);
    }
  }

  Future<void> _searchAndSelectJob() async {
    final selectedJob = await Navigator.push<SelectableJob>(
      context,
      MaterialPageRoute(builder: (context) => const SelectJobScreen()),
    );
    if (selectedJob != null) {
      setState(() {
        _nomorPermintaanController.text = selectedJob.nomor;
        _customerController.text = selectedJob.customer;
        _uraianController.text = selectedJob.uraian;
        _statusController.text = selectedJob.tipeJadwal;
        _selectedJadwal = selectedJob.tipeJadwal;
      });
    }
  }

  // [BARU] Fungsi untuk memilih driver
  Future<void> _searchAndSelectDriver() async {
    final driver = await Navigator.push<SelectableDriver>(
      context,
      MaterialPageRoute(builder: (context) => const SelectDriverScreen()),
    );
    if (driver != null) {
      setState(() {
        _selectedDriver = driver;
        _driverController.text = driver.nama;
      });
    }
  }

  Future<void> _submitCheckIn() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedJadwal == null || _selectedJadwal!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih nomor permintaan terlebih dahulu.'))
        );
        return;
    }

    setState(() => _isSaving = true);

    // [PERBAIKAN] Tentukan kode driver yang akan dikirim
    final driverKode = _selectedDriver?.kode ?? widget.user.kode;

    final Map<String, dynamic> formData = {
      'kar_kode': driverKode,
      'noplat': _noplatController.text,
      'tujuan': '${_customerController.text} => ${_uraianController.text}',
      'isplan': _selectedJadwal == 'Terjadwal' ? 0 : 1,
      'nomor_minta': _nomorPermintaanController.text,
    };

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/kegiatan/checkin'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(formData),
      );
      final data = json.decode(response.body);
      if (mounted) {
        if (data['success'] == true) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Check In berhasil!')),
          );
        }
      }
    } catch (e) { /* Handle error */ } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tentukan apakah user adalah leader
    final bool isLeader = widget.user.kode == '001';

    return Scaffold(
      appBar: AppBar(title: const Text('Input Kegiatan (Check In)')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // [BARU] Tampilkan pilihan driver hanya untuk leader
            if (isLeader) ...[
              TextFormField(
                controller: _driverController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Check In Untuk Driver',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _searchAndSelectDriver,
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Pilih Driver' : null,
              ),
              const SizedBox(height: 16),
            ] else ... [
              // Tampilkan info driver jika bukan leader
              _buildInfoText('Kode', widget.user.kode),
              _buildInfoText('Nama', widget.user.nama),
              const Divider(height: 24),
            ],
            
            TextFormField(
              controller: _noplatController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'No Plat',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchAndSelectKendaraan,
                ),
              ),
              validator: (value) => value!.isEmpty ? 'Pilih No Plat' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nomorPermintaanController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'No Permintaan',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchAndSelectJob,
                ),
              ),
              validator: (value) => value!.isEmpty ? 'Pilih No Permintaan' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customerController,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Customer', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _uraianController,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Uraian', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _statusController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Status',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _submitCheckIn,
              child: _isSaving ? const CircularProgressIndicator() : const Text('Check In'),
            ),
          ],
        ),
      ),
    );
  }

  // Widget helper untuk info text
  Widget _buildInfoText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyLarge,
          children: [
            TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
