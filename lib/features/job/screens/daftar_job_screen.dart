// lib/features/job/screens/daftar_job_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/widgets/empty_state_widget.dart';
import '../../../data/models/daftar_job_model.dart';
import 'daftar_job_detail_screen.dart';
import '../widgets/job_list_loading.dart';
import '../../../../config.dart'; 

class DaftarJobScreen extends StatefulWidget {
  const DaftarJobScreen({super.key});

  @override
  State<DaftarJobScreen> createState() => _DaftarJobScreenState();
}

class _DaftarJobScreenState extends State<DaftarJobScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<DaftarJob> _jobList = [];
  List<DaftarJob> _filteredList = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchJobs();
    _searchController.addListener(_filterJobs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http
          .get(Uri.parse('${Config.baseUrl}/jobs'))
          .timeout(const Duration(seconds: 10));
          
      if (mounted) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            List<dynamic> jobJson = data['data'];
            setState(() {
              _jobList = jobJson.map((json) => DaftarJob.fromJson(json)).toList();
              _filteredList = _jobList;
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

  void _filterJobs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredList = _jobList.where((job) {
        return job.nomor.toLowerCase().contains(query) ||
               job.customer.toLowerCase().contains(query) ||
               job.uraian.toLowerCase().contains(query);
      }).toList();
    });
  }

  Color _getStatusColor(String status) {
    if (status.toLowerCase() == 'proses') {
      return Colors.orange.shade700;
    }
    return Colors.green; 
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const JobListLoading();
    }

    if (_errorMessage != null) {
      return EmptyStateWidget(
        lottieAsset: 'assets/animations/error_animation.json',
        title: 'Oops, Terjadi Kesalahan',
        message: _errorMessage!,
        onRetry: _fetchJobs,
      );
    }

    if (_filteredList.isEmpty) {
      return EmptyStateWidget(
        lottieAsset: 'assets/animations/empty_animation.json',
        title: 'Data Tidak Ditemukan',
        message: _searchController.text.isNotEmpty
            ? 'Tidak ada pekerjaan yang cocok dengan pencarian Anda.'
            : 'Belum ada data pekerjaan yang tersedia.',
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchJobs,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80), 
        itemCount: _filteredList.length,
        itemBuilder: (context, index) {
          final job = _filteredList[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DaftarJobDetailScreen(job: job),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(job.nomor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Chip(
                          label: Text(
                            job.status,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          backgroundColor: _getStatusColor(job.status),
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    _buildInfoRow(Icons.business_outlined, 'Customer', job.customer),
                    _buildInfoRow(Icons.description_outlined, 'Uraian', job.uraian),
                    _buildInfoRow(Icons.flag_outlined, 'Tipe', job.tipeJadwal),
                    _buildInfoRow(Icons.person_outline, 'Peminta', job.userPeminta),
                    _buildInfoRow(Icons.directions_car_outlined, 'Driver', job.driver ?? '-'),
                    _buildInfoRow(Icons.calendar_today_outlined, 'Tgl Kerja', job.tglKerja),
                    _buildInfoRow(Icons.access_time_outlined, 'Jam Kerja', job.jamKerja),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey[600])),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Job')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari job...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchJobs,
        tooltip: 'Segarkan',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
