// lib/features/permintaan_driver/widgets/spk_search_sheet.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../config.dart';

/// Bottom sheet pencarian SPK / Memo SPK / SO.
/// Mengembalikan map {Nomor, Nama, Tipe}, atau null jika dibatalkan.
Future<Map<String, dynamic>?> showSpkSearchSheet(BuildContext context) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const _SpkSearchSheet(),
  );
}

class _SpkSearchSheet extends StatefulWidget {
  const _SpkSearchSheet();

  @override
  State<_SpkSearchSheet> createState() => _SpkSearchSheetState();
}

class _SpkSearchSheetState extends State<_SpkSearchSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  String _keyword = '';
  List<dynamic> _results = [];
  bool _isLoading = false;
  bool _searched = false;
  String? _error;
  int _reqId = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _keyword = value.trim());
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 400), () => _search(_keyword));
  }

  Future<void> _search(String keyword) async {
    final req = ++_reqId;

    if (keyword.length < 2) {
      setState(() {
        _results = [];
        _isLoading = false;
        _searched = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = Uri.parse('${Config.baseUrl}/permintaan/search-spk')
          .replace(queryParameters: {'query': keyword});
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      final data = json.decode(response.body);

      if (!mounted || req != _reqId) return;

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _results = (data['data'] as List<dynamic>?) ?? [];
          _isLoading = false;
          _searched = true;
        });
      } else {
        throw Exception(data['message'] ?? 'Gagal mencari SPK');
      }
    } catch (e) {
      if (!mounted || req != _reqId) return;
      setState(() {
        _isLoading = false;
        _error = 'Gagal memuat data. Periksa koneksi Anda.';
      });
    }
  }

  Widget _buildBody() {
    if (_keyword.length < 2) {
      return const Center(
          child: Text('Ketik minimal 2 karakter untuk mencari.'));
    }
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_searched && _results.isEmpty) {
      return const Center(child: Text('Tidak ada hasil.'));
    }

    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _results[index];
        return ListTile(
          title: Text(
            item['Nomor']?.toString() ?? '-',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            item['Nama']?.toString() ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(item['Tipe']?.toString() ?? ''),
          onTap: () =>
              Navigator.of(context).pop(Map<String, dynamic>.from(item)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Tinggi menyesuaikan sisa layar di atas keyboard
    final height =
        (media.size.height - media.viewInsets.bottom - media.padding.top) * 0.9;

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Cari nomor / nama SPK, Memo, atau SO',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: _onChanged,
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }
}
