import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_gradients.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../providers/vendor/vendor_home_provider.dart';

class VendorEarningsView extends StatefulWidget {
  const VendorEarningsView({super.key});

  @override
  State<VendorEarningsView> createState() => _VendorEarningsViewState();
}

class _VendorEarningsViewState extends State<VendorEarningsView> {
  final Map<String, List<Map<String, dynamic>>> _dailyBreakdowns = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VendorHomeProvider>().loadMonthlyRevenue();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VendorHomeProvider>();
    final history = provider.monthlyRevenueHistory;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: provider.isLoadingMonthlyRevenue && history.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : provider.monthlyRevenueError != null && history.isEmpty
              ? AppErrorView(
                  message: provider.monthlyRevenueError!,
                  onRetry: provider.loadMonthlyRevenue,
                )
              : RefreshIndicator(
                  onRefresh: provider.loadMonthlyRevenue,
                  color: AppColors.primary,
                  child: ListView(
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
                      SizedBox(height: 8.h),
                      Text(
                        'Monthly Revenue',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 18.h),
                      if (history.isEmpty)
                        _emptyState()
                      else
                        ...history.map((entry) {
                          final month = entry['month'] as DateTime;
                          final total = (entry['total'] as num?) ?? 0;
                          final key = _monthKey(month);
                          final breakdown = _dailyBreakdowns[key] ?? const [];

                          return Container(
                            margin: EdgeInsets.only(bottom: 12.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(18.r),
                            ),
                            child: ExpansionTile(
                              tilePadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 4.h,
                              ),
                              childrenPadding: EdgeInsets.fromLTRB(
                                16.w,
                                0,
                                16.w,
                                16.h,
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _monthLabel(month),
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Rs. ${total.toDouble().toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              onExpansionChanged: (expanded) async {
                                if (!expanded ||
                                    _dailyBreakdowns.containsKey(key)) {
                                  return;
                                }
                                final rows = await context
                                    .read<VendorHomeProvider>()
                                    .loadMonthlyRevenueBreakdown(month);
                                if (!mounted) return;
                                setState(() {
                                  _dailyBreakdowns[key] = rows;
                                });
                              },
                              children: [
                                if (breakdown.isEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 8.h),
                                    child: Text(
                                      'No revenue entries for this month.',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  )
                                else
                                  ...breakdown.map((entry) {
                                    final day = DateTime.parse(
                                      entry['date'] as String,
                                    );
                                    final amount =
                                        (entry['total'] as num?) ?? 0;
                                    return Padding(
                                      padding: EdgeInsets.only(bottom: 6.h),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${day.day.toString().padLeft(2, '0')} ${_monthLabel(day).split(' ').first}',
                                              style: TextStyle(
                                                fontSize: 13.sp,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'Rs. ${amount.toDouble().toStringAsFixed(0)}',
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Text(
        'No revenue recorded yet.\nRs. 0',
        style: TextStyle(fontSize: 16.sp, color: AppColors.textPrimary),
      ),
    );
  }

  String _monthKey(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}';

  String _monthLabel(DateTime value) {
    const months = [
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
    ];
    return '${months[value.month - 1]} ${value.year}';
  }
}
