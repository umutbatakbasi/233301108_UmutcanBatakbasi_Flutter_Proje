import 'package:flutter/material.dart';

import '../core/supabase_client.dart';
import '../core/utils.dart';

class PatientAppointmentsPage extends StatefulWidget {
  const PatientAppointmentsPage({super.key});

  @override
  State<PatientAppointmentsPage> createState() =>
      _PatientAppointmentsPageState();
}

class _PatientAppointmentsPageState extends State<PatientAppointmentsPage> {
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
              'id, appointment_date, status, note, doctor_id, doctor_response_note')
          .eq('patient_id', user!.id)
          .order('appointment_date', ascending: false);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Randevularım"),
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
                        leading: const Icon(Icons.calendar_month),
                        title: Text("Durum: ${buildStatusText(item['status'])}"),
                        subtitle: Text(
                          "Tarih: ${formatDateTime(item['appointment_date'])}\n"
                          "Hasta Notu: ${item['note'] ?? ''}\n"
                          "Doktor Notu: ${item['doctor_response_note'] ?? ''}",
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
