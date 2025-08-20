// File: screens/detail_visit_screen.dart

// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// // Import model yang sudah kita pisahkan
// import '../../../data/models/detail_visit_model.dart';
// import '../../../../config.dart';

// // Halaman utama untuk menampilkan detail kunjungan.
// class DetailVisitScreen extends StatefulWidget {
//   final int visitId;

//   const DetailVisitScreen({super.key, required this.visitId});

//   @override
//   State<DetailVisitScreen> createState() => _DetailVisitScreenState();
// }

// class _DetailVisitScreenState extends State<DetailVisitScreen> {
//   VisitDetail? _visitDetail;
//   bool _isLoading = true;
//   String _errorMessage = '';

//   GoogleMapController? _mapController;
//   final Set<Marker> _markers = {};

//   @override
//   void initState() {
//     super.initState();
//     _fetchVisitDetails();
//   }

//   // Fungsi untuk mengambil data dari backend Express.js.
//   Future<void> _fetchVisitDetails() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//     });

//     try {
//       final url = Uri.parse('${Config.baseUrl}/api/visit/${widget.visitId}');
      
//       final response = await http.get(url).timeout(const Duration(seconds: 10));

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         _visitDetail = VisitDetail.fromJson(data);
//         _setupMapMarker();
//       } else {
//         throw Exception('Gagal memuat data dari server (Status code: ${response.statusCode})');
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   void _setupMapMarker() {
//     if (_visitDetail == null) return;

//     final marker = Marker(
//       markerId: MarkerId(_visitDetail!.id.toString()),
//       position: LatLng(_visitDetail!.latitude, _visitDetail!.longitude),
//       infoWindow: InfoWindow(
//         title: _visitDetail!.customerName,
//         snippet: 'Lokasi Kunjungan',
//       ),
//     );

//     setState(() {
//       _markers.clear(); // Hapus marker lama sebelum menambah yang baru
//       _markers.add(marker);
//     });

//     _mapController?.animateCamera(
//       CameraUpdate.newLatLngZoom(
//         LatLng(_visitDetail!.latitude, _visitDetail!.longitude),
//         15,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Detail Visit'),
//         backgroundColor: Colors.blueGrey[800],
//         foregroundColor: Colors.white,
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _errorMessage.isNotEmpty
//               ? Center(child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Text(_errorMessage, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center,),
//                 ))
//               : _buildContent(),
//     );
//   }

//   Widget _buildContent() {
//     if (_visitDetail == null) {
//       return const Center(child: Text('Tidak ada data untuk ditampilkan.'));
//     }

//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildInfoRow(
//                 icon: Icons.business,
//                 label: 'Customer',
//                 value: _visitDetail!.customerName,
//               ),
//               const SizedBox(height: 16),
//               _buildInfoRow(
//                 icon: Icons.location_on,
//                 label: 'Location',
//                 value: '${_visitDetail!.latitude}, ${_visitDetail!.longitude}',
//               ),
//             ],
//           ),
//         ),
//         const Divider(height: 1, thickness: 1),
//         Expanded(
//           child: GoogleMap(
//             onMapCreated: (GoogleMapController controller) {
//               _mapController = controller;
//               _setupMapMarker();
//             },
//             initialCameraPosition: CameraPosition(
//               target: LatLng(_visitDetail!.latitude, _visitDetail!.longitude),
//               zoom: 15.0,
//             ),
//             markers: _markers,
//             mapType: MapType.normal,
//             zoomControlsEnabled: true,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
//      return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Icon(icon, color: Colors.blueGrey, size: 24),
//         const SizedBox(width: 16),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
//               const SizedBox(height: 4),
//               Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
