import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static late final SupabaseClient client;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    await Supabase.initialize(
      url: 'https://xhqndcvspzmfckhpbbtf.supabase.co',
      publishableKey: 'sb_publishable_QaEoXoHkml1q8BiJ0DGHDg_VyvuIv1k',
    );

    client = Supabase.instance.client;
    _initialized = true;
  }
}
