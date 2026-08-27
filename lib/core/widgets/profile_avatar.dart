import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_gradients.dart';
import '../../models/profile_model.dart';

class ProfileAvatar extends StatelessWidget {
  final ProfileModel? profile;
  final VoidCallback? onTap;
  final double? size;

  const ProfileAvatar({
    super.key,
    required this.profile,
    this.onTap,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: 'Profile',
      padding: EdgeInsets.zero,
      icon: Container(
        width: (size ?? 42).w,
        height: (size ?? 42).w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: AppGradients.gold,
          shape: BoxShape.circle,
        ),
        child: Text(
          _initials(profile),
          style: TextStyle(
            fontSize: (size ?? 42) >= 70 ? 24.sp : 14.sp,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  static String _initials(ProfileModel? profile) {
    final source = (profile?.fullName.trim().isNotEmpty ?? false)
        ? profile!.fullName.trim()
        : (profile?.email ?? '').trim();
    if (source.isEmpty) return 'U';
    final parts = source.split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return source.substring(0, source.length > 1 ? 2 : 1).toUpperCase();
  }
}
