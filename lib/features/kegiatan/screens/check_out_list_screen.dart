// lib/features/kegiatan/screens/check_out_list_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../data/models/checkout_job_model.dart';
import '../../../data/models/user_model.dart';
import 'check_out_form_screen.dart'; 
import '../../../../config.dart'; 

class CheckOutListScreen extends StatefulWidget {
  final User user;
  const CheckOutListScreen({super.key, required this.user});

  @override
  State<CheckOutListScreen> createState() => _CheckOutListScreenState();
}

class _CheckOutListScreenState extends State<CheckOutListScreen> {
  bool _isLoading = true;
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _jobList.length,
              itemBuilder: (context, index) {
                final job = _jobList[index];
                return ListTile(
                  title: Text(job.nomor),
                  subtitle: Text(
                      'Uraian: ${job.uraian}\n'
                      'Tgl Kerja: ${job.tglKerja} | Jam: ${job.jamKerja}'),
                  isThreeLine: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckOutFormScreen(user: widget.user, job: job),
                      ),
                    ).then((_) {
                      _fetchCheckoutJobs();
                    });
                  },
                );
              },
            ),
    );
  }
}
