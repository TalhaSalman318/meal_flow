import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';

class MenuImage extends StatelessWidget {
  final String? url;
  final double height;
  final BorderRadius? borderRadius;

  const MenuImage({
    super.key,
    required this.url,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = url?.trim();
    final radius = borderRadius ?? BorderRadius.circular(16.r);
    return ClipRRect(
      borderRadius: radius,
      child: imageUrl == null || imageUrl.isEmpty
          ? _placeholder()
          : Image.network(
              imageUrl,
              width: double.infinity,
              height: height,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _placeholder(showLoading: true);
              },
              errorBuilder: (_, _, _) => _placeholder(showError: true),
            ),
    );
  }

  Widget _placeholder({bool showLoading = false, bool showError = false}) {
    return Container(
      width: double.infinity,
      height: height,
      color: AppColors.primary.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: showLoading
          ? SizedBox(
              width: 24.w,
              height: 24.w,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  showError
                      ? Icons.broken_image_outlined
                      : Icons.restaurant_outlined,
                  size: 30.sp,
                  color: AppColors.textMuted,
                ),
                if (showError) ...[
                  SizedBox(height: 6.h),
                  Text(
                    'Unable to load menu image',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
