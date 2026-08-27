import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_gradients.dart';
import '../../core/services/empolyee_services.dart';
import '../../core/services/vendor_service.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/employee_model.dart';
import '../../models/profile_model.dart';
import '../../models/vendor_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/vendor/vendor_home_provider.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});
  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  EmployeeModel? _employee;
  VendorModel? _vendor;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final profileProvider = context.read<ProfileProvider>();
    if (profileProvider.profile == null) await profileProvider.loadProfile();
    final profile = profileProvider.profile;
    if (profile == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to load your profile.';
        });
      }
      return;
    }
    try {
      if (profile.isEmployee) {
        final data = await EmployeeService.getCurrentEmployee();
        if (data != null) _employee = EmployeeModel.fromMap(data);
      } else if (profile.isVendor) {
        final data = await VendorService.getCurrentVendor();
        if (data != null) _vendor = VendorModel.fromMap(data);
      }
    } catch (_) {
      _error = 'Unable to load profile details. Please try again.';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: _loading
            ? const SafeArea(child: _ProfileSkeleton())
            : profile == null || _error != null
            ? Center(child: Text(_error ?? 'Profile not found.'))
            : SafeArea(child: _content(profile)),
      ),
    );
  }

  Widget _content(ProfileModel profile) {
    final fields = <(String, String, IconData)>[
      ('Name', profile.fullName, Icons.person_outline_rounded),
      if (profile.isEmployee && _employee != null) ...[
        ('Employee code', _employee!.employeeCode, Icons.badge_outlined),
        if (_employee!.department != null)
          ('Department', _employee!.department!, Icons.apartment_outlined),
        if (_employee!.designation != null)
          ('Designation', _employee!.designation!, Icons.work_outline_rounded),
        if (_employee!.phone != null)
          ('Phone', _employee!.phone!, Icons.phone_outlined),
      ],
      if (profile.isVendor && _vendor != null) ...[
        ('Vendor code', _vendor!.vendorCode, Icons.storefront_outlined),
        ('Vendor name', _vendor!.vendorName, Icons.business_outlined),
        if (_vendor!.phone != null)
          ('Phone', _vendor!.phone!, Icons.phone_outlined),
        if (_vendor!.contactPerson != null)
          ('Contact', _vendor!.contactPerson!, Icons.person_outline),
      ],
      if (profile.email != null)
        ('Email', profile.email!, Icons.email_outlined),
      ('Role', profile.role, Icons.verified_user_outlined),
    ];
    return ListView(
      padding: EdgeInsets.all(20.w),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () => Navigator.maybePop(context),
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.textPrimary,
          ),
        ),
        Center(child: ProfileAvatar(profile: profile, size: 96)),
        SizedBox(height: 22.h),
        Center(
          child: Column(
            children: [
              Text(
                profile.fullName,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                profile.role,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 22.h),
        for (final field in fields) _field(field.$1, field.$2, field.$3),
        SizedBox(height: 28.h),
        OutlinedButton.icon(
          onPressed: _confirmSignOut,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign Out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
          ),
        ),
      ],
    );
  }

  Widget _field(String label, String value, IconData icon) => Container(
    margin: EdgeInsets.only(bottom: 10.h),
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(16.r),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    try {
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      context.read<ProfileProvider>().clearProfile();
      context.read<EmployeeProvider>().clearData();
      context.read<VendorHomeProvider>().clearData();
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to sign out. Please try again.'),
          ),
        );
      }
    }
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: ListView(
        padding: EdgeInsets.all(20.w),
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: SkeletonBox(width: 48, height: 48),
          ),
          SizedBox(height: 22.h),
          const Center(
            child: SkeletonBox(
              width: 96,
              height: 96,
              borderRadius: BorderRadius.all(Radius.circular(48)),
            ),
          ),
          SizedBox(height: 18.h),
          const Center(child: SkeletonBox(width: 170, height: 22)),
          SizedBox(height: 8.h),
          const Center(child: SkeletonBox(width: 80, height: 14)),
          SizedBox(height: 24.h),
          for (var index = 0; index < 6; index++) ...[
            const SkeletonBox(height: 70),
            SizedBox(height: 10.h),
          ],
        ],
      ),
    );
  }
}
