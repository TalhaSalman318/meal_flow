import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_gradients.dart';
import '../../../models/menu_model.dart';
import '../../../providers/employee_provider.dart';

class EmployeeMenusView extends StatefulWidget {
  const EmployeeMenusView({super.key});

  @override
  State<EmployeeMenusView> createState() => _EmployeeMenusViewState();
}

class _EmployeeMenusViewState extends State<EmployeeMenusView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<EmployeeProvider>().loadMenusForMonth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();
    final selected = provider.menus
        .where((menu) => menu.isForDate(DateTime.now()))
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Menu')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: provider.loadMenusForMonth,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(20.w),
              children: [
                _monthHeader(provider),
                SizedBox(height: 16.h),
                if (provider.isMenuLoading) const LinearProgressIndicator(),
                if (provider.menuError != null) _message(provider.menuError!),
                if (!provider.isMenuLoading &&
                    provider.menuError == null &&
                    provider.menus.isEmpty)
                  _message('No menus planned for this month.'),
                if (selected != null) ...[
                  _heading("Today's Menu"),
                  _menuCard(selected, highlight: true),
                  SizedBox(height: 18.h),
                ],
                if (provider.menus.isNotEmpty) _heading('Menus This Month'),
                for (final menu in provider.menus) _menuCard(menu),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _monthHeader(EmployeeProvider provider) {
    final month = provider.menuMonth;
    return Row(
      children: [
        IconButton(
          onPressed: provider.isMenuLoading
              ? null
              : () => provider.changeMenuMonth(-1),
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous month',
        ),
        Expanded(
          child: Text(
            '${_monthName(month.month)} ${month.year}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          onPressed: provider.isMenuLoading
              ? null
              : () => provider.changeMenuMonth(1),
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next month',
        ),
      ],
    );
  }

  Widget _menuCard(MenuModel menu, {bool highlight = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.gold.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: highlight
              ? AppColors.gold
              : AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _dateLabel(menu.menuDate),
            style: TextStyle(fontSize: 12.sp, color: AppColors.primary),
          ),
          SizedBox(height: 5.h),
          Text(
            menu.title,
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (menu.description != null && menu.description!.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              menu.description!,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
          if (menu.imageUrl != null && menu.imageUrl!.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              menu.imageUrl!,
              style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _heading(String text) => Padding(
    padding: EdgeInsets.only(bottom: 10.h),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    ),
  );

  Widget _message(String text) => Padding(
    padding: EdgeInsets.all(28.w),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(color: AppColors.textSecondary),
    ),
  );

  static String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  static String _monthName(int month) => const [
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
}
