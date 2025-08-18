// lib/features/monitoring/screens/monitoring_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../data/models/monitoring_model.dart';
import '../../monitoring/widget/monitoring_list_loading.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../../config.dart'; 

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<MonitoringData> _monitoringList = [];

  @override
  void initState() {
    super.initState();
    _fetchMonitoringData();
  }

  Future<void> _fetchMonitoringData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http
          .get(Uri.parse('${Config.baseUrl}/monitoring'))
          .timeout(const Duration(seconds: 15));

      if (mounted) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            List<dynamic> monitoringJson = data['data'];
            setState(() {
              _monitoringList = monitoringJson
                  .map((json) => MonitoringData.fromJson(json))
                  .toList();
            });
          } else {
             setState(() => _errorMessage = data['message'] ?? 'Gagal memuat data');
          }
        } else {
           setState(() => _errorMessage = 'Error: ${response.statusCode}');
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
  
  Widget _buildContent() {
    if (_isLoading) {
      return const MonitoringListLoading(); 
    }

    if (_errorMessage != null) {
      return EmptyStateWidget(
        lottieAsset: 'assets/animations/error_animation.json',
        title: 'Oops, Terjadi Kesalahan',
        message: _errorMessage!,
        onRetry: _fetchMonitoringData,
      );
    }

    if (_monitoringList.isEmpty) {
      return EmptyStateWidget(
        lottieAsset: 'assets/animations/empty_animation.json',
        title: 'Data Tidak Ditemukan',
        message: 'Belum ada data monitoring yang tersedia.',
        onRetry: _fetchMonitoringData,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMonitoringData,
      child: ListView.builder(
        itemCount: _monitoringList.length,
        itemBuilder: (context, index) {
          final item = _monitoringList[index];
          final bool isFree = item.keterangan.toUpperCase().contains('FREE');
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isFree ? Colors.green : Colors.orange,
                child: Icon(
                  isFree ? Icons.check_circle_outline : Icons.directions_car,
                  color: Colors.white,
                ),
              ),
              title: Text(item.namaKaryawan, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(item.keterangan.replaceAll(r'\r\n', '\n')),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Driver'),
      ),
      body: _buildContent(),
    );
  }
}
