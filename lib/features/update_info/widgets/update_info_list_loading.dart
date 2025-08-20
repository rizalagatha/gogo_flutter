// lib/features/update_info/widgets/update_info_list_loading.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class UpdateInfoListLoading extends StatelessWidget {
  const UpdateInfoListLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: 6, // Jumlah item skeleton yang ditampilkan
        itemBuilder: (context, index) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              title: Container(
                width: double.infinity,
                height: 18.0,
                color: Colors.white,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 14.0,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 150,
                      height: 14.0,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
