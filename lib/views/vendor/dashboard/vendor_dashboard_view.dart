import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../models/menu_model.dart';
import '../../../models/profile_model.dart';
import '../../../providers/vendor/vendor_home_provider.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/menu_image.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/app_error_view.dart';

class VendorDashboardView extends StatefulWidget {
  const VendorDashboardView({super.key});

  @override
  State<VendorDashboardView> createState() => _VendorDashboardViewState();
}

class _VendorDashboardViewState extends State<VendorDashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VendorHomeProvider>().loadVendorData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VendorHomeProvider>();

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          const _Atmosphere(),
          SafeArea(
            child:
                provider.isLoading ||
                    (!provider.hasData && provider.errorMessage == null)
                ? const _LoadingState()
                : provider.errorMessage != null
                ? AppErrorView(
                    message: provider.errorMessage!,
                    onRetry: () {
                      provider.loadVendorData();
                    },
                  )
                : _DashboardContent(provider: provider),
          ),
        ],
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final VendorHomeProvider provider;

  const _DashboardContent({required this.provider});

  @override
  Widget build(BuildContext context) {
    final vendor = provider.vendor!;
    final profile = provider.profile!;

    return RefreshIndicator(
      onRefresh: provider.loadVendorData,
      color: AppColors.primary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth >= 900 ? 40.w : 16.w;
          final maxWidth = constraints.maxWidth >= 1200
              ? 1200.0
              : constraints.maxWidth;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(padding, 24.h, padding, 40.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(
                      vendor: vendor,
                      profileName: profile.fullName,
                      profile: profile,
                    ),
                    SizedBox(height: 28.h),
                    const _SectionTitle(
                      title: "Today's Glance",
                      subtitle: 'A clear view of your canteen operations',
                    ),
                    SizedBox(height: 14.h),
                    _StatisticsGrid(provider: provider),
                    SizedBox(height: 28.h),
                    const _SectionTitle(
                      title: "Today's menu",
                      subtitle: 'Keep the day ahead ready for your diners',
                    ),
                    SizedBox(height: 14.h),
                    _TodayMenuCard(menu: provider.todaysMenu),
                    SizedBox(height: 14.h),
                    _GenerateMealsButton(provider: provider),
                    SizedBox(height: 28.h),
                    const _SectionTitle(
                      title: 'Quick actions',
                      subtitle: 'Move quickly between the work that matters',
                    ),
                    SizedBox(height: 14.h),
                    const _QuickActions(),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GenerateMealsButton extends StatelessWidget {
  final VendorHomeProvider provider;

  const _GenerateMealsButton({required this.provider});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: provider.isGeneratingMeals
            ? null
            : () => _generateMeals(context),
        icon: provider.isGeneratingMeals
            ? SizedBox(
                width: 18.w,
                height: 18.w,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.restaurant_rounded),
        label: Text(
          provider.isGeneratingMeals
              ? 'Generating Today\'s Meals...'
              : 'Generate Today\'s Meals',
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.white,
          minimumSize: Size.fromHeight(52.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.r),
          ),
        ),
      ),
    );
  }

  Future<void> _generateMeals(BuildContext context) async {
    final result = await provider.generateTodaysMeals();
    if (!context.mounted) return;

    final message = result == null
        ? (provider.mealGenerationError ?? 'Unable to generate today\'s meals.')
        : "Today's meals generated successfully\n"
              'Meals: ${result['generated_meals'] ?? 0}, '
              'Charges: ${result['generated_charges'] ?? 0}';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Header extends StatelessWidget {
  final dynamic vendor;
  final String profileName;
  final ProfileModel profile;

  const _Header({
    required this.vendor,
    required this.profileName,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning, ${vendor.vendorName}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 28.sp,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "Here's your canteen overview",
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 14.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _Pill(
                    icon: Icons.storefront_outlined,
                    label: vendor.vendorCode,
                  ),
                  _StatusPill(label: vendor.status),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                vendor.contactPerson ?? profileName,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 16.w),
        ProfileAvatar(
          profile: profile,
          onTap: () => Navigator.pushNamed(context, AppRoutes.vendorProfile),
        ),
      ],
    );
  }
}

class _StatisticsGrid extends StatelessWidget {
  final VendorHomeProvider provider;

