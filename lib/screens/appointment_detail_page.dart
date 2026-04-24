import 'package:flutter/material.dart';

import '../core/supabase_client.dart';
import '../core/utils.dart';
import '../services/log_service.dart';
import 'examination_form_page.dart';

class AppointmentDetailPage extends StatefulWidget {
  final Map appointment;

  const AppointmentDetailPage({super.key, required this.appointment});

  @override
  State<AppointmentDetailPage> createState() => _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends State<AppointmentDetailPage> {
  final noteController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    noteController.text = widget.appointment['doctor_response_note'] ?? '';
  }

  Future<void> updateStatus(String status) async {
    setState(() => isLoading = true);

    try {
      await supabase.from('appointments').update({
        'status': status,
        'doctor_response_note': noteController.text.trim(),
      }).eq('id', widget.appointment['id']);

      String message = '';
      if (status == 'onaylandı') {
        message = 'Doktorunuz randevunuzu onayladı.';
      } else if (status == 'reddedildi') {
        message = 'Doktorunuz randevunuzu reddetti.';
      } else if (status == 'iptal') {
        message = 'Doktorunuz randevunuzu iptal etti.';
      } else if (status == 'tamamlandı') {
        message = 'Randevunuz tamamlandı.';
      } else {
        message = 'Randevunuz güncellendi.';
      }

      await supabase.from('notifications').insert({
        'user_id': widget.appointment['patient_id'],
        'title': 'Randevu Durumu',
        'message': message,
        'is_read': false,
      });

      await addLog(
        action: 'UPDATE_APPOINTMENT',
        details: 'Randevu $status yapıldı',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("İşlem başarılı")),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
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
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.appointment;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Randevu Detayı"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.info),
                title: const Text("Durum"),
                subtitle: Text(buildStatusText(item['status'])),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text("Tarih"),
                subtitle: Text(formatDateTime(item['appointment_date'])),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.notes),
                title: const Text("Hasta Notu"),
                subtitle: Text(item['note'] ?? ''),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Doktor Notu",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : () => updateStatus('onaylandı'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text("Onayla"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: isLoading ? null : () => updateStatus('reddedildi'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text("Reddet"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: isLoading ? null : () => updateStatus('iptal'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text("İptal Et"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ExaminationFormPage(appointment: widget.appointment),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text("Muayene Notu Ekle / Güncelle"),
            ),
          ],
        ),
      ),
    );
  }
}
