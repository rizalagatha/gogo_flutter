// lib/features/kendaraan/screens/history_perawatan_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../data/models/history_perawatan_model.dart';
import 'input_perawatan_screen.dart';
import '../../../../config.dart';
import '../../../core/widgets/empty_state_widget.dart';

class HistoryPerawatanScreen extends StatefulWidget {
  final String noplat;
  const HistoryPerawatanScreen({super.key, required this.noplat});

  @override
  State<HistoryPerawatanScreen> createState() => _HistoryPerawatanScreenState();
}

class _HistoryPerawatanScreenState extends State<HistoryPerawatanScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<HistoryPerawatan> _historyList = [];
  
  DateTime _startDate = DateTime(2019, 1, 1);
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final formattedStartDate = DateFormat('yyyy-MM-dd').format(_startDate);
    final formattedEndDate = DateFormat('yyyy-MM-dd').format(_endDate);

    try {
      final response = await http.get(Uri.parse(
          '${Config.baseUrl}/kendaraan/${widget.noplat}/history?start_date=$formattedStartDate&end_date=$formattedEndDate'));
      
      if (mounted) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            List<dynamic> historyJson = data['data'];
            setState(() {
              _historyList = historyJson.map((json) => HistoryPerawatan.fromJson(json)).toList();
            });
          } else {
            setState(() => _errorMessage = data['message'] ?? 'Gagal memuat data');
          }
        } else {
           setState(() => _errorMessage = 'Gagal terhubung ke server');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Terjadi kesalahan: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _setQuickRange(String type) {
    final now = DateTime.now();
    setState(() {
      if (type == '7days') {
        _startDate = now.subtract(const Duration(days: 6));
        _endDate = now;
      } else if (type == 'thisMonth') {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
      }
    });
    _fetchHistory(); // Langsung panggil fetch setelah tanggal diubah
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
        onRetry: _fetchHistory,
      );
    }
    if (_historyList.isEmpty) {
      return EmptyStateWidget(
        lottieAsset: 'assets/animations/empty_animation.json',
        title: 'Data Tidak Ditemukan',
        message: 'Tidak ada riwayat perawatan pada rentang tanggal ini.',
        onRetry: _fetchHistory,
      );
    }

    final numberFormatter = NumberFormat("#,###", "id_ID");

    return RefreshIndicator(
      onRefresh: _fetchHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _historyList.length,
        itemBuilder: (context, index) {
          final history = _historyList[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    history.tujuan,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tanggal : ${history.tanggal}'),
                      Text('Bengkel : ${history.bengkel}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Biaya : ${numberFormatter.format(history.biaya)}'),
                      Text('KM : ${numberFormatter.format(history.km)}'),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('History: ${widget.noplat}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            // [PERUBAHAN] Menggunakan Column untuk menampung baris tombol baru
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDatePickerButton(context, isStartDate: true),
                    const Text('s/d'),
                    _buildDatePickerButton(context, isStartDate: false),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _fetchHistory,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // [BARU] Baris untuk tombol filter cepat
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
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
          const Divider(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => InputPerawatanScreen(noplat: widget.noplat),
            ),
          );
          
          if (result == true) {
            setState(() {
              _endDate = DateTime.now();
            });
            _fetchHistory();
          }
        },
        tooltip: 'Input Perawatan Baru',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDatePickerButton(BuildContext context, {required bool isStartDate}) {
    return TextButton(
      onPressed: () => _selectDate(context, isStartDate),
      child: Text(DateFormat('dd/MM/yyyy').format(isStartDate ? _startDate : _endDate)),
    );
  }
}
