import 'package:flutter/material.dart';

import '../core/supabase_client.dart';
import '../core/utils.dart';
import 'appointment_detail_page.dart';

class DoctorAppointmentsPage extends StatefulWidget {
  const DoctorAppointmentsPage({super.key});

  @override
  State<DoctorAppointmentsPage> createState() =>
      _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState
    extends State<DoctorAppointmentsPage> {
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
        'id, appointment_date, status, note, patient_id, doctor_id, doctor_response_note',
      )
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

  Widget buildInfoBox({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content.isEmpty ? "-" : content,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bana Gelen Randevular"),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : appointments.isEmpty
          ? const Center(
        child: Text("Henüz randevu yok"),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final item = appointments[index];

          final status =
              item['status'] ?? 'bekliyor';

          return GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AppointmentDetailPage(
                        appointment: item,
                      ),
                ),
              );

              await refreshAppointments();
            },
            child: Container(
              margin:
              const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      0.05,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor:
                        getStatusColor(status)
                            .withOpacity(0.15),
                        child: Icon(
                          getStatusIcon(status),
                          color:
                          getStatusColor(status),
                        ),
                      ),
                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            Text(
                              buildStatusText(
                                  status),
                              style:
                              const TextStyle(
                                fontSize: 18,
                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),

                            const SizedBox(
                                height: 4),

                            Text(
                              formatDateTime(
                                item[
                                'appointment_date'],
                              ),
                              style:
                              TextStyle(
                                color: Colors
                                    .grey
                                    .shade700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color:
                        Colors.grey.shade500,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  buildInfoBox(
                    title: "Hasta Notu",
                    content:
                    item['note'] ?? '',
                    icon: Icons.notes,
                  ),

                  buildInfoBox(
                    title: "Doktor Notu",
                    content: item[
                    'doctor_response_note'] ??
                        '',
                    icon: Icons.medical_information,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}