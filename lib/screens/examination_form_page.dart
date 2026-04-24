import 'package:flutter/material.dart';

import '../core/supabase_client.dart';
import '../core/utils.dart';
import '../services/log_service.dart';

class ExaminationFormPage extends StatefulWidget {
  final Map appointment;

  const ExaminationFormPage({super.key, required this.appointment});

  @override
  State<ExaminationFormPage> createState() => _ExaminationFormPageState();
}

class _ExaminationFormPageState extends State<ExaminationFormPage> {
  final complaintController = TextEditingController();
  final diagnosisController = TextEditingController();
  final treatmentController = TextEditingController();

  bool isLoading = true;
  int? examinationId;

  @override
  void initState() {
    super.initState();
    loadExistingExamination();
  }

  Future<void> loadExistingExamination() async {
    try {
      final data = await supabase
          .from('examinations')
          .select()
          .eq('appointment_id', widget.appointment['id'])
          .maybeSingle();

      if (data != null) {
        examinationId = data['id'];
        complaintController.text = data['complaint'] ?? '';
        diagnosisController.text = data['diagnosis'] ?? '';
        treatmentController.text = data['treatment'] ?? '';
      }
    } catch (e) {
      // sessiz geç
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> saveExamination() async {
    final complaint = complaintController.text.trim();
    final diagnosis = diagnosisController.text.trim();
    final treatment = treatmentController.text.trim();

    if (complaint.isEmpty || diagnosis.isEmpty || treatment.isEmpty) {
      showMessage('Tüm alanları doldurun');
      return;
    }

    setState(() => isLoading = true);

    try {
      if (examinationId == null) {
        final inserted = await supabase
            .from('examinations')
            .insert({
              'appointment_id': widget.appointment['id'],
              'patient_id': widget.appointment['patient_id'],
              'doctor_id': widget.appointment['doctor_id'],
              'complaint': complaint,
              'diagnosis': diagnosis,
              'treatment': treatment,
            })
            .select()
            .single();

        examinationId = inserted['id'];

        await supabase.from('notifications').insert({
          'user_id': widget.appointment['patient_id'],
          'title': 'Muayene Notu',
          'message': 'Doktorunuz muayene notunuzu sisteme ekledi.',
          'is_read': false,
        });

        await addLog(
          action: 'CREATE_EXAMINATION',
          details: 'Muayene notu eklendi',
        );
      } else {
        await supabase.from('examinations').update({
          'complaint': complaint,
          'diagnosis': diagnosis,
          'treatment': treatment,
        }).eq('id', examinationId!);

        await supabase.from('notifications').insert({
          'user_id': widget.appointment['patient_id'],
          'title': 'Muayene Notu Güncellendi',
          'message': 'Doktorunuz muayene notunuzu güncelledi.',
          'is_read': false,
        });

        await addLog(
          action: 'UPDATE_EXAMINATION',
          details: 'Muayene notu güncellendi',
        );
      }

      await supabase.from('appointments').update({
        'status': 'tamamlandı',
      }).eq('id', widget.appointment['id']);

      if (!mounted) return;
      showMessage('Muayene notu kaydedildi');
      Navigator.pop(context);
    } catch (e) {
      showMessage('Hata: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
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
    complaintController.dispose();
    diagnosisController.dispose();
    treatmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Muayene Notu"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text("Randevu Tarihi"),
                      subtitle:
                          Text(formatDateTime(widget.appointment['appointment_date'])),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: complaintController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Şikayet',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: diagnosisController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Tanı',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: treatmentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Tedavi / Öneri',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isLoading ? null : saveExamination,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text("Kaydet"),
                  ),
                ],
              ),
            ),
    );
  }
}
