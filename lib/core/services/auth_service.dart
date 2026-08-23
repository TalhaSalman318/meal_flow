import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class AuthService {
  AuthService._();

  static SupabaseClient get _client => SupabaseService.client;

  // ============================================================
  // LOGIN
  // ============================================================

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ============================================================
  // SIGNUP
  // ============================================================

  static Future<AuthResponse> signUp({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? department,
    String? designation,
    String? phone,
    String? vendorCode,
    String? vendorName,
    String? contactPerson,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = fullName.trim();
    final cleanRole = role.trim().toUpperCase();

    if (cleanName.isEmpty) {
      throw const AuthException('Full name is required.');
    }

    if (cleanEmail.isEmpty) {
      throw const AuthException('Email is required.');
    }

    if (password.length < 6) {
      throw const AuthException(
        'Password must be at least 6 characters.',
        code: 'weak_password',
      );
    }

    if (cleanRole != 'EMPLOYEE' && cleanRole != 'VENDOR') {
      throw const AuthException('Invalid account type.');
    }

    if (kDebugMode) {
      debugPrint('==============================================');
      debugPrint('[MealFlow Signup] START');
      debugPrint('[MealFlow Signup] email=$cleanEmail');
      debugPrint('[MealFlow Signup] role=$cleanRole');
      debugPrint('==============================================');
    }

    // ==========================================================
    // 1. CREATE AUTH USER
    // ==========================================================

    final response = await _client.auth.signUp(
      email: cleanEmail,
      password: password,
    );

    final user = response.user;

    if (user == null) {
      throw const AuthException('Unable to create account.');
    }

    if (kDebugMode) {
      debugPrint('[MealFlow Signup] Auth user created: ${user.id}');
    }

    // ==========================================================
    // 2. SESSION CHECK
    // ==========================================================

    final session = response.session;

    if (session == null) {
      if (kDebugMode) {
        debugPrint('[MealFlow Signup] ERROR: session is null.');
      }

      throw const AuthException(
        'Account created, but signup session is not available. '
        'If email confirmation is enabled in Supabase, confirm the email first.',
        code: 'session_missing',
      );
    }

    if (kDebugMode) {
      debugPrint('[MealFlow Signup] Session available.');
    }

    // ==========================================================
    // 3. PROFILE
    // ==========================================================

    try {
      final existingProfile = await _client
          .from('profiles')
          .select('id, email, full_name, role')
          .eq('id', user.id)
          .maybeSingle();

      if (existingProfile == null) {
        await _client.from('profiles').insert({
          'id': user.id,
          'full_name': cleanName,
          'email': cleanEmail,
          'role': cleanRole,
          'status': 'ACTIVE',
        });

        if (kDebugMode) {
          debugPrint('[MealFlow Signup] Profile INSERT successful.');
        }
      } else {
        if (kDebugMode) {
          debugPrint('[MealFlow Signup] Profile already exists.');
        }
      }

      // Verify profile.
      final profileCheck = await _client
          .from('profiles')
          .select('id, email, full_name, role')
          .eq('id', user.id)
          .maybeSingle();

      if (profileCheck == null) {
        throw const AuthException(
          'Profile could not be verified.',
          code: 'signup_profile_failed',
        );
      }

      if (kDebugMode) {
        debugPrint('[MealFlow Signup] Profile verified: $profileCheck');
      }
    } on PostgrestException catch (error) {
      if (kDebugMode) {
        debugPrint('[MealFlow Signup] PROFILE ERROR');
        debugPrint('message="${error.message}"');
        debugPrint('code=${error.code}');
        debugPrint('details="${error.details}"');
        debugPrint('hint="${error.hint}"');
      }

      throw const AuthException(
        'Profile creation failed.',
        code: 'signup_profile_failed',
      );
    }

    // ==========================================================
    // 4. EMPLOYEE
    // ==========================================================

    if (cleanRole == 'EMPLOYEE') {
      try {
        if (kDebugMode) {
          debugPrint('[MealFlow Signup] Creating employee record...');
        }

        // Check whether employee already exists.
        final existingEmployee = await _client
            .from('employees')
            .select('id, employee_code, profile_id')
            .eq('profile_id', user.id)
            .maybeSingle();

        // ------------------------------------------------------
        // INSERT EMPLOYEE
        // ------------------------------------------------------

        if (existingEmployee == null) {
          //
          // IMPORTANT:
          //
          // employee_code is NOT sent from Flutter.
          //
          // Supabase trigger:
          //
          // employees_generate_code
          //
          // automatically generates:
          //
          // EMP001
          // EMP002
          // EMP003
          // EMP004
          // EMP005
          // ...
          //

          final insertedEmployee = await _client
              .from('employees')
              .insert({
                'profile_id': user.id,
                'department': _nullableText(department),
                'designation': _nullableText(designation),
                'phone': _nullableText(phone),
                'status': 'ACTIVE',
              })
              .select(
                'id, profile_id, employee_code, department, designation, phone, status',
              )
              .single();

          if (kDebugMode) {
            debugPrint('[MealFlow Signup] Employee INSERT successful.');

            debugPrint('[MealFlow Signup] Employee data: $insertedEmployee');
          }
        } else {
          if (kDebugMode) {
            debugPrint(
              '[MealFlow Signup] Employee already exists: '
              '$existingEmployee',
            );
          }
        }

        // ------------------------------------------------------
        // VERIFY EMPLOYEE
        // ------------------------------------------------------

        final employeeCheck = await _client
            .from('employees')
            .select(
              'id, profile_id, employee_code, department, designation, phone, status',
            )
            .eq('profile_id', user.id)
            .single();

        final employeeCode = employeeCheck['employee_code'];

        if (employeeCode == null || employeeCode.toString().trim().isEmpty) {
          throw const AuthException(
            'Employee record was created but employee code was not generated.',
            code: 'signup_employee_failed',
          );
        }

        if (kDebugMode) {
          debugPrint('==============================================');

          debugPrint('[MealFlow Signup] EMPLOYEE CREATED SUCCESSFULLY');

          debugPrint('[MealFlow Signup] employee_id=${employeeCheck['id']}');

          debugPrint('[MealFlow Signup] employee_code=$employeeCode');

          debugPrint(
            '[MealFlow Signup] profile_id=${employeeCheck['profile_id']}',
          );

          debugPrint(
            '[MealFlow Signup] department=${employeeCheck['department']}',
          );

          debugPrint(
            '[MealFlow Signup] designation=${employeeCheck['designation']}',
          );

          debugPrint('==============================================');
        }
      } on PostgrestException catch (error) {
        if (kDebugMode) {
          debugPrint('==============================================');

          debugPrint('[MealFlow Signup] EMPLOYEE INSERT ERROR');

          debugPrint('message="${error.message}"');

          debugPrint('code=${error.code}');

          debugPrint('details="${error.details}"');

          debugPrint('hint="${error.hint}"');

          debugPrint('==============================================');
        }

        throw const AuthException(
          'Employee record could not be created.',
          code: 'signup_employee_failed',
        );
      }
    }

    // ==========================================================
    // 5. VENDOR
    // ==========================================================

    if (cleanRole == 'VENDOR') {
      if (vendorCode == null || vendorCode.trim().isEmpty) {
        throw const AuthException('Vendor code is required.');
      }

      if (vendorName == null || vendorName.trim().isEmpty) {
        throw const AuthException('Vendor name is required.');
      }

      try {
        final existingVendor = await _client
            .from('vendors')
            .select('id, vendor_code, profile_id')
            .eq('profile_id', user.id)
            .maybeSingle();

        if (existingVendor == null) {
          final insertedVendor = await _client
              .from('vendors')
              .insert({
                'profile_id': user.id,
                'vendor_code': vendorCode.trim(),
                'vendor_name': vendorName.trim(),
                'contact_person': _nullableText(contactPerson),
                'phone': _nullableText(phone),
                'email': cleanEmail,
                'status': 'ACTIVE',
              })
              .select(
                'id, profile_id, vendor_code, vendor_name, contact_person, phone, email, status',
              )
              .single();

          if (kDebugMode) {
            debugPrint('[MealFlow Signup] Vendor INSERT successful.');

            debugPrint('[MealFlow Signup] Vendor data: $insertedVendor');
          }
        } else {
          if (kDebugMode) {
            debugPrint(
              '[MealFlow Signup] Vendor already exists: '
              '$existingVendor',
            );
          }
        }

        // Verify vendor.
        final vendorCheck = await _client
            .from('vendors')
            .select(
              'id, profile_id, vendor_code, vendor_name, contact_person, phone, email, status',
            )
            .eq('profile_id', user.id)
            .single();

        if (kDebugMode) {
          debugPrint('[MealFlow Signup] Vendor verified: $vendorCheck');
        }
      } on PostgrestException catch (error) {
        if (kDebugMode) {
          debugPrint('==============================================');

          debugPrint('[MealFlow Signup] VENDOR INSERT ERROR');

          debugPrint('message="${error.message}"');

          debugPrint('code=${error.code}');

          debugPrint('details="${error.details}"');

          debugPrint('hint="${error.hint}"');

          debugPrint('==============================================');
        }

        throw const AuthException(
          'Vendor record could not be created.',
          code: 'signup_vendor_failed',
        );
      }
    }

    // ==========================================================
    // COMPLETE SUCCESS
    // ==========================================================

    if (kDebugMode) {
      debugPrint('==============================================');

      debugPrint('[MealFlow Signup] COMPLETE SUCCESS');

      debugPrint('[MealFlow Signup] user_id=${user.id}');

      debugPrint('[MealFlow Signup] role=$cleanRole');

      debugPrint('==============================================');
    }

    return response;
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ============================================================
  // CURRENT SESSION
  // ============================================================

  static Session? get session {
    return _client.auth.currentSession;
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  static User? get currentUser {
    return _client.auth.currentUser;
  }

  // ============================================================
  // HELPER
  // ============================================================

  static String? _nullableText(String? value) {
    final text = value?.trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }
}
