// lib/features/kegiatan/widgets/check_out_form_loading.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonContainer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonContainer({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class CheckOutFormLoading extends StatelessWidget {
  const CheckOutFormLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          SkeletonContainer(width: 150, height: 16),
          SizedBox(height: 8),
          SkeletonContainer(width: 120, height: 16),
          SizedBox(height: 8),
          SkeletonContainer(width: 180, height: 16),
          SizedBox(height: 8),
          SkeletonContainer(width: 220, height: 16),
          Divider(height: 32),
          SkeletonContainer(height: 56), 
          SizedBox(height: 16),
          SkeletonContainer(height: 100), 
          SizedBox(height: 16),
          SkeletonContainer(height: 150), 
          SizedBox(height: 24),
          SkeletonContainer(height: 48),
        ],
      ),
    );
  }
}
