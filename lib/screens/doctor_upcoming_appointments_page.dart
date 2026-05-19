import 'package:flutter/material.dart';

import '../core/supabase_client.dart';
import '../core/utils.dart';

class DoctorUpcomingAppointmentsPage extends StatefulWidget {
  const DoctorUpcomingAppointmentsPage({super.key});

  @override
  State<DoctorUpcomingAppointmentsPage> createState() =>
      _DoctorUpcomingAppointmentsPageState();
}

class _DoctorUpcomingAppointmentsPageState
    extends State<DoctorUpcomingAppointmentsPage> {
  List appointments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUpcomingAppointments();
  }

  Future<void> loadUpcomingAppointments() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      final now = DateTime.now();

      final data = await supabase
          .from('appointments')
          .select(
        'id, appointment_date, status, note, patient_id, doctor_response_note',
      )
          .eq('doctor_id', user.id)
          .gte('appointment_date', now.toIso8601String())
          .order('appointment_date', ascending: true);

      setState(() {
        appointments = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  String buildStatusText(String status) {
    if (status == 'onaylandı') return 'Onaylandı';
    if (status == 'reddedildi') return 'Reddedildi';
    if (status == 'iptal') return 'İptal';
    if (status == 'tamamlandı') return 'Tamamlandı';
    return 'Bekliyor';
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'onaylandı':
        return Colors.green;
      case 'reddedildi':
        return Colors.red;
      case 'tamamlandı':
        return Colors.blue;
      case 'iptal':
        return Colors.orange;
      default:
        return Colors.amber.shade700;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status) {
      case 'onaylandı':
        return Icons.check_circle;
      case 'reddedildi':
        return Icons.cancel;
      case 'tamamlandı':
        return Icons.task_alt;
      case 'iptal':
        return Icons.remove_circle;
      default:
        return Icons.access_time;
    }
  }

  Widget buildAppointmentCard(Map item) {
    final status = item['status'] ?? 'bekliyor';
    final statusColor = getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: statusColor.withOpacity(0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.15),
                child: Icon(
                  getStatusIcon(status),
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  formatDateTime(item['appointment_date']),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  buildStatusText(status),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.notes, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Hasta Notu: ${item['note'] == null || item['note'].toString().isEmpty ? '-' : item['note']}",
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.medical_information, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Doktor Notu: ${item['doctor_response_note'] == null || item['doctor_response_note'].toString().isEmpty ? '-' : item['doctor_response_note']}",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Gelecek Randevular",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Toplam ${appointments.length} gelecek randevu görüntüleniyor.",
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7FF),
      appBar: AppBar(
        title: const Text("Randevuları Gör"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : appointments.isEmpty
          ? const Center(
        child: Text("Gelecek tarihli randevu yok"),
      )
          : RefreshIndicator(
        onRefresh: loadUpcomingAppointments,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return buildHeader();
            }

            final item = appointments[index - 1];
            return buildAppointmentCard(item);
          },
        ),
      ),
    );
  }
}