import 'package:flutter/material.dart';

import '../core/supabase_client.dart';
import '../services/log_service.dart';
import 'dashboard_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool isRegisterMode = false;
  String selectedRole = 'patient';

  Future<void> signIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage('Email ve şifre boş olamaz');
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        await addLog(
          action: 'LOGIN',
          details: '$email giriş yaptı',
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      }
    } catch (e) {
      showMessage('Giriş hatası: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> signUp() async {
    final fullName = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      showMessage('Tüm alanları doldurun');
      return;
    }

    if (password.length < 6) {
      showMessage('Şifre en az 6 karakter olmalı');
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (res.user != null) {
        await supabase.from('profiles').upsert({
          'id': res.user!.id,
          'full_name': fullName,
          'email': email,
          'role': selectedRole,
        });

        await addLog(
          action: 'REGISTER',
          details: '$email kayıt oldu. Rol: $selectedRole',
        );

        if (!mounted) return;
        showMessage("Kayıt başarılı! Şimdi giriş yapabilirsiniz.");

        setState(() {
          isRegisterMode = false;
          nameController.clear();
          passwordController.clear();
        });
      }
    } catch (e) {
      showMessage('Kayıt hatası: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void showMessage(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m)),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = isRegisterMode ? "Kayıt Ol" : "Giriş Yap";

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 140,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Klinik Randevu Sistemi",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              if (isRegisterMode) ...[
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Ad Soyad",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Şifre",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (isRegisterMode) ...[
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Rol Seç',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'patient',
                      child: Text('Hasta'),
                    ),
                    DropdownMenuItem(
                      value: 'doctor',
                      child: Text('Doktor'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => selectedRole = v);
                  },
                ),
                const SizedBox(height: 20),
              ] else
                const SizedBox(height: 8),
              ElevatedButton(
                onPressed:
                    isLoading ? null : (isRegisterMode ? signUp : signIn),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: isLoading
                    ? const CircularProgressIndicator()
                    : Text(isRegisterMode ? "Kayıt Ol" : "Giriş Yap"),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        setState(() {
                          isRegisterMode = !isRegisterMode;
                          nameController.clear();
                          passwordController.clear();
                        });
                      },
                child: Text(
                  isRegisterMode
                      ? "Zaten hesabın var mı? Giriş yap"
                      : "Hesabın yok mu? Kayıt ol",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
