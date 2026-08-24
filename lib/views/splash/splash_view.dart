import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../providers/profile_provider.dart';
import 'package:provider/provider.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();

    _redirectTimer = Timer(const Duration(seconds: 2), _redirect);
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  Future<void> _redirect() async {
    if (AuthService.session == null || AuthService.currentUser == null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    final profileProvider = context.read<ProfileProvider>();
    final profileLoaded = await profileProvider.loadProfile();

    if (!mounted) return;

    final profile = profileProvider.profile;
    if (!profileLoaded || profile == null || !profile.isActive) {
      await AuthService.signOut();

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    final destination = profile.isEmployee
        ? AppRoutes.employeeHome
        : profile.isVendor
        ? AppRoutes.vendorDashboard
        : AppRoutes.login;

    Navigator.pushReplacementNamed(context, destination);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.cream, AppColors.lightSage],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.restaurant_rounded,
                  size: 48.sp,
                  color: AppColors.primary,
                ),
              ),

              SizedBox(height: 24.h),

              Text(
                'MealFlow',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              SizedBox(height: 8.h),

              Text(
                'Smart meals. Simple workdays.',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
