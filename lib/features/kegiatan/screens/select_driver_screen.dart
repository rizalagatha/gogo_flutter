// lib/features/kegiatan/screens/select_driver_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../data/models/selectable_driver_model.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../../config.dart';

class SelectDriverScreen extends StatefulWidget {
  const SelectDriverScreen({super.key});

  @override
  State<SelectDriverScreen> createState() => _SelectDriverScreenState();
}

class _SelectDriverScreenState extends State<SelectDriverScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<SelectableDriver> _driverList = [];
  Timer? _debounce;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDrivers('');
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
      _fetchDrivers(query);
    });
  }

  Future<void> _fetchDrivers(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse('${Config.baseUrl}/karyawan/drivers?query=$query'));
      if (mounted && response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          List<dynamic> driverJson = data['data'];
          setState(() {
            _driverList = driverJson.map((json) => SelectableDriver.fromJson(json)).toList();
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
        onRetry: () => _fetchDrivers(_searchController.text),
      );
    }
    if (_driverList.isEmpty) {
      return EmptyStateWidget(
        lottieAsset: 'assets/animations/empty_animation.json',
        title: 'Driver Tidak Ditemukan',
        message: 'Tidak ada driver yang cocok dengan pencarian Anda.',
      );
    }

    return ListView.builder(
      itemCount: _driverList.length,
      itemBuilder: (context, index) {
        final driver = _driverList[index];
        return ListTile(
          title: Text(driver.nama),
          subtitle: Text('Kode: ${driver.kode}'),
          onTap: () {
            Navigator.of(context).pop(driver);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Driver')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari kode atau nama driver...',
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
