import 'package:flutter/material.dart';

import '../core/supabase_client.dart';
import '../core/utils.dart';
import '../services/log_service.dart';

class CreateAppointmentPage extends StatefulWidget {
  const CreateAppointmentPage({super.key});

  @override
  State<CreateAppointmentPage> createState() =>
      _CreateAppointmentPageState();
}

class _CreateAppointmentPageState
    extends State<CreateAppointmentPage> {
  List doctors = [];
  List bookedSlots = [];

  String? selectedDoctorId;
  DateTime? selectedDate;
  String? selectedTime;

  final noteController = TextEditingController();

  bool isLoading = false;

  final List<String> timeSlots = [
    "09:00",
    "09:30",
    "10:00",
    "10:30",
    "11:00",
    "11:30",
    "12:00",
    "12:30",
    "13:00",
    "13:30",
    "14:00",
    "14:30",
    "15:00",
    "15:30",
    "16:00",
    "16:30",
  ];

  @override
  void initState() {
    super.initState();
    loadDoctors();
  }

  Future<void> loadDoctors() async {
    final res =
    await supabase.from('profiles').select().eq('role', 'doctor');

    setState(() => doctors = res);
  }

  Future<void> loadBookedSlots() async {
    if (selectedDoctorId == null || selectedDate == null) return;

    final start = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
    );

    final end = start.add(const Duration(days: 1));

    final data = await supabase
        .from('appointments')
        .select('appointment_date')
        .eq('doctor_id', selectedDoctorId!)
        .gte('appointment_date', start.toIso8601String())
        .lt('appointment_date', end.toIso8601String());

    bookedSlots = data.map<String>((item) {
      final dt = DateTime.parse(item['appointment_date']);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }).toList();

    setState(() {});
  }

  bool isWeekday(DateTime date) {
    final day = date.weekday;

    return day != DateTime.saturday &&
        day != DateTime.sunday;
  }

  Future<void> createAppointment() async {
    final user = supabase.auth.currentUser;

    if (selectedDoctorId == null ||
        selectedDate == null ||
        selectedTime == null) {
      showMessage("Doktor, tarih ve saat seçmelisiniz");
      return;
    }

    if (bookedSlots.contains(selectedTime)) {
      showMessage("Bu saat dolu");
      return;
    }

    final parts = selectedTime!.split(":");

    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final finalDate = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      hour,
      minute,
    );

    setState(() => isLoading = true);

    try {
      await supabase.from('appointments').insert({
        'patient_id': user!.id,
        'doctor_id': selectedDoctorId,
        'appointment_date': finalDate.toIso8601String(),
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
      showMessage("Bu saate başka randevu alınmış olabilir");
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

    if (!isWeekday(date)) {
      showMessage("Hafta sonu randevu alınamaz");
      return;
    }

    setState(() {
      selectedDate = date;
      selectedTime = null;
    });

    await loadBookedSlots();
  }

  String getSelectedDateText() {
    if (selectedDate == null) return "Tarih seç";

    return "${selectedDate!.day}.${selectedDate!.month}.${selectedDate!.year}";
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
              items:
              doctors.map<DropdownMenuItem<String>>((doc) {
                return DropdownMenuItem<String>(
                  value: doc['id'] as String,
                  child: Text(doc['full_name'] ?? ''),
                );
              }).toList(),
              onChanged: (value) async {
                setState(() {
                  selectedDoctorId = value;
                });

                await loadBookedSlots();
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
              child: Text(getSelectedDateText()),
            ),

            const SizedBox(height: 16),

            if (selectedDate != null)
              DropdownButtonFormField<String>(
                value: selectedTime,
                hint: const Text("Saat seç"),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: timeSlots.map((time) {
                  final isBooked =
                  bookedSlots.contains(time);

                  return DropdownMenuItem(
                    value: isBooked ? null : time,
                    enabled: !isBooked,
                    child: Text(
                      isBooked
                          ? "$time (Dolu)"
                          : time,
                      style: TextStyle(
                        color: isBooked
                            ? Colors.grey
                            : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedTime = value;
                  });
                },
              ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed:
              isLoading ? null : createAppointment,
              style: ElevatedButton.styleFrom(
                minimumSize:
                const Size(double.infinity, 48),
              ),
              child: const Text("Randevu Al"),
            ),
          ],
        ),
      ),
    );
  }
}