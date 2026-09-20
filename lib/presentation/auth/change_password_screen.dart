import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/snack_bar_helper.dart';
import '../../logic/providers/auth_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.changePassword(
      oldPassword: _oldPasswordController.text,
      newPassword: _newPasswordController.text,
      newPasswordConfirmation: _confirmPasswordController.text,
    );

    if (success) {
      if (mounted) {
        SnackBarHelper.show(
          context: context,
          message: 'Kata sandi berhasil diperbarui!',
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        SnackBarHelper.show(
          context: context,
          message: authProvider.errorMessage ?? 'Gagal mengubah kata sandi',
          isError: true,
        );
      }
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Ubah Kata Sandi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Keamanan Akun',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              Text(
                'Pastikan kata sandi baru Anda kuat dan sulit ditebak.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _oldPasswordController,
                      decoration: _inputDecoration('Kata Sandi Lama', Icons.lock_open_outlined),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Kata sandi lama wajib diisi';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      decoration: _inputDecoration('Kata Sandi Baru', Icons.lock_outline),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Kata sandi baru wajib diisi';
                        if (value.length < 8) return 'Minimal 8 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: _inputDecoration('Konfirmasi Kata Sandi Baru', Icons.security_outlined),
                      obscureText: true,
                      validator: (value) {
                        if (value != _newPasswordController.text) return 'Konfirmasi kata sandi tidak cocok';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    Consumer<AuthProvider>(
                      builder: (context, auth, child) {
                        return auth.isLoading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _changePassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text('Perbarui Kata Sandi',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
