import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://uxajmerljjkgdiewelkz.supabase.co',
    anonKey: 'sb_publishable_TP0P1JEKdp3uHh4NeKoePQ_xHwl8N92',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

String formatDateTime(dynamic value) {
  if (value == null) return '-';
  final dt = DateTime.tryParse(value.toString())?.toLocal();
  if (dt == null) return value.toString();
  return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Klinik App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;
    if (session != null) {
      return const DashboardPage();
    }
    return const HomePage();
  }
}

Future<void> addLog({
  required String action,
  required String details,
}) async {
  final user = supabase.auth.currentUser;
  await supabase.from('logs').insert({
    'user_id': user?.id,
    'action': action,
    'details': details,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool isRegisterMode = false;
  String selectedRole = 'patient';

  Future<void> signIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage('Email ve şifre boş olamaz');
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        await addLog(
          action: 'LOGIN',
          details: '$email giriş yaptı',
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      }
    } catch (e) {
      showMessage('Giriş hatası: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> signUp() async {
    final fullName = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      showMessage('Tüm alanları doldurun');
      return;
    }

    if (password.length < 6) {
      showMessage('Şifre en az 6 karakter olmalı');
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (res.user != null) {
        await supabase.from('profiles').upsert({
          'id': res.user!.id,
          'full_name': fullName,
          'email': email,
          'role': selectedRole,
        });

        await addLog(
          action: 'REGISTER',
          details: '$email kayıt oldu. Rol: $selectedRole',
        );

        if (!mounted) return;
        showMessage("Kayıt başarılı! Şimdi giriş yapabilirsiniz.");

        setState(() {
          isRegisterMode = false;
          nameController.clear();
          passwordController.clear();
        });
      }
    } catch (e) {
      showMessage('Kayıt hatası: $e');
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
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = isRegisterMode ? "Kayıt Ol" : "Giriş Yap";

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 140,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Klinik Randevu Sistemi",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              if (isRegisterMode) ...[
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Ad Soyad",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Şifre",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (isRegisterMode) ...[
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Rol Seç',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'patient',
                      child: Text('Hasta'),
                    ),
                    DropdownMenuItem(
                      value: 'doctor',
                      child: Text('Doktor'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => selectedRole = v);
                  },
                ),
                const SizedBox(height: 20),
              ] else
                const SizedBox(height: 8),
              ElevatedButton(
                onPressed: isLoading ? null : (isRegisterMode ? signUp : signIn),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: isLoading
                    ? const CircularProgressIndicator()
                    : Text(isRegisterMode ? "Kayıt Ol" : "Giriş Yap"),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                  setState(() {
                    isRegisterMode = !isRegisterMode;
                    nameController.clear();
                    passwordController.clear();
                  });
                },
                child: Text(
                  isRegisterMode
                      ? "Zaten hesabın var mı? Giriş yap"
                      : "Hesabın yok mu? Kayıt ol",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? profile;
  bool isLoading = true;
  int notificationCount = 0;

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  Future<void> loadAll() async {
    await loadProfile();
    await loadNotificationCount();
  }

  Future<void> loadProfile() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      final data =
      await supabase.from('profiles').select().eq('id', user.id).maybeSingle();

      setState(() {
        profile = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> loadNotificationCount() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_read', false);

      setState(() {
        notificationCount = data.length;
      });
    } catch (e) {
      // sessiz geç
    }
  }

  String get roleText {
    final role = profile?['role'];
    if (role == 'doctor') return 'Doktor';
    if (role == 'patient') return 'Hasta';
    return 'Belirsiz';
  }

  Future<void> signOut() async {
    final email = supabase.auth.currentUser?.email ?? '';

    await addLog(
      action: 'LOGOUT',
      details: '$email çıkış yaptı',
    );

    await supabase.auth.signOut();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ana Sayfa"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: signOut,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Klinik Randevu Sistemine Hoş Geldiniz",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text("Ad Soyad"),
                    subtitle: Text(profile?['full_name'] ?? 'Bulunamadı'),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text("Email"),
                    subtitle: Text(user?.email ?? 'Bulunamadı'),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.badge),
                    title: const Text("Rol"),
                    subtitle: Text(roleText),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfilePage(),
                      ),
                    );
                    await loadProfile();
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text("Profilim"),
                ),
                const SizedBox(height: 10),
                if (profile?['role'] == 'patient') ...[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateAppointmentPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text("Randevu Oluştur"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PatientAppointmentsPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text("Randevularım"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PatientExaminationsPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text("Muayene Geçmişim"),
                  ),
                  const SizedBox(height: 100),
                ],
                if (profile?['role'] == 'doctor') ...[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DoctorAppointmentsPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text("Bana Gelen Randevular"),
                  ),
                ],
              ],
            ),
          ),
          if (profile?['role'] == 'patient')
            Positioned(
              right: 20,
              bottom: 20,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  FloatingActionButton(
                    shape: const CircleBorder(),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsPage(),
                        ),
                      );
                      await loadNotificationCount();
                    },
                    child: const Icon(Icons.notifications),
                  ),
                  if (notificationCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                        child: Text(
                          notificationCount > 99
                              ? '99+'
                              : notificationCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? profile;
  bool isLoading = true;
  bool isEditMode = false;
  bool isSaving = false;

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      final data =
      await supabase.from('profiles').select().eq('id', user.id).maybeSingle();

      fullNameController.text = data?['full_name'] ?? '';
      emailController.text = user.email ?? data?['email'] ?? '';

      setState(() {
        profile = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  String get roleText {
    final role = profile?['role'];
    if (role == 'doctor') return 'Doktor';
    if (role == 'patient') return 'Hasta';
    return 'Belirsiz';
  }

  Future<void> saveProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();

    if (fullName.isEmpty || email.isEmpty) {
      showMessage('Ad soyad ve email boş olamaz');
      return;
    }

    setState(() => isSaving = true);

    try {
      await supabase.from('profiles').update({
        'full_name': fullName,
        'email': email,
      }).eq('id', user.id);

      if (user.email != email) {
        await supabase.auth.updateUser(
          UserAttributes(email: email),
        );
      }

      await addLog(
        action: 'UPDATE_PROFILE',
        details: 'Profil bilgileri güncellendi',
      );

      if (!mounted) return;

      showMessage('Profil başarıyla güncellendi');

      setState(() {
        profile = {
          ...?profile,
          'full_name': fullName,
          'email': email,
        };
        isEditMode = false;
      });
    } catch (e) {
      showMessage('Hata: $e');
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
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
    fullNameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final fullName = profile?['full_name'] ?? 'Bulunamadı';
    final email = user?.email ?? profile?['email'] ?? 'Bulunamadı';
    final createdAt = formatDateTime(profile?['created_at']);
    final userId = user?.id ?? profile?['id'] ?? '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profilim"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: isSaving
                ? null
                : () {
              setState(() {
                isEditMode = !isEditMode;
                if (!isEditMode) {
                  fullNameController.text = profile?['full_name'] ?? '';
                  emailController.text =
                      user?.email ?? profile?['email'] ?? '';
                }
              });
            },
            icon: Icon(isEditMode ? Icons.close : Icons.edit),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 45,
              child: Text(
                fullName.toString().isNotEmpty
                    ? fullName.toString()[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              fullName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            if (isEditMode) ...[
              TextField(
                controller: fullNameController,
                decoration: const InputDecoration(
                  labelText: "Ad Soyad",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: isSaving ? null : saveProfile,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: isSaving
                    ? const CircularProgressIndicator()
                    : const Text("Kaydet"),
              ),
              const SizedBox(height: 20),
            ],
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text("Ad Soyad"),
                subtitle: Text(fullName),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text("Email"),
                subtitle: Text(email),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text("Rol"),
                subtitle: Text(roleText),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text("Kayıt Tarihi"),
                subtitle: Text(createdAt),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.fingerprint),
                title: const Text("Kullanıcı ID"),
                subtitle: Text(userId),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      final data = await supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        notifications = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> openNotification(Map item) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true}).eq('id', item['id']);

      await supabase.from('notifications').delete().eq('id', item['id']);

      if (!mounted) return;

      setState(() {
        notifications.removeWhere((n) => n['id'] == item['id']);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(item['message'] ?? 'Bildirim açıldı')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bildirimlerim"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? const Center(child: Text("Bildirim yok"))
          : ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final item = notifications[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_active),
              title: Text(item['title'] ?? 'Bildirim'),
              subtitle: Text(item['message'] ?? ''),
              onTap: () => openNotification(item),
            ),
          );
        },
      ),
    );
  }
}

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