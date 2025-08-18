// lib/features/karyawan/widgets/history_job_list_loading.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class HistoryJobListLoading extends StatelessWidget {
  const HistoryJobListLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 6,
        itemBuilder: (context, index) => ListTile(
          title: Container(height: 18, width: 200, color: Colors.white),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Container(height: 14, width: 150, color: Colors.white),
              const SizedBox(height: 4),
              Container(height: 14, width: double.infinity, color: Colors.white),
            ],
          ),
          isThreeLine: true,
        ),
      ),
    );
  }
}
