// lib/features/update_info/screens/update_info_list_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../data/models/user_model.dart';
import '../../../data/models/open_job_model.dart';
import 'update_info_form_screen.dart'; 
import '../widgets/update_info_list_loading.dart'; 
import '../../../core/widgets/empty_state_widget.dart';
import '../../../../config.dart';

class UpdateInfoListScreen extends StatefulWidget {
  final User user;
  const UpdateInfoListScreen({super.key, required this.user});

  @override
  State<UpdateInfoListScreen> createState() => _UpdateInfoListScreenState();
}

class _UpdateInfoListScreenState extends State<UpdateInfoListScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<OpenJob> _jobList = [];

  @override
  void initState() {
    super.initState();
    _fetchAvailableJobs();
  }

  Future<void> _fetchAvailableJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final url = Uri.parse('${Config.baseUrl}/karyawan/${widget.user.kode}/open-jobs');
      final response = await http.get(url);
      if (mounted) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            List<dynamic> jobJson = data['data'];
            setState(() {
              _jobList = jobJson.map((json) => OpenJob.fromJson(json)).toList();
            });
          } else {
            setState(() => _errorMessage = data['message']);
          }
        } else {
          setState(() => _errorMessage = 'Gagal memuat daftar pekerjaan.');
        }
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Pekerjaan')),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const UpdateInfoListLoading(); // <-- Tampilkan skeleton loading
    }
    if (_errorMessage != null) {
      return EmptyStateWidget( // <-- Tampilkan Lottie error
        lottieAsset: 'assets/animations/error_animation.json',
        title: 'Oops, Terjadi Kesalahan',
        message: _errorMessage!,
        onRetry: _fetchAvailableJobs,
      );
    }
    if (_jobList.isEmpty) {
      return EmptyStateWidget( // <-- Tampilkan Lottie empty
        lottieAsset: 'assets/animations/empty_animation.json',
        title: 'Tidak Ada Pekerjaan',
        message: 'Saat ini tidak ada pekerjaan yang perlu diupdate.',
        onRetry: _fetchAvailableJobs,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAvailableJobs,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: _jobList.length,
        itemBuilder: (context, index) {
          final job = _jobList[index];
          return Card( // <-- Gunakan Card untuk setiap item
            elevation: 2,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              title: Text(
                job.tujuan,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'ID: ${job.id}\nTanggal: ${job.tglKerja} | Jam: ${job.jamKerja}',
                ),
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpdateInfoFormScreen(
                      user: widget.user,
                      job: job,
                    ),
                  ),
                ).then((isSuccess) {
                  // Refresh daftar jika form berhasil disubmit
                  if (isSuccess == true) {
                    _fetchAvailableJobs();
                  }
                });
              },
            ),
          );
        },
      ),
    );
  }
}
