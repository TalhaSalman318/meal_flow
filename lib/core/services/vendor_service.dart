import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class VendorService {
  VendorService._();

  static SupabaseClient get _client => SupabaseService.client;

  static Future<Map<String, dynamic>?> getCurrentVendor() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return null;
    }

    return _client
        .from('vendors')
        .select('''
          id,
          profile_id,
          vendor_code,
          vendor_name,
          contact_person,
          phone,
          email,
          status
        ''')
        .eq('profile_id', user.id)
        .maybeSingle();
  }

  static Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return null;
    }

    return _client
        .from('profiles')
        .select('id, email, full_name, role, status')
        .eq('id', user.id)
        .maybeSingle();
  }
}
