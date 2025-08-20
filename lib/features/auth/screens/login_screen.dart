// lib/features/auth/screens/login_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../config.dart';
import '../../home/screens/menu_screen.dart';
import '../../../data/models/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _kodeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _savePassword = true;
  bool _isLoading = false;
  String _appVersion = '1.0.0';

  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _loadInitialData();
  }

  Future<void> _requestPermissions() async {
    var status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }

  @override
  void dispose() {
    _kodeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _getAppVersion();
    // await _checkServerVersion();
    await _loadSavedCredentials();
  }

  Future<void> _getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = packageInfo.version;
      });
    }
  }

  // Future<void> _checkServerVersion() async {
  //   try {
  //     final response = await http.get(Uri.parse('${Config.baseUrl}/app-version'));
  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       final serverVersion = data['version'];
  //       if (mounted && _appVersion.isNotEmpty && serverVersion != _appVersion) {
  //         _showUpdateDialog(serverVersion);
  //       }
  //     }
  //   } catch (e) {
  //     print('Gagal memeriksa versi: $e');
  //   }
  // }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKode = prefs.getString('saved_kode');
    if (savedKode != null && savedKode.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse('${Config.baseUrl}/auth/credentials?kode=$savedKode'));
        if (mounted && response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            setState(() {
              _kodeController.text = savedKode;
              _passwordController.text = data['password']; // Mengisi password
              _savePassword = true;
            });
          }
        }
      } catch (e) {
        print("Gagal mengambil password tersimpan: $e");
        // Jika gagal, setidaknya isi username
        setState(() {
          _kodeController.text = savedKode;
        });
      }
    }
  }

  Future<void> _login() async {
    if (_kodeController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorSnackbar('Kode dan Password tidak boleh kosong');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/auth/login'),
        body: {'username': _kodeController.text, 'password': _passwordController.text},
      );

      if (mounted) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            final user = User.fromJson(data['user']);
            final prefs = await SharedPreferences.getInstance();
            if (_savePassword) {
              await prefs.setString('saved_kode', user.kode);
            } else {
              await prefs.remove('saved_kode');
            }
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MenuScreen(user: user)),
            );
          } else {
            _showErrorSnackbar(data['message'] ?? 'Terjadi kesalahan');
          }
        } else {
          _showErrorSnackbar('Gagal terhubung ke server.');
        }
      }
    } catch (e) {
      _showErrorSnackbar('Tidak dapat terhubung. Periksa koneksi Anda.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showUpdateDialog(String newVersion) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Update Tersedia'),
        content: Text('Versi baru ($newVersion) tersedia. Silahkan update aplikasi Anda.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
            ),
            child: IntrinsicHeight(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 1),
                        const Text(
                          'GOGO',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Silakan login untuk melanjutkan',
                          style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 40),
                        TextField(
                          controller: _kodeController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            hintText: 'Login',
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface, 
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            hintText: 'Password',
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface, 
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 10),
                        CheckboxListTile(
                          title: const Text('Save Password'),
                          value: _savePassword,
                          onChanged: _isLoading
                              ? null
                              : (bool? newValue) {
                                  setState(() {
                                    _savePassword = newValue ?? false;
                                  });
                                },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 3, color: Colors.white),
                                  )
                                : const Text('Login', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        const Spacer(flex: 2),
                        Image.asset(
                          'assets/logo_kencana.png',
                          height: 150,
                          fit: BoxFit.contain,
                        ),
                        const Spacer(flex: 1),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            'Ver. $_appVersion',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
