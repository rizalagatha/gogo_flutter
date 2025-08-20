// lib/features/kendaraan/screens/kegiatan_detail_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  LatLng? _initialCenter;

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

              _subDetails = (data['sub_details'] as List).map((json) {
                if (json['foto'] != null &&
                    json['foto'].toString().isNotEmpty) {
                  json['fotoUrl'] = "${Config.baseUrl}/uploads/${json['foto']}";
                }
                return KegiatanSubDetail.fromJson(json);
              }).toList();
              _setupMapMarkers(); // Panggil setup markers setelah data siap
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
    final markers = <Marker>[];
    LatLng? firstCoordinate;

    for (final detail in _subDetails) {
      if (detail.latitude != null && detail.longitude != null) {
        final position = LatLng(detail.latitude!, detail.longitude!);
        firstCoordinate ??= position;
        markers.add(
          Marker(
            width: 80.0,
            height: 80.0,
            point: position,
            child: Tooltip(
              message: detail.customer,
              child: Icon(Icons.location_pin, color: Colors.red, size: 40.0),
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
      // [PERBAIKAN] Simpan koordinat awal ke state, jangan panggil .move()
      _initialCenter = firstCoordinate;
    });
  }

  Future<void> _launchMapsUrl(double lat, double lng) async {
    final Uri url = Uri.parse('http://www.openstreetmap.org/#map=18/$lat/$lng');
    if (!await launchUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka peta')),
      );
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
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _initialCenter ?? const LatLng(-7.565, 110.825), // Fallback ke koordinat default
            initialZoom: 12,
          ),
          children: [
            TileLayer(
              urlTemplate: 'http://googleusercontent.com/tile/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.gogo_flutter', // Ganti dengan package name Anda
            ),
            MarkerLayer(markers: _markers),
          ],
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
                      final hasPhoto = detail.fotoUrl != null && detail.fotoUrl!.isNotEmpty;
                      final photoUrl = hasPhoto ? "${Config.baseUrl}/uploads/${detail.fotoUrl}" : null;
                      final hasLocation = detail.latitude != null && detail.longitude != null;

                      return ListTile(
                        leading: GestureDetector(
                          onTap: hasPhoto ? () {
                            showDialog(context: context, builder: (_) => Dialog(child: Padding(padding: const EdgeInsets.all(8.0), child: InteractiveViewer(child: Image.network(photoUrl!)))));
                          } : null,
                          child: CircleAvatar(
                            // [PERBAIKAN] Menggunakan photoUrl yang sudah dibangun
                            backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
                            child: !hasPhoto ? Text('${index + 1}') : null,
                          ),
                        ),
                        title: Text(detail.customer),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Jam: ${detail.jam}'),
                            if (hasLocation)
                              InkWell(
                                onTap: () => _launchMapsUrl(detail.latitude!, detail.longitude!),
                                child: const Padding(
                                  padding: EdgeInsets.only(top: 4.0),
                                  child: Text('Lihat di Peta', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          if (hasLocation) {
                            _mapController.move(LatLng(detail.latitude!, detail.longitude!), 16.0);
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
