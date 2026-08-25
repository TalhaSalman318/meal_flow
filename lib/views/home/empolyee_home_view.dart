import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_gradients.dart';
import '../../providers/auth_provider.dart';
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

            _mealHistoryCard(),

            SizedBox(height: 20.h),

            _guestMealCard(),

            SizedBox(height: 20.h),

            _monthlyMenuCard(),

            SizedBox(height: 20.h),

            _signOutButton(),

            SizedBox(height: 20.h),

            // ==================================================
            // QUICK INFO
            // ==================================================
            Row(
              children: [
                Expanded(child: _subscriptionCard(provider)),
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

  Widget _mealHistoryCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: () => Navigator.pushNamed(context, AppRoutes.mealHistory),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              color: AppColors.primary,
              size: 28.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meal History',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'View your monthly attendance',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _guestMealCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: () => Navigator.pushNamed(context, AppRoutes.guestMeal),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            Icon(Icons.person_add_alt_1, color: AppColors.primary, size: 28.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Guest Meals',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'Add and view guest meals',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthlyMenuCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: () => Navigator.pushNamed(context, AppRoutes.employeeMenus),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.menu_book_outlined,
              color: AppColors.primary,
              size: 28.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Menu',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'Browse menus by date',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _signOutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _confirmSignOut,
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Sign Out'),
      ),
    );
  }

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
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    try {
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      context.read<EmployeeProvider>().clearData();
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to sign out. Please try again.')),
      );
    }
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
    final meal = provider.todayMeal;
    final menu = provider.todaysMenu;
    final title = meal == null
        ? provider.subscriptionStatus == 'NOT SUBSCRIBED'
              ? 'Not Subscribed'
              : 'No Meal Scheduled'
        : meal.mealType == 'DIET'
        ? 'Diet Lunch'
        : (menu?['title'] as String? ?? 'Daily Lunch');
    final description = meal == null
        ? provider.mealErrorMessage ??
              (provider.subscriptionStatus == 'NOT SUBSCRIBED'
                  ? 'Activate a subscription to receive daily meals.'
                  : 'No meal is scheduled for today.')
        : meal.status == 'CANCELLED'
        ? "Today's meal has been cancelled."
        : meal.status == 'SERVED'
        ? 'Meal Served'
        : ((menu?['description'] as String?)?.trim().isNotEmpty ?? false)
        ? (menu!['description'] as String).trim()
        : "Today's lunch";

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58.w,
                height: 58.w,
                decoration: BoxDecoration(
                  gradient: AppGradients.gold,
                  borderRadius: BorderRadius.circular(17.r),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              SizedBox(width: 15.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    SizedBox(height: 5.h),

                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (meal != null && meal.status != 'CANCELLED')
                Text(
                  'Rs. ${meal.rate.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          if (provider.isMealLoading)
            Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: const LinearProgressIndicator(),
            ),
          if (meal?.status == 'PLANNED')
            Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: provider.isMealCancelling
                      ? null
                      : () => _confirmMealCancellation(provider),
                  icon: provider.isMealCancelling
                      ? SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel Meal'),
                ),
              ),
            ),
          if (meal?.status == 'CANCELLED' && meal?.cancelledAt != null)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(
                'Cancelled at ${_formatTime(meal!.cancelledAt!)}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmMealCancellation(EmployeeProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Today's Meal?"),
        content: const Text(
          "Are you sure you want to cancel today's meal? The meal amount will be credited back to your account.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Meal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Meal'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    final success = await provider.cancelTodayMeal();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? "Today's meal cancelled successfully."
              : (provider.mealErrorMessage ?? "Unable to cancel today's meal."),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:$minute $period';
  }

  // ============================================================
  // INFO CARD
  // ============================================================

  Widget _subscriptionCard(EmployeeProvider provider) {
    final status = provider.subscriptionStatus;
    final canPause = status == 'ACTIVE';
    final canResume = status == 'PAUSED';
    final canCancel = status == 'ACTIVE' || status == 'PAUSED';
    final canActivate =
        status == 'NOT SUBSCRIBED' ||
        status == 'CANCELLED' ||
        status == 'EXPIRED';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _infoCard(
          title: 'Subscription',
          value: status,
          icon: Icons.autorenew_rounded,
        ),
        if (canActivate)
          _subscriptionButton(
            label: 'Activate Subscription',
            onPressed: () => _activateSubscription(provider),
            isLoading: provider.isSubscriptionLoading,
          ),
        if (canPause)
          _subscriptionButton(
            label: 'Pause Subscription',
            onPressed: () => _pauseSubscription(provider),
            isLoading: provider.isSubscriptionLoading,
          ),
        if (canResume)
          _subscriptionButton(
            label: 'Resume Subscription',
            onPressed: () => _runSubscriptionAction(
              provider,
              provider.resumeSubscription,
              'Subscription resumed successfully.',
            ),
            isLoading: provider.isSubscriptionLoading,
          ),
        if (canCancel)
          _subscriptionButton(
            label: 'Cancel Subscription',
            onPressed: () => _confirmCancel(provider),
            isLoading: provider.isSubscriptionLoading,
          ),
      ],
    );
  }

  Widget _subscriptionButton({
    required String label,
    required VoidCallback onPressed,
    required bool isLoading,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 16.w,
                height: 16.w,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label, textAlign: TextAlign.center),
      ),
    );
  }

  Future<void> _activateSubscription(EmployeeProvider provider) async {
    await _runSubscriptionAction(
      provider,
      provider.activateSubscription,
      'Subscription activated successfully.',
    );
  }

  Future<void> _pauseSubscription(EmployeeProvider provider) async {
    final now = DateTime.now();
    final endDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );
    if (!mounted || endDate == null) return;

    await _runSubscriptionAction(
      provider,
      () => provider.pauseSubscription(startDate: now, endDate: endDate),
      'Subscription paused successfully.',
    );
  }

  Future<void> _confirmCancel(EmployeeProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text(
          'Are you sure you want to cancel your subscription?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    await _runSubscriptionAction(
      provider,
      provider.cancelSubscription,
      'Subscription cancelled successfully.',
    );
  }

  Future<void> _runSubscriptionAction(
    EmployeeProvider provider,
    Future<bool> Function() action,
    String successMessage,
  ) async {
    if (provider.isSubscriptionLoading) return;
    final success = await action();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? successMessage
              : (provider.subscriptionError ??
                    'Unable to update subscription.'),
        ),
      ),
    );
  }

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
