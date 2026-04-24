import 'package:flutter/material.dart';

import '../core/supabase_client.dart';
import '../services/log_service.dart';
import 'create_appointment_page.dart';
import 'home_page.dart';
import 'notifications_page.dart';
import 'patient_appointments_page.dart';
import 'patient_examinations_page.dart';
import 'profile_page.dart';

class PatientDashboardPage extends StatefulWidget {
  final Map<String, dynamic>? profile;

  const PatientDashboardPage({
    super.key,
    required this.profile,
  });

  @override
  State<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends State<PatientDashboardPage> {
  int notificationCount = 0;

  @override
  void initState() {
    super.initState();
    loadNotificationCount();
  }

  Future<void> loadNotificationCount() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_read', false);

      setState(() {
        notificationCount = data.length;
      });
    } catch (e) {
      // sessiz geç
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

  Widget menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(icon, color: Colors.blue.shade700),
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
    final fullName = widget.profile?['full_name'] ?? 'Hasta';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hasta Paneli"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade50,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: signOut,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hoş geldiniz, $fullName",
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Randevularınızı, bildirimlerinizi ve muayene geçmişinizi buradan takip edebilirsiniz.",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                menuCard(
                  icon: Icons.add_circle_outline,
                  title: "Randevu Oluştur",
                  subtitle: "Yeni doktor randevusu oluştur",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateAppointmentPage(),
                      ),
                    );
                  },
                ),
                menuCard(
                  icon: Icons.calendar_month,
                  title: "Randevularım",
                  subtitle: "Randevu durumlarını görüntüle",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PatientAppointmentsPage(),
                      ),
                    );
                  },
                ),
                menuCard(
                  icon: Icons.history,
                  title: "Muayene Geçmişim",
                  subtitle: "Doktor tarafından eklenen muayene notları",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PatientExaminationsPage(),
                      ),
                    );
                  },
                ),
                menuCard(
                  icon: Icons.person,
                  title: "Profilim",
                  subtitle: "Kişisel bilgilerini görüntüle ve düzenle",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfilePage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                FloatingActionButton(
                  shape: const CircleBorder(),
                  backgroundColor: Colors.blue,
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsPage(),
                      ),
                    );
                    await loadNotificationCount();
                  },
                  child: const Icon(Icons.notifications, color: Colors.white),
                ),
                if (notificationCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      child: Text(
                        notificationCount > 99
                            ? '99+'
                            : notificationCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}