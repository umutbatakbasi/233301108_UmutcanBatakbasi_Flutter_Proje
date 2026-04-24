import 'package:flutter/material.dart';

import '../core/supabase_client.dart';
import '../core/utils.dart';
import '../services/log_service.dart';

class CreateAppointmentPage extends StatefulWidget {
  const CreateAppointmentPage({super.key});

  @override
  State<CreateAppointmentPage> createState() => _CreateAppointmentPageState();
}

class _CreateAppointmentPageState extends State<CreateAppointmentPage> {
  List doctors = [];
  String? selectedDoctorId;
  DateTime? selectedDate;
  final noteController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadDoctors();
  }

  Future<void> loadDoctors() async {
    final res = await supabase.from('profiles').select().eq('role', 'doctor');
    setState(() => doctors = res);
  }

  Future<void> createAppointment() async {
    final user = supabase.auth.currentUser;

    if (selectedDoctorId == null || selectedDate == null) {
      showMessage("Doktor ve tarih seçmelisiniz");
      return;
    }

    setState(() => isLoading = true);

    try {
      await supabase.from('appointments').insert({
        'patient_id': user!.id,
        'doctor_id': selectedDoctorId,
        'appointment_date': selectedDate!.toIso8601String(),
        'status': 'bekliyor',
        'note': noteController.text.trim(),
      });

      await addLog(
        action: 'CREATE_APPOINTMENT',
        details: 'Yeni randevu oluşturdu',
      );

      if (!mounted) return;
      showMessage("Randevu oluşturuldu");
      Navigator.pop(context);
    } catch (e) {
      showMessage("Hata: $e");
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

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Randevu Oluştur"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedDoctorId,
              hint: const Text("Doktor seç"),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: doctors.map<DropdownMenuItem<String>>((doc) {
                return DropdownMenuItem<String>(
                  value: doc['id'] as String,
                  child: Text(doc['full_name'] ?? ''),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDoctorId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Not',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: pickDate,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(
                selectedDate == null
                    ? 'Tarih ve saat seç'
                    : formatDateTime(selectedDate),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : createAppointment,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text("Randevu Al"),
            ),
          ],
        ),
      ),
    );
  }
}
