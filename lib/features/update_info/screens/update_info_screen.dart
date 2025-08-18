// lib/features/update_info/screens/update_info_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import '../../../data/models/user_model.dart';
import '../../../../config.dart';

class UpdateInfoScreen extends StatefulWidget {
  final User user;
  final int kegiatanId;

  const UpdateInfoScreen(
      {super.key, required this.user, required this.kegiatanId});

  @override
  State<UpdateInfoScreen> createState() => _UpdateInfoScreenState();
}

class _UpdateInfoScreenState extends State<UpdateInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  // Form Controllers
  final _customerController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  // Data
  String _noplat = '';
  String _tujuan = '';
  File? _imageFile;
  XFile? _webImageFile;

  @override
  void initState() {
    super.initState();
    _fetchKegiatanInfo();
  }

  Future<void> _fetchKegiatanInfo() async {
    try {
      // [PERUBAHAN] URL diubah untuk menunjuk ke endpoint Express.js
      final response = await http.get(
          Uri.parse('${Config.baseUrl}/kegiatan/${widget.kegiatanId}/info'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _noplat = data['data']['noplat'];
            _tujuan = data['data']['tujuan'];
            _customerController.text = data['data']['pd_customer'] ?? '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {/* Handle error */}
  }

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
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

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
      request.fields['header_id'] = widget.kegiatanId.toString();
      request.fields['customer'] = _customerController.text;
      request.fields['latitude'] = _latitudeController.text;
      request.fields['longitude'] = _longitudeController.text;

      // attach file
      if (!kIsWeb && _imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'foto', // sesuai field di backend
          _imageFile!.path,
        ));
      } else if (kIsWeb && _webImageFile != null) {
        final bytes = await _webImageFile!.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'foto',
          bytes,
          filename: _webImageFile!.name,
        ));
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        if (mounted && data['success'] == true) {
          Navigator.of(context).pop();
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
      appBar: AppBar(title: const Text('Update Info Kegiatan')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Text('Nama: ${widget.user.nama}'),
                  Text('No Plat: $_noplat'),
                  Text('Tujuan: $_tujuan'),
                  const Divider(height: 24),
                  TextFormField(
                    controller: _customerController,
                    decoration: const InputDecoration(
                        labelText: 'Customer', border: OutlineInputBorder()),
                    validator: (v) =>
                        v!.isEmpty ? 'Customer tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latitudeController,
                          decoration: const InputDecoration(
                              labelText: 'Latitude',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _longitudeController,
                          decoration: const InputDecoration(
                              labelText: 'Longitude',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      IconButton(
                          icon: const Icon(Icons.location_searching),
                          onPressed: _getCurrentLocation),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: (_imageFile != null || _webImageFile != null)
                        ? (kIsWeb
                            ? Image.network(_webImageFile!.path,
                                fit: BoxFit.cover)
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
                  ElevatedButton(
                    onPressed: _isSaving ? null : _submitUpdate,
                    child: _isSaving
                        ? const CircularProgressIndicator()
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
}
