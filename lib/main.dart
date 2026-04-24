import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://uxajmerljjkgdiewelkz.supabase.co',
    anonKey: 'sb_publishable_TP0P1JEKdp3uHh4NeKoePQ_xHwl8N92',
  );

  runApp(const MyApp());
}
