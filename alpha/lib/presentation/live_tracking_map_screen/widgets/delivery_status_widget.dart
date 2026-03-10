import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DeliveryStatusWidget extends StatelessWidget {
  final List<Map<String, dynamic>> statusTimeline;
  final String currentStatus;
  final ThemeData theme;

  const DeliveryStatusWidget({
    super.key,
    required this.statusTimeline,
    required this.currentStatus,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Delivery Progress', style: theme.textTheme.titleSmall),
        SizedBox(height: 1.5.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: statusTimeline.length,
          itemBuilder: (context, index) {
            final item = statusTimeline[index];
            final isDone = item["done"] as bool;
            final isCurrent = item["status"] == currentStatus;
            final isLast = index == statusTimeline.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Column(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone
                                ? AppTheme.successColor
                                : isCurrent
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                          ),
                          child: isDone
                              ? Center(
                                  child: CustomIconWidget(
                                    iconName: 'check',
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                )
                              : isCurrent
                              ? Center(
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        isLast
                            ? const SizedBox.shrink()
                            : Expanded(
                                child: Container(
                                  width: 2,
                                  color: isDone
                                      ? AppTheme.successColor
                                      : theme.colorScheme.outlineVariant,
                                ),
                              ),
                      ],
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 2.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item["label"] as String,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isCurrent
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isDone || isCurrent
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            item["time"] as String,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
