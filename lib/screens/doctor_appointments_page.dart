import 'package:flutter/material.dart';

import '../core/supabase_client.dart';
import '../core/utils.dart';
import 'appointment_detail_page.dart';

class DoctorAppointmentsPage extends StatefulWidget {
  const DoctorAppointmentsPage({super.key});

  @override
  State<DoctorAppointmentsPage> createState() => _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState extends State<DoctorAppointmentsPage> {
  List appointments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAppointments();
  }

  Future<void> loadAppointments() async {
    try {
      final user = supabase.auth.currentUser;

      final data = await supabase
          .from('appointments')
          .select(
              'id, appointment_date, status, note, patient_id, doctor_id, doctor_response_note')
          .eq('doctor_id', user!.id)
          .order('appointment_date', ascending: false);

      setState(() {
        appointments = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> refreshAppointments() async {
    setState(() => isLoading = true);
    await loadAppointments();
  }

  String buildStatusText(String status) {
    if (status == 'onaylandı') return 'Onaylandı';
    if (status == 'reddedildi') return 'Reddedildi';
    if (status == 'iptal') return 'İptal';
    if (status == 'tamamlandı') return 'Tamamlandı';
    return 'Bekliyor';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bana Gelen Randevular"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : appointments.isEmpty
              ? const Center(child: Text("Henüz randevu yok"))
              : ListView.builder(
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final item = appointments[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.medical_services),
                        title:
                            Text("Durum: ${buildStatusText(item['status'])}"),
                        subtitle: Text(
                          "Tarih: ${formatDateTime(item['appointment_date'])}\n"
                          "Hasta Notu: ${item['note'] ?? ''}\n"
                          "Doktor Notu: ${item['doctor_response_note'] ?? ''}",
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AppointmentDetailPage(appointment: item),
                            ),
                          );
                          await refreshAppointments();
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
