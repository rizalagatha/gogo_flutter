// lib/features/kendaraan/screens/daftar_kendaraan_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/widgets/empty_state_widget.dart';
import '../../../data/models/kendaraan_model.dart';
import 'history_perawatan_screen.dart';
import '../../kendaraan/screens/widgets/kendaraan_list_loading.dart';
import '../../../../config.dart';

class DaftarKendaraanScreen extends StatefulWidget {
  const DaftarKendaraanScreen({super.key});

  @override
  State<DaftarKendaraanScreen> createState() => _DaftarKendaraanScreenState();
}

class _DaftarKendaraanScreenState extends State<DaftarKendaraanScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Kendaraan> _kendaraanList = [];
  List<Kendaraan> _filteredList = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchKendaraan();
    _searchController.addListener(_filterKendaraan);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchKendaraan() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http
          .get(Uri.parse('${Config.baseUrl}/kendaraan'))
          .timeout(const Duration(seconds: 10));
          
      if (mounted) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            List<dynamic> kendaraanJson = data['data'];
            setState(() {
              _kendaraanList = kendaraanJson.map((json) => Kendaraan.fromJson(json)).toList();
              _filteredList = _kendaraanList;
            });
          } else {
             setState(() => _errorMessage = data['message'] ?? 'Gagal memuat data');
          }
        }
      }
    } on TimeoutException {
      setState(() => _errorMessage = 'Server tidak merespons. Periksa koneksi Anda.');
    } catch (e) {
      setState(() => _errorMessage = 'Terjadi kesalahan: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterKendaraan() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredList = _kendaraanList.where((kendaraan) {
        return kendaraan.noplat.toLowerCase().contains(query) ||
               kendaraan.keterangan.toLowerCase().contains(query);
      }).toList();
    });
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const KendaraanListLoading();
    }

    if (_errorMessage != null) {
      return EmptyStateWidget(
        lottieAsset: 'assets/animations/error_animation.json', 
        title: 'Oops, Terjadi Kesalahan',
        message: _errorMessage!,
        onRetry: _fetchKendaraan,
      );
    }

    if (_filteredList.isEmpty) {
      return EmptyStateWidget(
        lottieAsset: 'assets/animations/empty_animation.json', 
        title: 'Data Tidak Ditemukan',
        message: _searchController.text.isNotEmpty
            ? 'Tidak ada kendaraan yang cocok dengan pencarian Anda.'
            : 'Belum ada data kendaraan yang tersedia.',
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchKendaraan,
      child: ListView.builder(
        itemCount: _filteredList.length,
        itemBuilder: (context, index) {
          final kendaraan = _filteredList[index];
          return ListTile(
            leading: const Icon(Icons.directions_car),
            title: Text(kendaraan.noplat),
            subtitle: Text(kendaraan.keterangan),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryPerawatanScreen(noplat: kendaraan.noplat),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Kendaraan')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari no plat atau keterangan...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }
}
