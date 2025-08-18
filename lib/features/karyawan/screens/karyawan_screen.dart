// lib/features/karyawan/screens/karyawan_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/widgets/empty_state_widget.dart';
import '../../../data/models/karyawan_model.dart';
import '../widgets/karyawan_list_loading.dart';
import 'history_job_screen.dart'; 
import '../../../../config.dart'; 

class KaryawanScreen extends StatefulWidget {
  const KaryawanScreen({super.key});

  @override
  State<KaryawanScreen> createState() => _KaryawanScreenState();
}

class _KaryawanScreenState extends State<KaryawanScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Karyawan> _karyawanList = [];
  List<Karyawan> _filteredList = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchKaryawan();
    _searchController.addListener(_filterKaryawan);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchKaryawan() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http
          .get(Uri.parse('${Config.baseUrl}/karyawan'))
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            List<dynamic> karyawanJson = data['data'];
            setState(() {
              _karyawanList =
                  karyawanJson.map((json) => Karyawan.fromJson(json)).toList();
              _filteredList = _karyawanList;
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

  void _filterKaryawan() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredList = _karyawanList.where((karyawan) {
        return karyawan.nama.toLowerCase().contains(query);
      }).toList();
    });
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const KaryawanListLoading();
    }

    if (_errorMessage != null) {
      return EmptyStateWidget(
        lottieAsset: 'assets/animations/error_animation.json',
        title: 'Oops, Terjadi Kesalahan',
        message: _errorMessage!,
        onRetry: _fetchKaryawan,
      );
    }

    if (_filteredList.isEmpty) {
      return EmptyStateWidget(
        lottieAsset: 'assets/animations/empty_animation.json',
        title: 'Data Tidak Ditemukan',
        message: _searchController.text.isNotEmpty
            ? 'Tidak ada karyawan yang cocok dengan pencarian Anda.'
            : 'Belum ada data karyawan yang tersedia.',
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchKaryawan,
      child: ListView.builder(
        itemCount: _filteredList.length,
        itemBuilder: (context, index) {
          final karyawan = _filteredList[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text(karyawan.nama.isNotEmpty ? karyawan.nama.substring(0, 1) : '?'),
            ),
            title: Text(karyawan.nama),
            subtitle: Text('Kode: ${karyawan.kode}'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryJobScreen(karyawan: karyawan),
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
      appBar: AppBar(title: const Text('Pilih Karyawan')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama karyawan...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }
}
