
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer loading card للتحميل الاحترافي
class ShimmerCard extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const ShimmerCard({
    super.key,
    this.height = 80,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Shimmer لـ List Items (مثل المحادثات والمواعيد)
class ShimmerListItem extends StatelessWidget {
  const ShimmerListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // صورة دائرية
          const ShimmerCard(
            height: 56,
            width: 56,
            borderRadius: BorderRadius.all(Radius.circular(28)),
          ),
          const SizedBox(width: 12),

          // المحتوى
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerCard(
                  height: 16,
                  width: MediaQuery.of(context).size.width * 0.4,
                ),
                const SizedBox(height: 8),
                ShimmerCard(
                  height: 14,
                  width: MediaQuery.of(context).size.width * 0.6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer لبطاقات الإحصائيات
class ShimmerStatCard extends StatelessWidget {
  const ShimmerStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: ShimmerCard(height: 100),
    );
  }
}

/// Shimmer Loading List - قائمة كاملة من shimmer items
class ShimmerLoadingList extends StatelessWidget {
  final int itemCount;

  const ShimmerLoadingList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) => const ShimmerListItem(),
    );
  }
}
