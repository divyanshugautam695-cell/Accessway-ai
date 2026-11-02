import 'package:supabase_flutter/supabase_flutter.dart';

/// Supply these at build time. Never commit a Supabase secret/service-role key.
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

bool get supabaseConfigured =>
    supabaseUrl.startsWith('https://') &&
    supabasePublishableKey.isNotEmpty;

Future<void> initializeBackend() async {
  if (!supabaseConfigured) return;
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
}
