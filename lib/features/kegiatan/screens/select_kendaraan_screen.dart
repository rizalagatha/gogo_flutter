// lib/features/kegiatan/screens/select_kendaraan_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/widgets/empty_state_widget.dart'; 
import '../../../../config.dart'; 

class SelectKendaraanScreen extends StatefulWidget {
  const SelectKendaraanScreen({super.key});

  @override
  State<SelectKendaraanScreen> createState() => _SelectKendaraanScreenState();
}

class _SelectKendaraanScreenState extends State<SelectKendaraanScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<String> _kendaraanList = [];
  Timer? _debounce;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchKendaraan('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchKendaraan(query);
    });
  }

  Future<void> _searchKendaraan(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse('${Config.baseUrl}/kendaraan/search?query=$query'));
      if (mounted && response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _kendaraanList = List<String>.from(data['data']);
          });
        } else {
          setState(() => _errorMessage = data['message'] ?? 'Gagal memuat data');
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Terjadi kesalahan koneksi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return EmptyStateWidget(
        lottieAsset: 'assets/animations/error_animation.json',
        title: 'Oops, Terjadi Kesalahan',
        message: _errorMessage!,
        onRetry: () => _searchKendaraan(_searchController.text),
      );
    }

    if (_kendaraanList.isEmpty) {
      return EmptyStateWidget(
        lottieAsset: 'assets/animations/empty_animation.json',
        title: 'Data Tidak Ditemukan',
        message: 'Tidak ada kendaraan yang cocok dengan pencarian Anda.',
      );
    }

    return ListView.builder(
      itemCount: _kendaraanList.length,
      itemBuilder: (context, index) {
        final noplat = _kendaraanList[index];
        return ListTile(
          title: Text(noplat),
          onTap: () {
            Navigator.of(context).pop(noplat);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cari Kendaraan')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Ketik No Plat...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              autofocus: true,
            ),
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }
}