  const _StatisticsGrid({required this.provider});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 520
            ? 2
            : 1;
        final gap = 12.w;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        final cards = [
          (
            Icons.restaurant_outlined,
            "Today's Meals",
            provider.isLoadingMeals ? '--' : '${provider.totalMeals}',
          ),
          (
            Icons.groups_outlined,
            'Guest Meals',
            provider.isLoadingGuestMeals
                ? '--'
                : '${provider.todaysGuestMeals.length}',
          ),
          (
            Icons.badge_outlined,
            'Active Employees',
            provider.activeEmployeeCount?.toString() ?? '--',
          ),
          (
            Icons.payments_outlined,
            "Today's Revenue",
            provider.isLoadingMeals || provider.isLoadingGuestMeals
                ? '--'
                : 'Rs. ${provider.todaysRevenue.toStringAsFixed(0)}',
          ),
          (
            Icons.calendar_month_rounded,
            'Monthly Revenue',
            provider.isLoadingMonthlyRevenue
                ? '--'
                : provider.monthlyRevenueError != null
                ? 'Rs. 0'
                : 'Rs. ${provider.monthlyRevenue.toStringAsFixed(0)}',
          ),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards)
              card.$2 == 'Monthly Revenue'
                  ? InkWell(
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.vendorEarnings,
                      ),
                      borderRadius: BorderRadius.circular(24.r),
                      child: _StatCard(
                        width: width,
                        icon: card.$1,
                        label: card.$2,
                        value: card.$3,
                      ),
                    )
                  : _StatCard(
                      width: width,
                      icon: card.$1,
                      label: card.$2,
                      value: card.$3,
                    ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: _GlassCard(
        child: Row(
          children: [
            _IconTile(icon: icon),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 6.h),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayMenuCard extends StatelessWidget {
  final MenuModel? menu;

  const _TodayMenuCard({required this.menu});

  @override
  Widget build(BuildContext context) {
    if (menu == null) {
      return _GlassCard(
        child: Row(
          children: [
            const _IconTile(icon: Icons.restaurant_menu_outlined),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No menu planned for today',
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    'Add the next dish your canteen will serve.',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  const _MenuButton(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return _GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MenuImage(
            url: menu!.imageUrl,
            height: 190.h,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        menu!.title,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        _dateLabel(menu!.menuDate),
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.primary,
                        ),
                      ),
                      if (menu!.description != null &&
                          menu!.description!.isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        Text(menu!.description!),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                const _MenuButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _MenuButton extends StatelessWidget {
  const _MenuButton();

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () => Navigator.pushNamed(context, AppRoutes.vendorMenus),
      icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
      label: const Text('Manage Menu'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.white,
        minimumSize: Size(0, 52.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.r),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700
            ? 4
            : constraints.maxWidth >= 420
            ? 2
            : 1;
        final gap = 12.w;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        final actions = [
          (Icons.restaurant_menu_rounded, 'Manage Menu', true),
          (Icons.restaurant_outlined, 'View Meals', true),
          (Icons.group_outlined, 'Guest Meals', true),
          (Icons.person_outline_rounded, 'Profile', false),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final action in actions)
              _ActionCard(
                width: width,
                icon: action.$1,
                label: action.$2,
                onPressed: action.$2 == 'Manage Menu'
                    ? () => Navigator.pushNamed(context, AppRoutes.vendorMenus)
                    : action.$2 == 'View Meals'
                    ? () => Navigator.pushNamed(context, AppRoutes.vendorMeals)
                    : action.$2 == 'Guest Meals'
                    ? () => Navigator.pushNamed(context, AppRoutes.vendorMeals)
                    : () =>
                          Navigator.pushNamed(context, AppRoutes.vendorProfile),
              ),
          ],
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24.r),
          child: _GlassCard(
            child: Row(
              children: [
                _IconTile(icon: icon),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18.sp,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _GlassCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 24.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
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
        SizedBox(height: 4.h),
        Text(
          subtitle,
          style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  final IconData icon;

  const _IconTile({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46.w,
      height: 46.w,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Icon(icon, color: AppColors.textPrimary, size: 22.sp),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.72)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: AppColors.textPrimary),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7.w,
            height: 7.w,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const DataSkeleton(count: 5);
  }
}

class _Atmosphere extends StatelessWidget {
  const _Atmosphere();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -180.h,
            right: -140.w,
            child: _Glow(
              color: AppColors.lightSage.withValues(alpha: 0.32),
              size: 500.w,
            ),
          ),
          Positioned(
            bottom: -220.h,
            left: -180.w,
            child: _Glow(
              color: AppColors.gold.withValues(alpha: 0.13),
              size: 560.w,
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;

  const _Glow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}
