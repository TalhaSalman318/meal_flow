import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_gradients.dart';
import '../../../models/menu_model.dart';
import '../../../providers/vendor/menu_provider.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/menu_image.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/app_error_view.dart';
import 'add_menu_view.dart';
import 'edit_menu_view.dart';

class VendorMenusView extends StatefulWidget {
  const VendorMenusView({super.key});
  @override
  State<VendorMenusView> createState() => _VendorMenusViewState();
}

class _VendorMenusViewState extends State<VendorMenusView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VendorMenuProvider>().loadMenus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VendorMenuProvider>();

    return Scaffold(
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.gold,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              blurRadius: 18.r,
              offset: Offset(0, 8.h),
              color: AppColors.primary.withValues(alpha: 0.18),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: provider.isSaving
                ? null
                : () async {
                    await Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const AddMenuView(),
                      ),
                    );
                    if (!context.mounted) return;
                    context.read<VendorMenuProvider>().loadMenus();
                  },
            borderRadius: BorderRadius.circular(18.r),
            child: SizedBox(
              height: 52.h,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, color: Colors.white),
                    SizedBox(width: 8.w),
                    Text(
                      'Add Menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: Column(
            children: [
              PageHeader(
                title: 'Menu Management',
                actions: [
                  IconButton(
                    onPressed: provider.isLoading ? null : provider.loadMenus,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh menus',
                  ),
                ],
              ),
              Expanded(
                child: provider.isLoading
                    ? const DataSkeleton()
                    : provider.errorMessage != null
                    ? _error(provider)
                    : provider.isEmpty
                    ? _empty()
                    : _menuSections(provider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuSections(VendorMenuProvider provider) {
    final today = _dateOnly(DateTime.now());
    final month = provider.selectedMonth;
    final isCurrentMonth =
        month.year == today.year && month.month == today.month;
    final todayMenus = provider.menus
        .where((menu) => _dateOnly(menu.menuDate) == today)
        .toList();
    final upcoming =
        provider.menus
            .where((menu) => _dateOnly(menu.menuDate).isAfter(today))
            .toList()
          ..sort((a, b) => a.menuDate.compareTo(b.menuDate));
    final past =
        provider.menus
            .where((menu) => _dateOnly(menu.menuDate).isBefore(today))
            .toList()
          ..sort((a, b) => b.menuDate.compareTo(a.menuDate));

    return RefreshIndicator(
      onRefresh: provider.loadMenus,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 100.h),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: provider.isLoading
                    ? null
                    : () => provider.changeMonth(-1),
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
                onPressed: provider.isLoading
                    ? null
                    : () => provider.changeMonth(1),
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next month',
              ),
            ],
          ),
          _section(
            isCurrentMonth ? 'Today\'s Menu' : 'Menus This Month',
            isCurrentMonth ? todayMenus : provider.menus,
            showAddAction: isCurrentMonth,
          ),
          if (isCurrentMonth && upcoming.isNotEmpty) ...[
            SizedBox(height: 24.h),
            _section('Upcoming Menus', upcoming),
          ],
          if (isCurrentMonth && past.isNotEmpty) ...[
            SizedBox(height: 24.h),
            _section('Past Menus', past),
          ],
        ],
      ),
    );
  }

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

  Widget _section(
    String title,
    List<MenuModel> menus, {
    bool showAddAction = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        if (menus.isEmpty)
          Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('No menu planned for today.'),
                if (showAddAction) ...[
                  SizedBox(height: 12.h),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppGradients.gold,
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    child: FilledButton.icon(
                      onPressed: _openAddMenu,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text("Add Today's Menu"),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          ...menus.map(
            (menu) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _MenuCard(
                menu: menu,
                onEdit: () => _editMenu(menu),
                onDelete: () => _deleteMenu(menu),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _editMenu(MenuModel menu) async {
    final provider = context.read<VendorMenuProvider>();
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => EditMenuView(menu: menu)),
    );
    if (!mounted) return;
    provider.loadMenus();
  }

  Future<void> _openAddMenu() async {
    final provider = context.read<VendorMenuProvider>();
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const AddMenuView()),
    );
    if (!mounted) return;
    provider.loadMenus();
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _deleteMenu(MenuModel menu) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this menu?'),
        content: const Text(
          'Are you sure you want to delete this menu? This action cannot be undone.',
        ),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    final provider = context.read<VendorMenuProvider>();
    debugPrint('[Vendor Menu Delete] UI CONFIRMED menuId=${menu.id}');

    final success = await provider.deleteMenu(menu.id);
    if (!mounted) return;
    debugPrint(
      '[Vendor Menu Delete] UI COMPLETE menuId=${menu.id} success=$success',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Menu deleted successfully' : 'Unable to delete menu.',
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your menu is empty'),
            SizedBox(height: 8.h),
            const Text('Create your first menu to start planning meals.'),
            SizedBox(height: 16.h),
            FilledButton.icon(
              onPressed: _openAddMenu,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Menu'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _error(VendorMenuProvider provider) {
    return AppErrorView(
      message: provider.errorMessage!,
      onRetry: () {
        provider.loadMenus();
      },
    );
  }
}

class _MenuCard extends StatelessWidget {
  final MenuModel menu;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MenuCard({
    required this.menu,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  menu.title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit menu',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete menu',
              ),
            ],
          ),
          Text(
            _dateLabel(menu.menuDate),
            style: TextStyle(fontSize: 13.sp, color: AppColors.primary),
          ),
          if (menu.description != null && menu.description!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(menu.description!),
          ],
          SizedBox(height: 12.h),
          MenuImage(url: menu.imageUrl, height: 160.h),
        ],
      ),
    );
  }

  static String _dateLabel(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
