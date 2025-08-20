// lib/features/kegiatan/screens/check_out_form_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../data/models/user_model.dart';
import '../../../data/models/checkout_job_model.dart';
import '../widgets/check_out_form_loading.dart';
import '../../../../config.dart'; 

class CheckOutFormScreen extends StatefulWidget {
  final User user;
  final CheckoutJob job;

  const CheckOutFormScreen({super.key, required this.user, required this.job});

  @override
  State<CheckOutFormScreen> createState() => _CheckOutFormScreenState();
}

class _CheckOutFormScreenState extends State<CheckOutFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  // Form Data
  String _noplat = '';
  String _tujuan = '';
  String? _selectedStandby;
  List<String> _standbyOptions = [];
  final _keteranganController = TextEditingController();
  final _statusController = TextEditingController();
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _fetchFormData();
  }

  Future<void> _fetchFormData() async {
    try {
      final response = await http
          .get(Uri.parse(
              '${Config.baseUrl}/kegiatan/checkout-form?kar_kode=${widget.user.kode}&nomor_minta=${widget.job.nomor}'))
          .timeout(const Duration(seconds: 15));

      if (mounted && response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _noplat = data['data']['noplat'] ?? 'Tidak ada data';
            _tujuan = data['data']['tujuan'] ?? 'Tidak ada data';
            _statusController.text =
                data['data']['status_text'] ?? 'Tidak ada data';
            _standbyOptions = List<String>.from(data['standby_options']);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Gagal memuat detail')),
          );
          Navigator.of(context).pop(); 
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat detail: $e')),
        );
        Navigator.of(context).pop(); 
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: source, imageQuality: 50, maxWidth: 800);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitCheckout() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isSaving = true);

  try {
    // bikin URI ke endpoint checkout
    final uri = Uri.parse('${Config.baseUrl}/kegiatan/checkout');

    // ganti dari http.post ke MultipartRequest
    final request = http.MultipartRequest('POST', uri);

    // tambahin form fields
    request.fields['kar_kode'] = widget.user.kode;
    request.fields['nomor_minta'] = widget.job.nomor;
    request.fields['keterangan'] = _keteranganController.text;
    request.fields['standby'] = _selectedStandby ?? '';

    // kalau ada foto, tambahin file
    if (_imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('foto', _imageFile!.path),
      );
    }

    // kirim request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (mounted) {
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Check Out berhasil!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: ${data['message']}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  } finally {
    if (mounted) setState(() => _isSaving = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check Out')),
      body: _isLoading
          ? const CheckOutFormLoading()
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildInfoText('Nama', widget.user.nama),
                  _buildInfoText('No Plat', _noplat),
                  _buildInfoText('Nomor Minta', widget.job.nomor),
                  _buildInfoText('Tujuan', _tujuan),
                  const Divider(height: 24),
                  TextFormField(
                    controller: _statusController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.08),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedStandby,
                    decoration: const InputDecoration(
                        labelText: 'Stand By', border: OutlineInputBorder()),
                    items: _standbyOptions.map((String value) {
                      return DropdownMenuItem<String>(
                          value: value, child: Text(value));
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedStandby = value),
                    validator: (v) => v == null ? 'Pilih lokasi standby' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _keteranganController,
                    decoration: const InputDecoration(
                        labelText: 'Note', border: OutlineInputBorder()),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  const Text('Image',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: _imageFile != null
                        ? Image.file(_imageFile!, fit: BoxFit.cover)
                        : const Center(
                            child: Icon(Icons.camera_alt,
                                size: 40, color: Colors.grey),
                          ),
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
                    onPressed: _isSaving ? null : _submitCheckout,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(color: Colors.white))
                        : const Text('Check Out'),
                  )
                ],
              ),
            ),
    );
  }

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
