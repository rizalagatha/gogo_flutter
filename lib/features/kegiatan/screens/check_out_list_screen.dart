// lib/features/kegiatan/screens/check_out_list_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../data/models/checkout_job_model.dart';
import '../../../data/models/user_model.dart';
import 'check_out_form_screen.dart'; 
import '../widgets/check_out_list_loading.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../../config.dart'; 

class CheckOutListScreen extends StatefulWidget {
  final User user;
  const CheckOutListScreen({super.key, required this.user});

  @override
  State<CheckOutListScreen> createState() => _CheckOutListScreenState();
}

class _CheckOutListScreenState extends State<CheckOutListScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<CheckoutJob> _jobList = [];

  @override
  void initState() {
    super.initState();
    _fetchCheckoutJobs();
  }

  Future<void> _fetchCheckoutJobs() async {
    try {
      final response = await http.get(Uri.parse(
          '${Config.baseUrl}/jobs/checkout-list?driver_name=${widget.user.nama}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          List<dynamic> jobJson = data['data'];
          setState(() {
            _jobList = jobJson.map((json) => CheckoutJob.fromJson(json)).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) { 
      // Handle error
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Job untuk Check Out')),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const CheckoutListLoading();
    }
    if (_errorMessage != null) {
      return EmptyStateWidget(
        lottieAsset: 'assets/animations/error_animation.json',
        title: 'Oops, Terjadi Kesalahan',
        message: _errorMessage!,
        onRetry: _fetchCheckoutJobs,
      );
    }
    if (_jobList.isEmpty) {
      return EmptyStateWidget(
        lottieAsset: 'assets/animations/empty_animation.json',
        title: 'Tidak Ada Pekerjaan',
        message: 'Saat ini tidak ada pekerjaan yang perlu di-check out.',
        onRetry: _fetchCheckoutJobs,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchCheckoutJobs,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: _jobList.length,
        itemBuilder: (context, index) {
          final job = _jobList[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              title: Text(
                job.nomor,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                    'Uraian: ${job.uraian}\n'
                    'Tgl Kerja: ${job.tglKerja} | Jam: ${job.jamKerja}'),
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CheckOutFormScreen(user: widget.user, job: job),
                  ),
                ).then((isSuccess) {
                  if (isSuccess == true) {
                    _fetchCheckoutJobs();
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
