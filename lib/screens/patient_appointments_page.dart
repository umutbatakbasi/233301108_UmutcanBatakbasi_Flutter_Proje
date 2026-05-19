import 'package:flutter/material.dart';

import '../core/supabase_client.dart';
import '../core/utils.dart';
import '../services/log_service.dart';

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
        'id, appointment_date, status, note, doctor_id, patient_id, doctor_response_note',
      )
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

  bool isPastAppointment(dynamic value) {
    final appointmentDate = DateTime.parse(value.toString()).toLocal();
    return appointmentDate.isBefore(DateTime.now());
  }

  bool canChangeAppointment(dynamic value) {
    final appointmentDate = DateTime.parse(value.toString()).toLocal();
    final now = DateTime.now();
    final difference = appointmentDate.difference(now);

    return difference.inHours >= 24;
  }

  String getButtonText(Map item) {
    if (isPastAppointment(item['appointment_date'])) {
      return "Geçmiş Randevu";
    }

    if (canChangeAppointment(item['appointment_date'])) {
      return "Randevuyu Değiştir";
    }

    return "24 Saatten Az Kaldı";
  }

  IconData getButtonIcon(Map item) {
    if (isPastAppointment(item['appointment_date'])) {
      return Icons.history;
    }

    if (canChangeAppointment(item['appointment_date'])) {
      return Icons.edit_calendar;
    }

    return Icons.lock_clock;
  }

  Future<void> openChangeAppointmentPage(Map appointment) async {
    if (isPastAppointment(appointment['appointment_date'])) {
      showMessage('Geçmiş randevular değiştirilemez.');
      return;
    }

    if (!canChangeAppointment(appointment['appointment_date'])) {
      showMessage(
        'Randevuya 24 saatten az kaldığı için randevu değiştirilemez.',
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeAppointmentPage(appointment: appointment),
      ),
    );

    if (result == true) {
      setState(() => isLoading = true);
      await loadAppointments();
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
            margin: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.calendar_month),
                    title: Text(
                      "Durum: ${buildStatusText(item['status'])}",
                    ),
                    subtitle: Text(
                      "Tarih: ${formatDateTime(item['appointment_date'])}\n"
                          "Hasta Notu: ${item['note'] ?? ''}\n"
                          "Doktor Notu: ${item['doctor_response_note'] ?? ''}",
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => openChangeAppointmentPage(item),
                    icon: Icon(getButtonIcon(item)),
                    label: Text(getButtonText(item)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                    ),
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

class ChangeAppointmentPage extends StatefulWidget {
  final Map appointment;

  const ChangeAppointmentPage({
    super.key,
    required this.appointment,
  });

  @override
  State<ChangeAppointmentPage> createState() => _ChangeAppointmentPageState();
}

class _ChangeAppointmentPageState extends State<ChangeAppointmentPage> {
  DateTime? selectedDate;
  String? selectedTime;
  List bookedSlots = [];
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

    final oldDate =
    DateTime.parse(widget.appointment['appointment_date'].toString())
        .toLocal();

    selectedDate = DateTime(
      oldDate.year,
      oldDate.month,
      oldDate.day,
    );

    selectedTime =
    "${oldDate.hour.toString().padLeft(2, '0')}:${oldDate.minute.toString().padLeft(2, '0')}";

    loadBookedSlots();
  }

  bool isWeekday(DateTime date) {
    final day = date.weekday;
    return day != DateTime.saturday && day != DateTime.sunday;
  }

  Future<void> loadBookedSlots() async {
    if (selectedDate == null) return;

    final doctorId = widget.appointment['doctor_id'];
    final appointmentId = widget.appointment['id'];

    final start = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
    );

    final end = start.add(const Duration(days: 1));

    final data = await supabase
        .from('appointments')
        .select('id, appointment_date')
        .eq('doctor_id', doctorId)
        .gte('appointment_date', start.toIso8601String())
        .lt('appointment_date', end.toIso8601String());

    bookedSlots = data
        .where((item) => item['id'] != appointmentId)
        .map<String>((item) {
      final dt = DateTime.parse(item['appointment_date']).toLocal();
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }).toList();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    if (!isWeekday(date)) {
      showMessage("Hafta sonu randevu alınamaz.");
      return;
    }

    setState(() {
      selectedDate = date;
      selectedTime = null;
    });

    await loadBookedSlots();
  }

  Future<void> updateAppointment() async {
    if (selectedDate == null || selectedTime == null) {
      showMessage("Yeni tarih ve saat seçmelisiniz.");
      return;
    }

    if (bookedSlots.contains(selectedTime)) {
      showMessage("Bu saat dolu. Lütfen farklı bir saat seçin.");
      return;
    }

    final oldDate =
    DateTime.parse(widget.appointment['appointment_date'].toString())
        .toLocal();

    final now = DateTime.now();
    final difference = oldDate.difference(now);

    if (oldDate.isBefore(now)) {
      showMessage("Geçmiş randevular değiştirilemez.");
      return;
    }

    if (difference.inHours < 24) {
      showMessage(
        "Randevuya 24 saatten az kaldığı için değişiklik yapılamaz.",
      );
      return;
    }

    final parts = selectedTime!.split(":");
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final newDate = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      hour,
      minute,
    );

    setState(() => isLoading = true);

    try {
      await supabase.from('appointments').update({
        'appointment_date': newDate.toIso8601String(),
        'status': 'bekliyor',
        'doctor_response_note': null,
      }).eq('id', widget.appointment['id']);

      await supabase.from('notifications').insert({
        'user_id': widget.appointment['doctor_id'],
        'title': 'Randevu Tarihi Değişti',
        'message':
        'Hasta randevu tarihini ${formatDateTime(newDate)} olarak değiştirdi.',
        'is_read': false,
      });

      await addLog(
        action: 'UPDATE_APPOINTMENT_DATE',
        details:
        'Hasta randevu tarihini ${formatDateTime(oldDate)} tarihinden ${formatDateTime(newDate)} tarihine değiştirdi',
      );

      if (!mounted) return;

      showMessage("Randevu tarihi güncellendi.");
      Navigator.pop(context, true);
    } catch (e) {
      showMessage(
        "Bu saate başka randevu alınmış olabilir. Lütfen farklı saat seçin.",
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String getSelectedDateText() {
    if (selectedDate == null) return "Tarih seç";
    return "${selectedDate!.day}.${selectedDate!.month}.${selectedDate!.year}";
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final oldDate = widget.appointment['appointment_date'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Randevu Değiştir"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.event),
                title: const Text("Mevcut Randevu"),
                subtitle: Text(formatDateTime(oldDate)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: pickDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(getSelectedDateText()),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 16),
            if (selectedDate != null)
              DropdownButtonFormField<String>(
                value: selectedTime,
                hint: const Text("Saat seç"),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Yeni Saat",
                ),
                items: timeSlots.map((time) {
                  final isBooked = bookedSlots.contains(time);

                  return DropdownMenuItem<String>(
                    value: time,
                    enabled: !isBooked,
                    child: Text(
                      isBooked ? "$time (Dolu)" : time,
                      style: TextStyle(
                        color: isBooked ? Colors.grey : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  if (bookedSlots.contains(value)) {
                    showMessage("Bu saat dolu.");
                    return;
                  }

                  setState(() {
                    selectedTime = value;
                  });
                },
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : updateAppointment,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Randevuyu Güncelle"),
            ),
          ],
        ),
      ),
    );
  }
}