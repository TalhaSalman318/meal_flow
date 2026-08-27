import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class MenuImageService {
  MenuImageService._();

  static SupabaseClient get _client => SupabaseService.client;
  static const bucket = 'menu-images';

  static Future<String> upload(XFile file) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Your session has expired.');

    final extension = file.name.split('.').last.toLowerCase();
    const allowed = {'jpg', 'jpeg', 'png', 'webp'};
    if (!allowed.contains(extension)) {
      throw const FormatException('Choose a JPG, PNG, or WEBP image.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty)
      throw const FormatException('The selected image is empty.');
    if (bytes.length > 8 * 1024 * 1024) {
      throw const FormatException('Images must be 8 MB or smaller.');
    }

    final path =
        '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$extension';
    await _client.storage
        .from(bucket)
        .uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(
            contentType: _contentType(extension),
            upsert: false,
          ),
        );
    final url = _client.storage.from(bucket).getPublicUrl(path).trim();
    if (url.isEmpty) throw StateError('The uploaded image has no URL.');
    return url;
  }

  static String _contentType(String extension) =>
      extension == 'jpg' || extension == 'jpeg'
      ? 'image/jpeg'
      : 'image/$extension';
}
