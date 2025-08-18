// lib/features/kendaraan/screens/history_perawatan_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../data/models/history_perawatan_model.dart';
import 'kegiatan_detail_screen.dart';
import 'input_perawatan_screen.dart';
import '../../../../config.dart'; 

class HistoryPerawatanScreen extends StatefulWidget {
  final String noplat;
  const HistoryPerawatanScreen({super.key, required this.noplat});

  @override
  State<HistoryPerawatanScreen> createState() => _HistoryPerawatanScreenState();
}

class _HistoryPerawatanScreenState extends State<HistoryPerawatanScreen> {
  bool _isLoading = true;
  List<HistoryPerawatan> _historyList = [];
  
  DateTime _startDate = DateTime(2019, 1, 1);
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['message'] ?? 'Gagal memuat data')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('History: ${widget.noplat}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
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
          ),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _historyList.isEmpty
                    ? const Center(child: Text('Tidak ada data pada rentang tanggal ini.'))
                    : RefreshIndicator(
                        onRefresh: _fetchHistory,
                        child: ListView.builder(
                          itemCount: _historyList.length,
                          itemBuilder: (context, index) {
                            final history = _historyList[index];
                            return ListTile(
                              title: Text(history.tujuan, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(history.keterangan.replaceAll(r'\r\n', '\n')),
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
                      ),
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
