import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
    );
  }
}

class SkeletonPulse extends StatefulWidget {
  final Widget child;

  const SkeletonPulse({super.key, required this.child});

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_controller),
      child: widget.child,
    );
  }
}

class DataSkeleton extends StatelessWidget {
  final int count;

  const DataSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (_, index) => Container(
          height: index.isEven ? 118 : 82,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          padding: const EdgeInsets.all(16),
          child: const Row(
            children: [
              SkeletonBox(width: 54, height: 54),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 16),
                    SizedBox(height: 10),
                    SkeletonBox(width: 170, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
