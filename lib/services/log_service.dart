import '../core/supabase_client.dart';

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
