// lib/features/monitoring/widgets/monitoring_list_loading.dart

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

class MonitoringListLoading extends StatelessWidget {
  const MonitoringListLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 7, // Tampilkan 7 item kerangka
        itemBuilder: (context, index) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SkeletonContainer(width: 48, height: 48, borderRadius: 24), // CircleAvatar
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonContainer(width: 150, height: 18), // Nama
                      SizedBox(height: 8),
                      SkeletonContainer(width: double.infinity, height: 14), // Keterangan baris 1
                      SizedBox(height: 6),
                      SkeletonContainer(width: 100, height: 14), // Keterangan baris 2
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
