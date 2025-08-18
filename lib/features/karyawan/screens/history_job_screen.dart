// lib/features/karyawan/screens/history_job_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../data/models/karyawan_model.dart';
import '../../../data/models/history_job_model.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../widgets/history_job_list_loading.dart';
import '../../kendaraan/screens/kegiatan_detail_screen.dart';
import '../../../../config.dart'; 

class HistoryJobScreen extends StatefulWidget {
  final Karyawan karyawan;
  const HistoryJobScreen({super.key, required this.karyawan});

  @override
  State<HistoryJobScreen> createState() => _HistoryJobScreenState();
}

class _HistoryJobScreenState extends State<HistoryJobScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<HistoryJob> _historyList = [];

  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    final formattedStartDate = DateFormat('yyyy-MM-dd').format(_startDate);
    final formattedEndDate = DateFormat('yyyy-MM-dd').format(_endDate);

    final url = '${Config.baseUrl}/karyawan/${widget.karyawan.kode}/history?start_date=$formattedStartDate&end_date=$formattedEndDate';
    print("[DEBUG] URL: $url");

    try {
      final response = await http.get(Uri.parse(url));
      if (mounted && response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          List<dynamic> historyJson = data['data'];
          setState(() {
            _historyList = historyJson.map((json) => HistoryJob.fromJson(json)).toList();
          });
        } else {
          print("[DEBUG] Gagal: ${data['message']}");
        }
      } else {
        print("[DEBUG] Status Code: ${response.statusCode}");
      }
    } catch (e) { 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'))
        );
      }
    } 
    finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) _startDate = picked;
        else _endDate = picked;
      });
    }
  }

  void _setQuickRange(String type) {
    final now = DateTime.now();
    setState(() {
      if (type == 'today') {
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = now;
      } else if (type == '7days') {
        _startDate = now.subtract(const Duration(days: 6));
        _endDate = now;
      } else if (type == 'thisMonth') {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
      }
    });
    _fetchHistory();
  }

 Widget _buildContent() {
    if (_isLoading) {
      return const HistoryJobListLoading();
    }
    if (_errorMessage != null) {
      return EmptyStateWidget(
        lottieAsset: 'assets/animations/error_animation.json',
        title: 'Oops, Terjadi Kesalahan',
        message: _errorMessage!,
        onRetry: _fetchHistory,
      );
    }
    if (_historyList.isEmpty) {
      return EmptyStateWidget(
        lottieAsset: 'assets/animations/empty_animation.json',
        title: 'Data Tidak Ditemukan',
        message: 'Tidak ada riwayat pekerjaan pada rentang tanggal ini.',
        onRetry: _fetchHistory,
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchHistory,
      child: ListView.builder(
        itemCount: _historyList.length,
        itemBuilder: (context, index) {
          final history = _historyList[index];
          return ListTile(
            title: Text(history.tujuan),
            subtitle: Text('Jam: ${history.jam}\nKet: ${history.keterangan}'),
            isThreeLine: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => KegiatanDetailScreen(kegiatanId: history.id),
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
      appBar: AppBar(title: Text('Kegiatan ${widget.karyawan.nama}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildDatePickerButton(context, isStartDate: true)),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('s/d')),
                    Expanded(child: _buildDatePickerButton(context, isStartDate: false)),
                    IconButton(icon: const Icon(Icons.search), onPressed: _fetchHistory),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => _setQuickRange('today'),
                      child: const Text('Hari Ini'),
                    ),
                    ElevatedButton(
                      onPressed: () => _setQuickRange('7days'),
                      child: const Text('7 Hari Terakhir'),
                    ),
                    ElevatedButton(
                      onPressed: () => _setQuickRange('thisMonth'),
                      child: const Text('Bulan Ini'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildDatePickerButton(BuildContext context, {required bool isStartDate}) {
    return OutlinedButton(
      onPressed: () => _selectDate(context, isStartDate),
      child: Text(DateFormat('dd/MM/yyyy').format(isStartDate ? _startDate : _endDate)),
    );
  }
}
