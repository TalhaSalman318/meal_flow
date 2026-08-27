import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_gradients.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/page_header.dart';
import '../../../models/meal_record_model.dart';
import '../../../models/guest_meal_model.dart';
import '../../../providers/vendor/vendor_home_provider.dart';

class VendorMealsView extends StatefulWidget {
  const VendorMealsView({super.key});

  @override
  State<VendorMealsView> createState() => _VendorMealsViewState();
}

class _VendorMealsViewState extends State<VendorMealsView> {
  final _searchController = TextEditingController();
  String _filter = 'ALL';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<VendorHomeProvider>();
      provider.loadTodaysMeals();
      provider.loadTodaysGuestMeals();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VendorHomeProvider>();
    final meals = provider.todaysMeals.where(_matches).toList();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: Column(
            children: [
              const PageHeader(title: "Today's Meals"),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: provider.refreshTodaysMeals,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(20.w),
                    children: [
                      Text(
                        _dateLabel(DateTime.now()),
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      _stats(provider),
                      SizedBox(height: 16.h),
                      TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search employee',
                        ),
                      ),
                      SizedBox(height: 10.h),
                      _filters(),
                      SizedBox(height: 16.h),
                      if (provider.isLoadingMeals)
                        const SizedBox(
                          height: 360,
                          child: DataSkeleton(count: 3),
                        ),
                      if (provider.mealError != null)
                        _message(provider.mealError!, Icons.error_outline),
                      if (!provider.isLoadingMeals &&
                          provider.mealError == null &&
                          meals.isEmpty)
                        _message(
                          "No meals generated for today.\nGenerate today's meals from the dashboard.",
                          Icons.restaurant_outlined,
                        ),
                      for (final meal in meals) _mealCard(provider, meal),
                      SizedBox(height: 16.h),
                      _guestMealsSection(provider),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _guestMealsSection(VendorHomeProvider provider) {
    if (!provider.isLoadingGuestMeals &&
        provider.todaysGuestMeals.isEmpty &&
        provider.guestMealError == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Guest Meals',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        if (provider.isLoadingGuestMeals)
          const SizedBox(height: 360, child: DataSkeleton(count: 3)),
        if (provider.guestMealError != null)
          _message(provider.guestMealError!, Icons.error_outline),
        for (final meal in provider.todaysGuestMeals) _guestMealCard(meal),
      ],
    );
  }

  Widget _guestMealCard(GuestMealModel meal) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(16.w),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meal.guestName,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            '${meal.guestType} guest  |  ${meal.mealType} meal',
            style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
          ),
          Text(
            'Employee',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
          Text(
            meal.employeeName?.trim().isNotEmpty == true
                ? meal.employeeName!
                : 'Employee',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            meal.employeeCode?.trim().isNotEmpty == true
                ? meal.employeeCode!
                : 'Code unavailable',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted),
          ),
          Text(
            'Rs. ${meal.amount.toStringAsFixed(0)}  |  ${meal.mealDate}',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted),
          ),
          if (meal.vendorName != null)
            Text(
              'Vendor: ${meal.vendorName}',
              style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
            ),
          if (meal.notes != null && meal.notes!.isNotEmpty)
            Text(
              meal.notes!,
              style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }

  bool _matches(MealRecordModel meal) {
    final query = _searchController.text.trim().toLowerCase();
    final searchable = '${meal.employeeName ?? ''} ${meal.employeeCode ?? ''}'
        .toLowerCase();
    final searchMatches = query.isEmpty || searchable.contains(query);
    final filterMatches =
        _filter == 'ALL' || meal.status == _filter || meal.mealType == _filter;
    return searchMatches && filterMatches;
  }

  Widget _stats(VendorHomeProvider provider) {
    return Row(
      children: [
        Expanded(child: _stat('Total', provider.totalMeals, AppColors.primary)),
        SizedBox(width: 6.w),
        Expanded(
          child: _stat('Served', provider.servedMeals, AppColors.success),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: _stat('Pending', provider.plannedMeals, AppColors.gold),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: _stat('Cancelled', provider.cancelledMeals, AppColors.error),
        ),
      ],
    );
  }

  Widget _stat(String label, int value, Color color) => Container(
    padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 3.w),
    decoration: _cardDecoration(),
    child: Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary),
        ),
      ],
    ),
  );

  Widget _filters() => Wrap(
    spacing: 8.w,
    children: ['ALL', 'PLANNED', 'SERVED', 'CANCELLED']
        .map(
          (filter) => ChoiceChip(
            label: Text(_label(filter)),
            selected: _filter == filter,
            onSelected: (_) => setState(() => _filter = filter),
          ),
        )
        .toList(),
  );

  Widget _mealCard(VendorHomeProvider provider, MealRecordModel meal) {
    final serving = provider.servingMealIds.contains(meal.id);
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  meal.employeeName?.trim().isNotEmpty == true
                      ? meal.employeeName!
                      : 'Employee',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _status(meal.status),
            ],
          ),
          if (meal.employeeCode?.trim().isNotEmpty == true)
            Text(
              meal.employeeCode!,
              style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted),
            ),
          SizedBox(height: 6.h),
          Text(
            '${meal.mealType == 'DIET' ? 'Diet' : 'Normal'} Meal  |  Rs. ${meal.rate.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
          ),
          if (meal.status == 'SERVED' && meal.servedAt != null)
            Text(
              'Served at ${_formatTime(meal.servedAt!)}',
              style: TextStyle(fontSize: 12.sp, color: AppColors.success),
            ),
          if (meal.status == 'CANCELLED')
            Text(
              'Meal cancelled',
              style: TextStyle(fontSize: 12.sp, color: AppColors.error),
            ),
          if (meal.status == 'PLANNED')
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: serving ? null : () => _confirmServe(provider, meal),
                icon: serving
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: const Text('Serve Meal'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _status(String status) => Text(
    _label(status),
    style: TextStyle(fontWeight: FontWeight.w700, color: _statusColor(status)),
  );

  Future<void> _confirmServe(
    VendorHomeProvider provider,
    MealRecordModel meal,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Serve this meal?'),
        content: Text(
          '${meal.employeeName?.trim().isNotEmpty == true ? meal.employeeName : 'Employee'}\n${meal.employeeCode ?? 'Code unavailable'}\n${meal.mealType} Meal\nRs. ${meal.rate.toStringAsFixed(0)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Serve Meal'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final success = await provider.serveMeal(meal.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Meal served successfully.'
              : (provider.mealError ?? 'Unable to serve meal.'),
        ),
      ),
    );
  }

  Widget _message(String message, IconData icon) => Padding(
    padding: EdgeInsets.all(28.w),
    child: Column(
      children: [
        Icon(icon, size: 42.sp, color: AppColors.textMuted),
        SizedBox(height: 10.h),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    ),
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white.withValues(alpha: 0.65),
    borderRadius: BorderRadius.circular(20.r),
    border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
  );

  Color _statusColor(String status) => switch (status) {
    'SERVED' => AppColors.success,
    'CANCELLED' => AppColors.error,
    'PAUSED' => AppColors.paused,
    _ => AppColors.gold,
  };

  String _label(String value) => value[0] + value.substring(1).toLowerCase();

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}';

  String _month(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];

  String _formatTime(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour;
    return '${hour % 12 == 0 ? 12 : hour % 12}:${local.minute.toString().padLeft(2, '0')} ${hour >= 12 ? 'PM' : 'AM'}';
  }
}
