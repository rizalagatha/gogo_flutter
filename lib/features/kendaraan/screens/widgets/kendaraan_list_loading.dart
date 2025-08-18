// lib/features/kendaraan/widgets/kendaraan_list_loading.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class KendaraanListLoading extends StatelessWidget {
  const KendaraanListLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 6, 
        itemBuilder: (context, index) => const KendaraanListTileSkeleton(),
      ),
    );
  }
}

class KendaraanListTileSkeleton extends StatelessWidget {
  const KendaraanListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 24, backgroundColor: Colors.white),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kerangka untuk judul
                SkeletonContainer(width: 120, height: 16),
                SizedBox(height: 8),
                // Kerangka untuk subjudul
                SkeletonContainer(width: double.infinity, height: 14),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class SkeletonContainer extends StatelessWidget {
  final double width;
  final double height;

  const SkeletonContainer({super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
