// lib/features/kegiatan/screens/select_job_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../data/models/selectable_job_model.dart';
import '../../../core/widgets/empty_state_widget.dart'; 
import '../../../../config.dart'; 

class SelectJobScreen extends StatefulWidget {
  const SelectJobScreen({super.key});

  @override
  State<SelectJobScreen> createState() => _SelectJobScreenState();
}

class _SelectJobScreenState extends State<SelectJobScreen> {
  bool _isLoading = true;
  String? _errorMessage; 
  List<SelectableJob> _jobList = [];
  Timer? _debounce;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSelectableJobs(''); 
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
      _fetchSelectableJobs(query);
    });
  }

  Future<void> _fetchSelectableJobs(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse('${Config.baseUrl}/permintaan/selectable-jobs?query=$query'));
      if (mounted && response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          List<dynamic> jobJson = data['data'];
          setState(() {
            _jobList = jobJson.map((json) => SelectableJob.fromJson(json)).toList();
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
        onRetry: () => _fetchSelectableJobs(_searchController.text),
      );
    }

    if (_jobList.isEmpty) {
      return EmptyStateWidget(
        lottieAsset: 'assets/animations/empty_animation.json',
        title: 'Data Tidak Ditemukan',
        message: 'Tidak ada pekerjaan yang cocok dengan pencarian Anda.',
      );
    }

    return ListView.builder(
      itemCount: _jobList.length,
      itemBuilder: (context, index) {
        final job = _jobList[index];
        return ListTile(
          title: Text(job.nomor),
          subtitle: Text('${job.customer} => ${job.uraian}'),
          onTap: () {
            Navigator.of(context).pop(job);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Permintaan Job')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari nomor, customer, atau uraian...',
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
