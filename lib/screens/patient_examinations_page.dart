import 'package:flutter/material.dart';

import '../core/supabase_client.dart';
import '../core/utils.dart';

class PatientExaminationsPage extends StatefulWidget {
  const PatientExaminationsPage({super.key});

  @override
  State<PatientExaminationsPage> createState() =>
      _PatientExaminationsPageState();
}

class _PatientExaminationsPageState extends State<PatientExaminationsPage> {
  List examinations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadExaminations();
  }

  Future<void> loadExaminations() async {
    try {
      final user = supabase.auth.currentUser;

      final data = await supabase
          .from('examinations')
          .select(
              'id, complaint, diagnosis, treatment, created_at, appointment_id')
          .eq('patient_id', user!.id)
          .order('created_at', ascending: false);

      setState(() {
        examinations = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Muayene Geçmişim"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : examinations.isEmpty
              ? const Center(child: Text("Henüz muayene kaydı yok"))
              : ListView.builder(
                  itemCount: examinations.length,
                  itemBuilder: (context, index) {
                    final item = examinations[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Tarih: ${formatDateTime(item['created_at'])}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text("Şikayet: ${item['complaint'] ?? ''}"),
                            const SizedBox(height: 8),
                            Text("Tanı: ${item['diagnosis'] ?? ''}"),
                            const SizedBox(height: 8),
                            Text("Tedavi / Öneri: ${item['treatment'] ?? ''}"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
