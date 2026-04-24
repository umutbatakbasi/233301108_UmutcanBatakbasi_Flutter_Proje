import 'package:flutter/material.dart';

import '../core/supabase_client.dart';
import '../services/log_service.dart';
import 'doctor_appointments_page.dart';
import 'home_page.dart';
import 'profile_page.dart';

class DoctorDashboardPage extends StatefulWidget {
  final Map<String, dynamic>? profile;

  const DoctorDashboardPage({
    super.key,
    required this.profile,
  });

  @override
  State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage> {
  int pendingCount = 0;
  int approvedCount = 0;
  int completedCount = 0;
  bool isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    loadAppointmentStats();
  }

  Future<void> loadAppointmentStats() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('appointments')
          .select('id, status')
          .eq('doctor_id', user.id);

      int pending = 0;
      int approved = 0;
      int completed = 0;

      for (final item in data) {
        if (item['status'] == 'bekliyor') pending++;
        if (item['status'] == 'onaylandı') approved++;
        if (item['status'] == 'tamamlandı') completed++;
      }

      setState(() {
        pendingCount = pending;
        approvedCount = approved;
        completedCount = completed;
        isLoadingStats = false;
      });
    } catch (e) {
      setState(() => isLoadingStats = false);
    }
  }

  Future<void> signOut() async {
    final email = supabase.auth.currentUser?.email ?? '';

    await addLog(
      action: 'LOGOUT',
      details: '$email çıkış yaptı',
    );

    await supabase.auth.signOut();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  Widget statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Card(
        color: Colors.indigo.shade50,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Icon(icon, color: Colors.indigo, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade50,
          child: Icon(icon, color: Colors.indigo),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName = widget.profile?['full_name'] ?? 'Doktor';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Doktor Paneli"),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade50,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: signOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Doktor Paneli",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Hoş geldiniz, $fullName",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Randevu onaylama, iptal etme ve muayene işlemlerinizi buradan yönetin.",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            isLoadingStats
                ? const Center(child: CircularProgressIndicator())
                : Row(
              children: [
                statCard(
                  title: "Bekleyen",
                  value: pendingCount.toString(),
                  icon: Icons.hourglass_empty,
                ),
                statCard(
                  title: "Onaylı",
                  value: approvedCount.toString(),
                  icon: Icons.check_circle_outline,
                ),
                statCard(
                  title: "Tamamlanan",
                  value: completedCount.toString(),
                  icon: Icons.task_alt,
                ),
              ],
            ),
            const SizedBox(height: 18),
            menuCard(
              icon: Icons.medical_services,
              title: "Bana Gelen Randevular",
              subtitle: "Randevuları incele, onayla, reddet veya iptal et",
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoctorAppointmentsPage(),
                  ),
                );
                await loadAppointmentStats();
              },
            ),
            menuCard(
              icon: Icons.person,
              title: "Profilim",
              subtitle: "Doktor profil bilgilerini görüntüle ve düzenle",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfilePage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}