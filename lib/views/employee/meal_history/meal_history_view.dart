import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_gradients.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/meal_record_model.dart';
import '../../../providers/employee_provider.dart';

class MealHistoryView extends StatefulWidget {
  const MealHistoryView({super.key});

  @override
  State<MealHistoryView> createState() => _MealHistoryViewState();
}

class _MealHistoryViewState extends State<MealHistoryView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<EmployeeProvider>().loadMealHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Meal History')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: provider.refreshMealHistory,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(20.w),
              children: [
                Text(
                  'Track your daily meals',
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 16.h),
                _calendar(provider),
                SizedBox(height: 16.h),
                if (provider.isMealHistoryLoading)
                  const SizedBox(height: 360, child: DataSkeleton(count: 3)),
                if (provider.mealHistoryError != null)
                  _message(provider.mealHistoryError!, Icons.error_outline),
                if (!provider.isMealHistoryLoading &&
                    provider.mealHistoryError == null &&
                    provider.mealHistory.isEmpty)
                  _message(
                    'No meal history for this month',
                    Icons.calendar_month,
                  ),
                if (provider.mealHistory.isNotEmpty) _summary(provider),
                SizedBox(height: 16.h),
                _selectedDetails(provider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _calendar(EmployeeProvider provider) {
    final month = provider.selectedMonth;
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingDays = firstDay.weekday - 1;
    final records = <int, MealRecordModel>{
      for (final meal in provider.mealHistory) meal.mealDate.day: meal,
    };

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => provider.changeMonth(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '${_monthName(month.month)} ${month.year}',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                onPressed: () => provider.changeMonth(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final day in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                SizedBox(
                  width: 30.w,
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingDays + daysInMonth,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6.h,
              crossAxisSpacing: 4.w,
            ),
            itemBuilder: (context, index) {
              if (index < leadingDays) return const SizedBox.shrink();
              final day = index - leadingDays + 1;
              final date = DateTime(month.year, month.month, day);
              final meal = records[day];
              final status = _statusForDate(provider, date, meal);
              final selected =
                  provider.selectedDate != null &&
                  _sameDay(provider.selectedDate!, date);
              return InkWell(
                borderRadius: BorderRadius.circular(10.r),
                onTap: () => provider.selectDate(date),
                child: Container(
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.gold.withValues(alpha: 0.25)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10.r),
                    border: selected ? Border.all(color: AppColors.gold) : null,
                  ),
                  child: Center(
                    child: Container(
                      width: status == null ? null : 28.w,
                      height: status == null ? null : 28.w,
                      alignment: Alignment.center,
                      decoration: status == null
                          ? null
                          : BoxDecoration(
                              color: _statusColor(status),
                              shape: BoxShape.circle,
                            ),
                      child: Text(
                        '$day',
                        style: TextStyle(
                          color: status == null
                              ? AppColors.textPrimary
                              : Colors.white,
                          fontSize: 13.sp,
                          fontWeight: status == null
                              ? FontWeight.normal
                              : FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 6.h,
            children: [
              _legend('Planned', AppColors.gold),
              _legend('Paused', AppColors.paused),
              _legend('Cancelled', AppColors.error),
              _legend('Served', AppColors.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summary(EmployeeProvider provider) {
    int count(String status) =>
        provider.mealHistory.where((meal) => meal.status == status).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        Text(
          'Monthly Summary',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _summaryItem('Planned', count('PLANNED'), AppColors.gold),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _summaryItem('Served', count('SERVED'), AppColors.success),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _summaryItem(
                'Cancelled',
                count('CANCELLED'),
                AppColors.error,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _summaryItem('Paused', count('PAUSED'), AppColors.paused),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: _cardDecoration(),
          child: Text(
            'Total meal charges: Rs. ${provider.monthlyMealCharges.toStringAsFixed(0)}\n'
            'Cancellation credits: Rs. ${provider.monthlyCancellationCredits.toStringAsFixed(0)}\n'
            'Net amount: Rs. ${provider.monthlyNetAmount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _selectedDetails(EmployeeProvider provider) {
    final date = provider.selectedDate;
    if (date == null) return const SizedBox.shrink();
    MealRecordModel? meal;
    for (final record in provider.mealHistory) {
      if (_sameDay(record.mealDate, date)) meal = record;
    }
    final status = _statusForDate(provider, date, meal);
    final cancellationCredit = meal == null
        ? 0.0
        : provider.ledgerHistory
              .where(
                (entry) =>
                    entry.transactionType == 'CANCELLATION' &&
                    entry.referenceId == meal!.id,
              )
              .fold<double>(0, (total, entry) => total + entry.credit);
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: _cardDecoration(),
      child: meal == null
          ? Text(
              '${_formatDate(date)}\n${status == 'PAUSED' ? 'Meal Paused' : 'No meal scheduled'}',
              style: _detailStyle(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(date),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  meal.mealType == 'DIET' ? 'Diet Lunch' : 'Daily Lunch',
                  style: _detailStyle(),
                ),
                Text(
                  'Status: ${_label(status!)}',
                  style: _detailStyle(color: _statusColor(status)),
                ),
                Text(
                  'Rate: Rs. ${meal.rate.toStringAsFixed(0)}',
                  style: _detailStyle(),
                ),
                if (cancellationCredit > 0)
                  Text(
                    'Cancellation credit: Rs. ${cancellationCredit.toStringAsFixed(0)}',
                    style: _detailStyle(color: AppColors.success),
                  ),
                if (meal.status == 'CANCELLED' && meal.cancelledAt != null)
                  Text(
                    'Cancelled at ${_formatTime(meal.cancelledAt!)}',
                    style: _detailStyle(),
                  ),
                if (meal.status == 'SERVED' && meal.servedAt != null)
                  Text(
                    'Served at ${_formatTime(meal.servedAt!)}',
                    style: _detailStyle(),
                  ),
              ],
            ),
    );
  }

  Widget _summaryItem(String label, int value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
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
  }

  Widget _legend(String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 7.w,
        height: 7.w,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      SizedBox(width: 4.w),
      Text(
        label,
        style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary),
      ),
    ],
  );

  Widget _message(String message, IconData icon) => Padding(
    padding: EdgeInsets.all(28.w),
    child: Column(
      children: [
        Icon(icon, size: 42.sp, color: AppColors.textMuted),
        SizedBox(height: 10.h),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
        ),
      ],
    ),
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white.withValues(alpha: 0.65),
    borderRadius: BorderRadius.circular(20.r),
    border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
  );

  TextStyle _detailStyle({Color? color}) =>
      TextStyle(fontSize: 14.sp, color: color ?? AppColors.textSecondary);

  Color _statusColor(String status) => switch (status) {
    'PAUSED' => AppColors.paused,
    'CANCELLED' => AppColors.error,
    'SERVED' => AppColors.success,
    'NO MEAL' => AppColors.textMuted,
    _ => AppColors.gold,
  };

  String? _statusForDate(
    EmployeeProvider provider,
    DateTime date,
    MealRecordModel? meal,
  ) {
    if (meal != null) {
      if (meal.status == 'CANCELLED' || meal.status == 'SERVED') {
        return meal.status;
      }
      if (meal.status == 'PAUSED') return 'PAUSED';
    }
    if (provider.pauseForDate(date) != null) return 'PAUSED';
    return meal?.status;
  }

  String _label(String status) => status[0] + status.substring(1).toLowerCase();

  bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  String _monthName(int month) => const [
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

  String _formatDate(DateTime date) =>
      '${date.day} ${_monthName(date.month)} ${date.year}';

  String _formatTime(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour;
    return '${hour % 12 == 0 ? 12 : hour % 12}:${local.minute.toString().padLeft(2, '0')} ${hour >= 12 ? 'PM' : 'AM'}';
  }
}
