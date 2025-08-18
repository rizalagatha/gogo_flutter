// lib/features/kendaraan/screens/input_perawatan_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../../config.dart'; 

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (newText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    double value = double.parse(newText);

    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    String newString = formatter.format(value);

    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}

class InputPerawatanScreen extends StatefulWidget {
  final String noplat;
  const InputPerawatanScreen({super.key, required this.noplat});

  @override
  State<InputPerawatanScreen> createState() => _InputPerawatanScreenState();
}

class _InputPerawatanScreenState extends State<InputPerawatanScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  final _kmController = TextEditingController();
  final _bengkelController = TextEditingController();
  final _biayaController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _tanggal = DateTime.now();

  List<Map<String, dynamic>> _jenisPerawatanOptions = [];
  int? _selectedJenisPerawatanId;

  @override
  void initState() {
    super.initState();
    _fetchFormData();
  }

  Future<void> _fetchFormData() async {
    try {
      final response =
          await http.get(Uri.parse('${Config.baseUrl}/perawatan/form-data'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _jenisPerawatanOptions =
                List<Map<String, dynamic>>.from(data['data']);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      /* Handle error */
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final biayaTanpaFormat =
        _biayaController.text.replaceAll(RegExp(r'[^0-9]'), '');

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/perawatan'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nopol': widget.noplat,
          'km': _kmController.text,
          'tanggal': DateFormat('yyyy-MM-dd').format(_tanggal),
          'jenis_perawatan_id': _selectedJenisPerawatanId,
          'note': _noteController.text,
          'bengkel': _bengkelController.text,
          'biaya': biayaTanpaFormat,
        }),
      );
      if (mounted) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          Navigator.of(context)
              .pop(true); 
        }
      }
    } catch (e) {
      /* Handle error */
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input Perawatan')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Text('No Plat: ${widget.noplat}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _kmController,
                    decoration: const InputDecoration(
                        labelText: 'KM', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                        v!.isEmpty ? 'KM tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bengkelController,
                    decoration: const InputDecoration(
                        labelText: 'Bengkel', border: OutlineInputBorder()),
                    validator: (v) =>
                        v!.isEmpty ? 'Bengkel tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _biayaController,
                    decoration: const InputDecoration(
                        labelText: 'Biaya', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    validator: (v) =>
                        v!.isEmpty ? 'Biaya tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _selectedJenisPerawatanId,
                    decoration: const InputDecoration(
                        labelText: 'Jenis Perawatan',
                        border: OutlineInputBorder()),
                    items: _jenisPerawatanOptions.map((item) {
                      return DropdownMenuItem<int>(
                        value: int.tryParse(item['id'].toString()),
                        child: Text(item['Jenis_perawatan']),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedJenisPerawatanId = value),
                    validator: (v) =>
                        v == null ? 'Pilih jenis perawatan' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                        labelText: 'Note', border: OutlineInputBorder()),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _submitForm,
                    child: _isSaving
                        ? const CircularProgressIndicator()
                        : const Text('Simpan'),
                  )
                ],
              ),
            ),
    );
  }
}
