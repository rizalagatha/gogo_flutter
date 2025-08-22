// lib/features/job/screens/daftar_job_detail_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../data/models/job_detail_model.dart';
import '../../../data/models/daftar_job_model.dart'; 
import '../../../../config.dart'; 

class DaftarJobDetailScreen extends StatefulWidget {
  final DaftarJob job;
  const DaftarJobDetailScreen({super.key, required this.job});

  @override
  State<DaftarJobDetailScreen> createState() => _DaftarJobDetailScreenState();
}

class _DaftarJobDetailScreenState extends State<DaftarJobDetailScreen> {
  bool _isLoading = true;
  List<JobDetail> _detailList = [];

  @override
  void initState() {
    super.initState();
    _fetchJobDetails();
  }

  Future<void> _fetchJobDetails() async {
    try {
      final response = await http.get(
          Uri.parse('${Config.baseUrl}/jobs/${widget.job.nomor}/detail'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          List<dynamic> detailJson = data['data'];
          setState(() {
            _detailList =
                detailJson.map((json) => JobDetail.fromJson(json)).toList();
            _isLoading = false;
          });
        } else {
           setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Detail Job: ${widget.job.nomor}')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderInfo('Customer', widget.job.customer),
                _buildHeaderInfo('Pengambilan', widget.job.pengambilan ?? '-'),
                _buildHeaderInfo('PIC', widget.job.pic ?? '-'), 
                _buildHeaderInfo('Uraian', widget.job.uraian),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Detail SPK:', 
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                ),
              ],
            ),
          ),
          // List of details
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _detailList.isEmpty
                    ? const Center(child: Text('Tidak ada detail SPK untuk job ini.'))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: _detailList.length,
                        itemBuilder: (context, index) {
                          final detail = _detailList[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                child: Text('${detail.noUrut}')
                              ),
                              title: Text('SPK: ${detail.spk}'),
                              subtitle: Text(
                                'Ket: ${detail.keterangan}\n'
                                'Penerima: ${detail.penerima ?? '-'}',
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeaderInfo(String label, String value) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: RichText(
        text: TextSpan(
          // Gunakan bodyMedium sebagai gaya dasar yang akan beradaptasi
          style: textTheme.bodyMedium,
          children: <TextSpan>[
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
