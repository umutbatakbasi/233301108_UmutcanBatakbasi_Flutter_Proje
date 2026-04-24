import 'package:flutter/material.dart';

import '../core/supabase_client.dart';
import 'patient_appointments_page.dart';
import 'patient_examinations_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      final data = await supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        notifications = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> openNotification(Map item) async {
    try {
      final title = (item['title'] ?? '').toString().toLowerCase();

      // önce read yap
      await supabase
          .from('notifications')
          .update({'is_read': true}).eq('id', item['id']);

      // sonra sil
      await supabase.from('notifications').delete().eq('id', item['id']);

      if (!mounted) return;

      setState(() {
        notifications.removeWhere((n) => n['id'] == item['id']);
      });

      // 🔥 YÖNLENDİRME
      if (title.contains('randevu')) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PatientAppointmentsPage(),
          ),
        );
      } else if (title.contains('muayene')) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PatientExaminationsPage(),
          ),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(item['message'] ?? 'Bildirim açıldı')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Color getBackgroundColor(Map item) {
    final isRead = item['is_read'] ?? false;

    return isRead ? Colors.white : Colors.blue.shade50;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bildirimlerim"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? const Center(child: Text("Bildirim yok"))
          : ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final item = notifications[index];

          return Card(
            color: getBackgroundColor(item),
            child: ListTile(
              leading: Icon(
                Icons.notifications_active,
                color: item['is_read'] == true
                    ? Colors.grey
                    : Colors.blue,
              ),
              title: Text(
                item['title'] ?? 'Bildirim',
                style: TextStyle(
                  fontWeight: item['is_read'] == true
                      ? FontWeight.normal
                      : FontWeight.bold,
                ),
              ),
              subtitle: Text(item['message'] ?? ''),
              onTap: () => openNotification(item),
            ),
          );
        },
      ),
    );
  }
}