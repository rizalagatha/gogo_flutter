// lib/features/auth/screens/change_password_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../config.dart';
import '../../../data/models/user_model.dart';

class ChangePasswordScreen extends StatefulWidget {
  final User? user; // diisi jika dibuka dari menu (sudah login)
  final String initialKode; // dipakai jika dibuka dari layar login

  const ChangePasswordScreen({super.key, this.user, this.initialKode = ''});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  late final TextEditingController _kodeController =
      TextEditingController(text: widget.user?.kode ?? widget.initialKode);

  bool _isLoading = false;
  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    _kodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/auth/change-password'),
        body: {
          'username': widget.user?.kode ?? _kodeController.text.trim(),
          'oldPassword': _oldController.text,
          'newPassword': _newController.text,
        },
      );

      if (!mounted) return;

      final data = json.decode(response.body);
      final success = response.statusCode == 200 && data['success'] == true;

      _showSnackbar(
        data['message'] ??
            (success ? 'Password berhasil diubah' : 'Terjadi kesalahan'),
        isError: !success,
      );

      if (success) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showSnackbar(
        'Tidak dapat terhubung. Periksa koneksi Anda.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool visible,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      obscureText: !visible,
      enabled: !_isLoading,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(
          Icons.lock_outline,
          color: colorScheme.onSurfaceVariant,
        ),
        hintText: hint,
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ganti Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (widget.user != null) ...[
                        Text(
                          widget.user!.nama,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                      ] else ...[
                        TextFormField(
                          controller: _kodeController,
                          enabled: !_isLoading,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Kode wajib diisi'
                              : null,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            hintText: 'Login',
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildPasswordField(
                        controller: _oldController,
                        hint: 'Password Lama',
                        visible: _showOld,
                        onToggle: () => setState(() => _showOld = !_showOld),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Password lama wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordField(
                        controller: _newController,
                        hint: 'Password Baru',
                        visible: _showNew,
                        onToggle: () => setState(() => _showNew = !_showNew),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password baru wajib diisi';
                          }
                          if (v.length < 6) return 'Minimal 6 karakter';
                          if (v == _oldController.text) {
                            return 'Tidak boleh sama dengan password lama';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordField(
                        controller: _confirmController,
                        hint: 'Konfirmasi Password Baru',
                        visible: _showConfirm,
                        onToggle: () =>
                            setState(() => _showConfirm = !_showConfirm),
                        validator: (v) => v != _newController.text
                            ? 'Konfirmasi tidak cocok'
                            : null,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Simpan',
                                  style: TextStyle(fontSize: 16),
                                ),
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
    );
  }
}
