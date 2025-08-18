// lib/features/job/widgets/job_list_loading.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonContainer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonContainer({
    super.key,
    required this.width,
    required this.height,
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


class JobListLoading extends StatelessWidget {
  const JobListLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5, 
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonContainer(width: 150, height: 18),
                  const SizedBox(height: 12),
                  const SkeletonContainer(width: double.infinity, height: 14),
                  const SizedBox(height: 6),
                  const SkeletonContainer(width: double.infinity, height: 14),
                  const SizedBox(height: 6),
                  SkeletonContainer(width: MediaQuery.of(context).size.width * 0.7, height: 14),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
