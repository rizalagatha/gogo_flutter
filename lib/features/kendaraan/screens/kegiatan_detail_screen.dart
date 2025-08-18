// lib/features/kendaraan/screens/kegiatan_detail_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../data/models/kegiatan_detail_model.dart';
import '../../../data/models/kegiatan_subdetail_model.dart';
import '../../../../config.dart'; 

class KegiatanDetailScreen extends StatefulWidget {
  final int kegiatanId;
  const KegiatanDetailScreen({super.key, required this.kegiatanId});

  @override
  State<KegiatanDetailScreen> createState() => _KegiatanDetailScreenState();
}

class _KegiatanDetailScreenState extends State<KegiatanDetailScreen> {
  bool _isLoading = true;
  KegiatanDetail? _mainData;
  List<KegiatanSubDetail> _subDetails = [];

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final response = await http
          .get(Uri.parse('${Config.baseUrl}/kegiatan/${widget.kegiatanId}/detail'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _mainData = KegiatanDetail.fromJson(data['main_data']);
            _subDetails = (data['sub_details'] as List)
                .map((json) => KegiatanSubDetail.fromJson(json))
                .toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {/* Handle error */}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Kegiatan')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _mainData == null
              ? const Center(child: Text('Data tidak ditemukan.'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Info Section
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nama: ${_mainData!.namaDriver}'),
                          Text('No Plat: ${_mainData!.noplat}'),
                          Text('Tujuan: ${_mainData!.tujuan}'),
                          Text('Status: ${_mainData!.status}'),
                          Text('Note: ${_mainData!.note ?? '-'}'),
                        ],
                      ),
                    ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Detail Kunjungan:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    // Sub-details List
                    Expanded(
                      child: ListView.builder(
                        itemCount: _subDetails.length,
                        itemBuilder: (context, index) {
                          final detail = _subDetails[index];
                          return ListTile(
                            leading: CircleAvatar(child: Text('${index + 1}')),
                            title: Text(detail.customer),
                            subtitle: Text('Jam: ${detail.jam}'),
                            onTap: () {
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
