import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_gradients.dart';
import '../../providers/employee_provider.dart';

class EmployeeHomeView extends StatefulWidget {
  const EmployeeHomeView({super.key});

  @override
  State<EmployeeHomeView> createState() => _EmployeeHomeViewState();
}

class _EmployeeHomeViewState extends State<EmployeeHomeView> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<EmployeeProvider>().loadEmployeeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child:
              provider.isLoading ||
                  (!provider.hasData && provider.errorMessage == null)
              ? const Center(child: CircularProgressIndicator())
              : provider.errorMessage != null
              ? _buildError(provider)
              : _buildHome(provider),
        ),
      ),
    );
  }

  // ============================================================
  // HOME
  // ============================================================

  Widget _buildHome(EmployeeProvider provider) {
    final profile = provider.profile!;
    final employee = provider.employee!;

    return RefreshIndicator(
      onRefresh: provider.loadEmployeeData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10.h),

            // ==================================================
            // HEADER
            // ==================================================
            Text(
              'Good Morning 👋',
              style: TextStyle(fontSize: 15.sp, color: AppColors.textSecondary),
            ),

            SizedBox(height: 5.h),

            Text(
              profile.fullName,
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            SizedBox(height: 5.h),

            Text(
              employee.designation ?? employee.department ?? 'Employee',
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
            ),

            SizedBox(height: 24.h),

            // ==================================================
            // EMPLOYEE CARD
            // ==================================================
            _employeeCard(employee),

            SizedBox(height: 20.h),

            // ==================================================
            // TODAY'S MEAL
            // ==================================================
            Text(
              "Today's Meal",
              style: TextStyle(
                fontSize: 19.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            SizedBox(height: 12.h),

            _mealCard(provider),

            SizedBox(height: 20.h),

            // ==================================================
            // QUICK INFO
            // ==================================================
            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    title: 'Subscription',
                    value: 'Active',
                    icon: Icons.autorenew_rounded,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _infoCard(
                    title: 'Balance',
                    value: 'Rs. 0',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
              ],
            ),

            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPLOYEE CARD
  // ============================================================

  Widget _employeeCard(dynamic employee) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: AppGradients.gold,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            blurRadius: 25.r,
            spreadRadius: 1.r,
            color: AppColors.primary.withValues(alpha: 0.20),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 55.w,
            height: 55.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.badge_outlined, size: 28.sp, color: Colors.white),
          ),

          SizedBox(width: 15.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Employee ID',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withValues(alpha: 0.80),
                  ),
                ),

                SizedBox(height: 3.h),

                Text(
                  employee.employeeCode,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 4.h),

                Text(
                  employee.department ?? 'No Department',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MEAL CARD
  // ============================================================

  Widget _mealCard(EmployeeProvider provider) {
    final menu = provider.todaysMenu;
    final imageUrl = menu?['image_url'] as String?;
    final hasImage = imageUrl != null && imageUrl.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 58.w,
            height: 58.w,
            decoration: BoxDecoration(
              gradient: AppGradients.gold,
              borderRadius: BorderRadius.circular(17.r),
            ),
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(17.r),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.restaurant_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  )
                : Icon(
                    Icons.restaurant_rounded,
                    color: Colors.white,
                    size: 30.sp,
                  ),
          ),

          SizedBox(width: 15.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  menu?['title'] as String? ?? 'No Menu Available',
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                SizedBox(height: 5.h),

                Text(
                  menu == null
                      ? 'No menu has been added for today.'
                      : ((menu['description'] as String?)?.trim().isNotEmpty ??
                            false)
                      ? (menu['description'] as String).trim()
                      : "Today's lunch menu",
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Text(
            'Rs. 400',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO CARD
  // ============================================================

  Widget _infoCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24.sp, color: AppColors.primary),

          SizedBox(height: 12.h),

          Text(
            title,
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),

          SizedBox(height: 4.h),

          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError(EmployeeProvider provider) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 55.sp,
              color: AppColors.primary,
            ),

            SizedBox(height: 15.h),

            Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15.sp, color: AppColors.textPrimary),
            ),

            SizedBox(height: 20.h),

            ElevatedButton(
              onPressed: provider.loadEmployeeData,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
