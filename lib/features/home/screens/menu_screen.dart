import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';

import 'package:gogo_flutter/main.dart';

import '../../../data/models/user_model.dart';
import '../../karyawan/screens/karyawan_screen.dart';
import '../../permintaan_driver/screens/permintaan_driver_screen.dart';
import '../../job/screens/daftar_job_screen.dart';
import '../../monitoring/screens/monitoring_screen.dart';
import '../../kegiatan/screens/check_in_screen.dart';
import '../../kegiatan/screens/check_out_list_screen.dart';
import '../../kendaraan/screens/daftar_kendaraan_screen.dart';
import '../../update_info/screens/update_info_screen.dart';
import '../../../core/providers/theme_provider.dart';
import '../../job/screens/daftar_job_batal_screen.dart';
import '../../../../config.dart';

class MenuScreen extends StatefulWidget {
  final User user;

  const MenuScreen({super.key, required this.user});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Timer? _notificationTimer;
  String _appVersion = '...';

  @override
  void initState() {
    super.initState();
    _getAppVersion();
    _fetchNotifications();
    _startNotificationTimer();
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  void _startNotificationTimer() {
    _notificationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _fetchNotifications();
    });
  }

  Future<void> _fetchNotifications() async {
    final userKode = widget.user.kode;
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/notifications?user_kode=$userKode'),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> notifications = data['notifications'] ?? [];
          for (var i = 0; i < notifications.length; i++) {
            final notif = notifications[i];
            notificationService.showNotification(
              i,
              notif['title'] ?? 'Info',
              notif['body'] ?? '-',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Gagal mengambil notifikasi: $e');
    }
  }

  void _showCheckInOutDialog() async {
    if (!widget.user.isDriver) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda tidak berhak membuka menu ini')),
      );
      return;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Pilih tindakan Anda.'),
        actions: [
          TextButton(
            child: const Text('Check Out'),
            onPressed: () => Navigator.of(context).pop('checkout'),
          ),
          TextButton(
            child: const Text('Check In'),
            onPressed: () => Navigator.of(context).pop('checkin'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result == 'checkin') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckInScreen(user: widget.user),
        ),
      );
      return;
    }

    if (result == 'checkout') {
      try {
        final response = await http.get(
            Uri.parse('${Config.baseUrl}/kegiatan/check-open?user_kode=${widget.user.kode}'));

        if (!mounted) return;

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            final hasOpenJob = data['has_open_job'] == true;
            if (hasOpenJob) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CheckOutListScreen(user: widget.user),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Tidak ada yang harus di-check out')),
              );
            }
          }
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _onUpdateInfoTapped() async {
    try {
      final response = await http.get(Uri.parse(
          '${Config.baseUrl}/kegiatan/check-open?user_kode=${widget.user.kode}'));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          if (data['has_open_job'] == true) {
            final int kegiatanId = int.parse('${data['kegiatan_id']}');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UpdateInfoScreen(
                  user: widget.user,
                  kegiatanId: kegiatanId,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Tidak ada kegiatan yang sedang berjalan untuk diupdate.'),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _getAppVersion() async {
    try {
      final response = await http.get(Uri.parse('${Config.baseUrl}/app-version'));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() => _appVersion = data['version'] ?? 'N/A');
        } else {
          setState(() => _appVersion = 'N/A');
        }
      } else {
        setState(() => _appVersion = 'N/A');
      }
    } catch (e) {
      debugPrint('Gagal mendapatkan versi aplikasi dari API: $e');
      if (!mounted) return;
      setState(() => _appVersion = 'N/A');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final List<Color> cardColors = [
      Colors.deepPurple.shade100,
      Colors.blue.shade100,
      Colors.green.shade100,
      Colors.orange.shade100,
      Colors.teal.shade100,
      Colors.red.shade100,
      Colors.indigo.shade100,
      Colors.pink.shade100,
    ];

    final menuItemsData = [
      {
        'icon': Icons.person_add_alt_1_outlined,
        'title': 'Minta Driver',
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PermintaanDriverScreen(user: widget.user),
              ),
            ),
      },
      {
        'icon': Icons.assignment_outlined,
        'title': 'Daftar Job',
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DaftarJobScreen()),
            ),
      },
      {
        'icon': Icons.monitor_outlined,
        'title': 'Monitoring',
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MonitoringScreen()),
            ),
      },
      {
        'icon': Icons.login_outlined,
        'title': 'Check In/Out',
        'onTap': _showCheckInOutDialog,
      },
      {
        'icon': Icons.directions_car_outlined,
        'title': 'Kendaraan',
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const DaftarKendaraanScreen()),
            ),
      },
      {
        'icon': Icons.info_outline,
        'title': 'Update Info',
        'onTap': _onUpdateInfoTapped,
      },
      {
        'icon': Icons.history_edu_outlined,
        'title': 'History Job',
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const KaryawanScreen()),
            ),
      },
      {
        'icon': Icons.cancel_outlined,
        'title': 'Job Batal',
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const DaftarJobBatalScreen()),
            ),
      },
    ];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Image.asset(
            'assets/logo_kencana.png',
            width: 100,
            height: 100,
          ),
          actions: [
            IconButton(
              tooltip: 'Ganti Tema',
              icon: Icon(
                themeProvider.themeMode == ThemeMode.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
              onPressed: () {
                final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
                themeProvider.toggleTheme(!isDarkMode);
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed('/login'),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      'Selamat Datang,',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      minFontSize: 14,
                    ),
                    AutoSizeText(
                      widget.user.nama,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      minFontSize: 18,
                    ),
                  ],
                ),
              ),

              // ====== GRID MENU (GridView.builder) ======
              AnimationLimiter(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: menuItemsData.length,
                  itemBuilder: (context, index) {
                    return AnimationConfiguration.staggeredGrid(
                      position: index,
                      duration: const Duration(milliseconds: 500),
                      columnCount: 3,
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _buildGridMenuItem(
                            icon: menuItemsData[index]['icon'] as IconData,
                            title: menuItemsData[index]['title'] as String,
                            onTap:
                                menuItemsData[index]['onTap'] as VoidCallback,
                            color: cardColors[index % cardColors.length],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'Ver $_appVersion',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget helper
  Widget _buildGridMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color color,
  }) {
    final textColor =
        color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    return Card(
      color: color,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: textColor),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
