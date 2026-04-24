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

  String getAuthErrorMessage(dynamic e) {
    final error = e.toString().toLowerCase();

    if (error.contains('invalid login credentials')) {
      return 'E-posta veya şifre hatalı.';
    } else if (error.contains('user not found')) {
      return 'Bu e-posta ile kayıtlı kullanıcı bulunamadı';
    } else {
      return 'Bir hata oluştu, tekrar deneyin';
    }
  }

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
      showMessage(getAuthErrorMessage(e));
    } finally {
      if (mounted) setState(() => isLoading = false);
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

        showMessage("Kayıt başarılı! Giriş yapabilirsiniz.");

        setState(() {
          isRegisterMode = false;
          nameController.clear();
          passwordController.clear();
        });
      }
    } catch (e) {
      showMessage(getAuthErrorMessage(e));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showMessage(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = isRegisterMode ? "Kayıt Ol" : "Giriş Yap";

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF6FB1FC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.local_hospital,
                        size: 60, color: Colors.blue),
                    const SizedBox(height: 10),

                    Text(
                      "Klinik Randevu Sistemi",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (isRegisterMode) ...[
                      TextField(
                        controller: nameController,
                        decoration: inputStyle("Ad Soyad", Icons.person),
                      ),
                      const SizedBox(height: 12),
                    ],

                    TextField(
                      controller: emailController,
                      decoration: inputStyle("Email", Icons.email),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: inputStyle("Şifre", Icons.lock),
                    ),

                    const SizedBox(height: 12),

                    if (isRegisterMode) ...[
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration:
                        inputStyle("Rol Seç", Icons.person_outline),
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
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : (isRegisterMode ? signUp : signIn),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : Text(
                          isRegisterMode ? "Kayıt Ol" : "Giriş Yap",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextButton(
                      onPressed: () {
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
          ),
        ),
      ),
    );
  }
}