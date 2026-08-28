import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_gradients.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../models/guest_meal_model.dart';
import '../../../providers/employee_provider.dart';

class GuestMealView extends StatefulWidget {
  const GuestMealView({super.key});

  @override
  State<GuestMealView> createState() => _GuestMealViewState();
}

class _GuestMealViewState extends State<GuestMealView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController(text: '400');
  final _notesController = TextEditingController();
  String _guestType = 'EMPLOYEE';
  String _mealType = 'NORMAL';
  String? _vendorId;
  DateTime _mealDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EmployeeProvider>();
      provider.loadGuestMeals();
      provider.loadActiveVendors();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: Column(
            children: [
              const PageHeader(title: 'Guest Meals'),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: provider.refreshGuestMeals,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(20.w),
                    children: [
                      Text(
                        'Today\'s guest meals',
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      _summary(provider),
                      SizedBox(height: 16.h),
                      _gradientButton(
                        onPressed: provider.isAddingGuestMeal
                            ? null
                            : _openAddSheet,
                        icon: Icons.person_add_alt_1,
                        label: 'Add Guest Meal',
                      ),
                      SizedBox(height: 20.h),
                      if (provider.isLoadingGuestMeals)
                        const SizedBox(
                          height: 360,
                          child: DataSkeleton(count: 3),
                        ),
                      if (provider.guestMealError != null)
                        AppErrorView(
                          message: provider.guestMealError!,
                          onRetry: provider.refreshGuestMeals,
                        ),
                      if (!provider.isLoadingGuestMeals &&
                          provider.guestMealError == null &&
                          provider.guestMeals.isEmpty)
                        _message(
                          'No guest meals yet.\nAdd a guest meal to see it here.',
                        ),
                      for (final meal in provider.guestMeals) _guestCard(meal),
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

  Widget _gradientButton({
    required VoidCallback? onPressed,
    required String label,
    IconData? icon,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.gold,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.r),
          ),
        ),
      ),
    );
  }

  Widget _summary(EmployeeProvider provider) => Container(
    padding: EdgeInsets.all(18.w),
    decoration: _cardDecoration(),
    child: Row(
      children: [
        Expanded(
          child: _summaryValue(
            'Total Guests',
            provider.guestMeals.length.toString(),
            AppColors.primary,
          ),
        ),
        Expanded(
          child: _summaryValue(
            'Total Charges',
            'Rs. ${provider.guestMealTotal.toStringAsFixed(0)}',
            AppColors.gold,
          ),
        ),
      ],
    ),
  );

  Widget _summaryValue(String label, String value, Color color) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      SizedBox(height: 4.h),
      Text(
        label,
        style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
      ),
    ],
  );

  Widget _guestCard(GuestMealModel meal) => Container(
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
                meal.guestName,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              _label(meal.guestType),
              style: TextStyle(fontSize: 12.sp, color: AppColors.primary),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Text(
          '${_label(meal.mealType)} Meal  |  Rs. ${meal.amount.toStringAsFixed(0)}',
          style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
        ),
        Text(
          '${_formatDate(meal.mealDate)}  ${_formatTime(meal.createdAt)}',
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

  Future<void> _openAddSheet() async {
    final provider = context.read<EmployeeProvider>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 20.h,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 20.h,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add Guest Meal',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Guest Name'),
                    validator: (value) {
                      final name = value?.trim() ?? '';
                      return name.length < 2 || name.length > 100
                          ? 'Enter a name between 2 and 100 characters.'
                          : null;
                    },
                  ),
                  SizedBox(height: 10.h),
                  DropdownButtonFormField<String>(
                    value: _guestType,
                    decoration: const InputDecoration(labelText: 'Guest Type'),
                    items: ['EMPLOYEE', 'VENDOR']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(_label(value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setSheetState(() {
                      _guestType = value!;
                      if (_guestType == 'EMPLOYEE') _vendorId = null;
                    }),
                  ),
                  if (_guestType == 'VENDOR')
                    DropdownButtonFormField<String>(
                      value: _vendorId,
                      decoration: const InputDecoration(labelText: 'Vendor'),
                      items: provider.activeVendors
                          .map(
                            (vendor) => DropdownMenuItem(
                              value: vendor['id'] as String,
                              child: Text(
                                '${vendor['vendor_name']} (${vendor['vendor_code']})',
                              ),
                            ),
                          )
                          .toList(),
                      validator: (value) =>
                          value == null ? 'Select a vendor.' : null,
                      onChanged: (value) =>
                          setSheetState(() => _vendorId = value),
                    ),
                  SizedBox(height: 10.h),
                  DropdownButtonFormField<String>(
                    value: _mealType,
                    decoration: const InputDecoration(labelText: 'Meal Type'),
                    items: ['NORMAL', 'DIET']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(_label(value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setSheetState(() => _mealType = value!),
                  ),
                  SizedBox(height: 10.h),
                  InputDecorator(
                    decoration: const InputDecoration(labelText: 'Meal Date'),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(_formatDate(_mealDate)),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    validator: (value) {
                      final amount = double.tryParse(value?.trim() ?? '');
                      return amount == null || amount <= 0
                          ? 'Enter an amount greater than zero.'
                          : null;
                    },
                  ),
                  SizedBox(height: 10.h),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _gradientButton(
                          onPressed: provider.isAddingGuestMeal
                              ? null
                              : () => _submit(provider),
                          label: provider.isAddingGuestMeal
                              ? 'Adding...'
                              : 'Add Guest Meal',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(EmployeeProvider provider) async {
    if (!_formKey.currentState!.validate()) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Guest Meal'),
        content: Text(
          '${_nameController.text.trim()}\n'
          '${_label(_guestType)} guest\n'
          '${_label(_mealType)} meal\n'
          'Rs. ${_amountController.text.trim()}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          _gradientButton(
            onPressed: () => Navigator.pop(context, true),
            label: 'Confirm',
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final success = await provider.addGuestMeal(
      guestType: _guestType,
      guestName: _nameController.text,
      vendorId: _vendorId,
      mealDate: _mealDate,
      mealType: _mealType,
      amount: double.parse(_amountController.text),
      notes: _notesController.text,
    );
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      _nameController.clear();
      _notesController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guest meal added successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.guestMealError ?? 'Unable to add guest meal.'),
        ),
      );
    }
  }

  Widget _message(String text) => Padding(
    padding: EdgeInsets.all(28.w),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(color: AppColors.textSecondary),
    ),
  );
  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white.withValues(alpha: 0.65),
    borderRadius: BorderRadius.circular(20.r),
    border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
  );
  String _label(String value) => value[0] + value.substring(1).toLowerCase();
  String _formatDate(DateTime date) =>
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
    return '${local.hour % 12 == 0 ? 12 : local.hour % 12}:${local.minute.toString().padLeft(2, '0')} ${local.hour >= 12 ? 'PM' : 'AM'}';
  }
}
