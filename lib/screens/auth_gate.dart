import 'package:flutter/material.dart';

import '../core/supabase_client.dart';
import 'dashboard_page.dart';
import 'home_page.dart';

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
