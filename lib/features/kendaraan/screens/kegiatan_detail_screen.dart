// lib/features/kendaraan/screens/kegiatan_detail_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

// Import model dan halaman yang relevan
import '../../../data/models/kegiatan_detail_model.dart';
import '../../../data/models/kegiatan_subdetail_model.dart';
import '../../../../config.dart';
import '../../../core/widgets/empty_state_widget.dart';

class KegiatanDetailScreen extends StatefulWidget {
  final int kegiatanId;
  const KegiatanDetailScreen({super.key, required this.kegiatanId});

  @override
  State<KegiatanDetailScreen> createState() => _KegiatanDetailScreenState();
}

class _KegiatanDetailScreenState extends State<KegiatanDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  KegiatanDetail? _mainData;
  List<KegiatanSubDetail> _subDetails = [];
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url =
          Uri.parse('${Config.baseUrl}/kegiatan/${widget.kegiatanId}/detail');
      final response = await http.get(url);

      if (mounted) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            setState(() {
              _mainData = KegiatanDetail.fromJson(data['main_data']);

              // 🚀 ubah bagian foto di sini jadi full URL
              _subDetails = (data['sub_details'] as List).map((json) {
                if (json['foto'] != null &&
                    json['foto'].toString().isNotEmpty) {
                  json['fotoUrl'] = "${Config.baseUrl}/uploads/${json['foto']}";
                }
                return KegiatanSubDetail.fromJson(json);
              }).toList();
            });
          } else {
            setState(() => _errorMessage = data['message']);
          }
        } else {
          setState(() => _errorMessage = 'Gagal terhubung ke server.');
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

  void _setupMapMarkers() {
    final markers = <Marker>{};
    LatLng? firstCoordinate;

    for (final detail in _subDetails) {
      if (detail.latitude != null && detail.longitude != null) {
        final position = LatLng(detail.latitude!, detail.longitude!);
        firstCoordinate ??=
            position; // Keep track of the first valid coordinate
        markers.add(
          Marker(
            markerId: MarkerId(detail.id.toString()),
            position: position,
            infoWindow: InfoWindow(
              title: detail.customer,
              snippet: 'Jam: ${detail.jam}',
              onTap: () {
                if (detail.fotoUrl != null && detail.fotoUrl!.isNotEmpty) {
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      child: InteractiveViewer(
                        child: Image.network(
                          "${Config.baseUrl}/uploads/${detail.fotoUrl}", // 👈 tambahkan baseUrl di sini
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, stack) =>
                              const Icon(Icons.broken_image, size: 100),
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        );
      }
    }

    setState(() {
      _markers.addAll(markers);
    });

    // Animate camera to the first location
    if (firstCoordinate != null) {
      _mapController
          ?.animateCamera(CameraUpdate.newLatLngZoom(firstCoordinate, 14));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Kegiatan & Kunjungan')),
      body: _buildContent(),
    );
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
        onRetry: _fetchDetails,
      );
    }
    if (_mainData == null) {
      return EmptyStateWidget(
        lottieAsset: 'assets/animations/empty_animation.json',
        title: 'Data Tidak Ditemukan',
        message: 'Detail untuk kegiatan ini tidak dapat ditemukan.',
        onRetry: _fetchDetails,
      );
    }

    return Column(
      children: [
        // Main Info Section
        _buildMainInfoCard(),
        // Map Section
        if (_subDetails.isNotEmpty && _markers.isNotEmpty) _buildMapCard(),
        // Sub-details List Section
        _buildSubDetailsList(),
      ],
    );
  }

  Widget _buildMainInfoCard() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Nama Driver', _mainData!.namaDriver),
            _infoRow('No Plat', _mainData!.noplat),
            _infoRow('Tujuan', _mainData!.tujuan),
            _infoRow('Status', _mainData!.status),
            _infoRow('Keterangan', _mainData!.keterangan ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCard() {
    return Expanded(
      flex: 3,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        clipBehavior: Clip.antiAlias,
        child: GoogleMap(
          onMapCreated: (controller) {
            _mapController = controller;
            _setupMapMarkers(); // Recenter map if it loads after markers are set
          },
          initialCameraPosition: CameraPosition(
            target: _markers.isNotEmpty
                ? _markers.first.position
                : const LatLng(-7.565, 110.825), // fallback koordinat default
            zoom: 12,
          ),
          markers: _markers,
        ),
      ),
    );
  }

  Widget _buildSubDetailsList() {
    return Expanded(
      flex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Daftar Kunjungan:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          Expanded(
            child: _subDetails.isEmpty
                ? const Center(child: Text('Belum ada kunjungan.'))
                : ListView.builder(
                    itemCount: _subDetails.length,
                    itemBuilder: (context, index) {
                      final detail = _subDetails[index];
                      return ListTile(
                        leading: detail.fotoUrl != null &&
                                detail.fotoUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  "${Config.baseUrl}/uploads/${detail.fotoUrl}", // 👈 tambahkan baseUrl di sini
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) =>
                                      const Icon(Icons.broken_image, size: 40),
                                ),
                              )
                            : CircleAvatar(child: Text('${index + 1}')),
                        title: Text(detail.customer),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Jam: ${detail.jam}'),
                            if (detail.latitude != null &&
                                detail.longitude != null)
                              Text(
                                  'Lokasi: ${detail.latitude}, ${detail.longitude}'),
                          ],
                        ),
                        onTap: () {
                          if (detail.latitude != null &&
                              detail.longitude != null) {
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                LatLng(detail.latitude!, detail.longitude!),
                                16,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 100,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          const Text(': '),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
