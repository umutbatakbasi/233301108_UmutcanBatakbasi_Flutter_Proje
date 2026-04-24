import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';
import '../core/utils.dart';
import '../services/log_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? profile;
  bool isLoading = true;
  bool isEditMode = false;
  bool isSaving = false;

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      final data =
          await supabase.from('profiles').select().eq('id', user.id).maybeSingle();

      fullNameController.text = data?['full_name'] ?? '';
      emailController.text = user.email ?? data?['email'] ?? '';

      setState(() {
        profile = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  String get roleText {
    final role = profile?['role'];
    if (role == 'doctor') return 'Doktor';
    if (role == 'patient') return 'Hasta';
    return 'Belirsiz';
  }

  Future<void> saveProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();

    if (fullName.isEmpty || email.isEmpty) {
      showMessage('Ad soyad ve email boş olamaz');
      return;
    }

    setState(() => isSaving = true);

    try {
      await supabase.from('profiles').update({
        'full_name': fullName,
        'email': email,
      }).eq('id', user.id);

      if (user.email != email) {
        await supabase.auth.updateUser(
          UserAttributes(email: email),
        );
      }

      await addLog(
        action: 'UPDATE_PROFILE',
        details: 'Profil bilgileri güncellendi',
      );

      if (!mounted) return;

      showMessage('Profil başarıyla güncellendi');

      setState(() {
        profile = {
          ...?profile,
          'full_name': fullName,
          'email': email,
        };
        isEditMode = false;
      });
    } catch (e) {
      showMessage('Hata: $e');
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
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
    fullNameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final fullName = profile?['full_name'] ?? 'Bulunamadı';
    final email = user?.email ?? profile?['email'] ?? 'Bulunamadı';
    final createdAt = formatDateTime(profile?['created_at']);
    final userId = user?.id ?? profile?['id'] ?? '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profilim"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: isSaving
                ? null
                : () {
                    setState(() {
                      isEditMode = !isEditMode;
                      if (!isEditMode) {
                        fullNameController.text = profile?['full_name'] ?? '';
                        emailController.text =
                            user?.email ?? profile?['email'] ?? '';
                      }
                    });
                  },
            icon: Icon(isEditMode ? Icons.close : Icons.edit),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    child: Text(
                      fullName.toString().isNotEmpty
                          ? fullName.toString()[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isEditMode) ...[
                    TextField(
                      controller: fullNameController,
                      decoration: const InputDecoration(
                        labelText: "Ad Soyad",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isSaving ? null : saveProfile,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: isSaving
                          ? const CircularProgressIndicator()
                          : const Text("Kaydet"),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text("Ad Soyad"),
                      subtitle: Text(fullName),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: const Text("Email"),
                      subtitle: Text(email),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: const Text("Rol"),
                      subtitle: Text(roleText),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_month_outlined),
                      title: const Text("Kayıt Tarihi"),
                      subtitle: Text(createdAt),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.fingerprint),
                      title: const Text("Kullanıcı ID"),
                      subtitle: Text(userId),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
