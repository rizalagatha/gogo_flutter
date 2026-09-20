// lib/features/auth/screens/change_password_dialog.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../config.dart';
import '../../../data/models/user_model.dart';

/// Menampilkan dialog ganti password.
/// - Dari menu (sudah login): kirim [user].
/// - Dari layar login: kirim [initialKode] (isi kolom login saat ini).
/// Mengembalikan true jika password berhasil diubah.
Future<bool> showChangePasswordDialog(
  BuildContext context, {
  User? user,
  String initialKode = '',
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ChangePasswordDialog(user: user, initialKode: initialKode),
  );

  if (result == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password berhasil diubah'),
        backgroundColor: Colors.green,
      ),
    );
  }
  return result == true;
}

class ChangePasswordDialog extends StatefulWidget {
  final User? user;
  final String initialKode;

  const ChangePasswordDialog({super.key, this.user, this.initialKode = ''});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
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
  String? _errorMessage;

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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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

      if (success) {
        Navigator.of(context).pop(true);
        return;
      }

      setState(() =>
          _errorMessage = data['message']?.toString() ?? 'Terjadi kesalahan');
    } catch (e) {
      if (!mounted) return;
      setState(
          () => _errorMessage = 'Tidak dapat terhubung. Periksa koneksi Anda.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool visible,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      enabled: !_isLoading,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          icon: Icon(
            visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ganti Password'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.user == null) ...[
                  TextFormField(
                    controller: _kodeController,
                    enabled: !_isLoading,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Kode wajib diisi'
                        : null,
                    decoration: InputDecoration(
                      labelText: 'Kode / Login',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _passwordField(
                  controller: _oldController,
                  label: 'Password Lama',
                  visible: _showOld,
                  onToggle: () => setState(() => _showOld = !_showOld),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Password lama wajib diisi'
                      : null,
                ),
                const SizedBox(height: 16),
                _passwordField(
                  controller: _newController,
                  label: 'Password Baru',
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
                _passwordField(
                  controller: _confirmController,
                  label: 'Konfirmasi Password Baru',
                  visible: _showConfirm,
                  onToggle: () => setState(() => _showConfirm = !_showConfirm),
                  validator: (v) => v != _newController.text
                      ? 'Konfirmasi tidak cocok'
                      : null,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
