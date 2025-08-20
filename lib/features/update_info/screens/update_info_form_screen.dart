// lib/features/update_info/screens/update_info_form_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import '../../../data/models/user_model.dart';
import '../../../data/models/open_job_model.dart'; // <-- Gunakan model baru
import '../../../../config.dart';

class UpdateInfoFormScreen extends StatefulWidget {
  final User user;
  final OpenJob job; // <-- Menerima job yang dipilih

  const UpdateInfoFormScreen({
    super.key,
    required this.user,
    required this.job,
  });

  @override
  State<UpdateInfoFormScreen> createState() => _UpdateInfoFormScreenState();
}

class _UpdateInfoFormScreenState extends State<UpdateInfoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Form Controllers
  final _customerController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  final List<String> _statusOptions = [
    'Terjadwal',
    'Tidak Terjadwal',
    'Keterlaluan'
  ];
  String? _selectedStatus;

  // Data
  File? _imageFile;
  XFile? _webImageFile;

  @override
  void initState() {
    super.initState();
    // --- MENGISI DATA OTOMATIS SAAT LAYAR DIBUKA ---
    _customerController.text = widget.job.customer;
    // Memastikan status dari DB ada di dalam list, jika tidak, set null
    if (_statusOptions.contains(widget.job.status)) {
      _selectedStatus = widget.job.status;
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  // ... (fungsi _pickImage dan _getCurrentLocation tidak berubah, jadi saya salin saja)
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        if (kIsWeb) {
          _webImageFile = pickedFile;
        } else {
          _imageFile = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied)
        return Future.error('Location permissions are denied');
    }
    if (permission == LocationPermission.deniedForever)
      return Future.error('Location permissions are permanently denied.');
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _latitudeController.text = position.latitude.toString();
      _longitudeController.text = position.longitude.toString();
    });
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null && _webImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan ambil foto terlebih dahulu.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      var uri = Uri.parse('${Config.baseUrl}/kegiatan/detail');
      var request = http.MultipartRequest('POST', uri);

      request.fields['header_id'] = widget.job.id.toString();
      request.fields['customer'] = _customerController.text;
      request.fields['latitude'] = _latitudeController.text;
      request.fields['longitude'] = _longitudeController.text;
      request.fields['status'] = _selectedStatus!;

      if (!kIsWeb && _imageFile != null) {
        request.files
            .add(await http.MultipartFile.fromPath('foto', _imageFile!.path));
      } else if (kIsWeb && _webImageFile != null) {
        final bytes = await _webImageFile!.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('foto', bytes,
            filename: _webImageFile!.name));
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        if (mounted && data['success'] == true) {
          // Kembali 2 kali untuk menutup layar form dan layar list
          Navigator.of(context).pop(true); // Kirim 'true' untuk refresh list

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Update info berhasil!')),
          );
        }
      } else {
        print('Upload failed: $responseBody');
      }
    } catch (e) {
      print('Error upload: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Info')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- BAGIAN INFO HEADER ---
            _buildHeaderInfo('Nama', widget.user.nama),
            _buildHeaderInfo(
                'No Plat', widget.job.noplat), // <-- Mengambil dari job
            _buildHeaderInfo('Tujuan', widget.job.tujuan),
            const SizedBox(height: 24),

            // --- BAGIAN FORM INPUT ---
            // Dropdown Status
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              hint: const Text('Pilih Status'),
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: _statusOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedStatus = newValue;
                });
              },
              validator: (value) =>
                  value == null ? 'Status harus dipilih' : null,
            ),
            const SizedBox(height: 16),

            // Customer (Read Only)
            TextFormField(
              controller: _customerController,
              readOnly: true, // <-- Dibuat read-only
              decoration: const InputDecoration(
                  labelText: 'Customer', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            // Location
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latitudeController,
                    decoration: const InputDecoration(
                        labelText: 'Latitude', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _longitudeController,
                    decoration: const InputDecoration(
                        labelText: 'Longitude', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.location_searching),
                    onPressed: _getCurrentLocation),
              ],
            ),
            const SizedBox(height: 16),

            // Image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: (_imageFile != null || _webImageFile != null)
                  ? (kIsWeb
                      ? Image.network(_webImageFile!.path, fit: BoxFit.cover)
                      : Image.file(_imageFile!, fit: BoxFit.cover))
                  : const Center(child: Text('Belum ada gambar')),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () => _pickImage(ImageSource.camera),
                    tooltip: 'Ambil Foto'),
                IconButton(
                    icon: const Icon(Icons.photo_library),
                    onPressed: () => _pickImage(ImageSource.gallery),
                    tooltip: 'Pilih dari Galeri'),
              ],
            ),
            const SizedBox(height: 24),

            // --- BAGIAN TOMBOL ---
            ElevatedButton(
              onPressed: _isSaving ? null : _submitUpdate,
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Update Info'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }

  // Widget helper untuk menampilkan info di header
  Widget _buildHeaderInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Text(': '),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
