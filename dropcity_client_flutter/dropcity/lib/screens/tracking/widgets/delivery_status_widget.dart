import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

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
        Text('Delivery Timeline', style: theme.textTheme.titleSmall),
        SizedBox(height: 1.5.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: statusTimeline.length,
          itemBuilder: (context, index) {
            final item = statusTimeline[index];
            final isDone = item['done'] as bool;
            final isLastItem = index == statusTimeline.length - 1;

            return SizedBox(
              height: 6.h,
              child: Row(
                children: [
                  // Timeline dot
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          border: isDone
                              ? null
                              : Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                  width: 2,
                                ),
                        ),
                        child: isDone
                            ? Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : SizedBox.shrink(),
                      ),
                      if (!isLastItem)
                        Container(
                          width: 2,
                          height: 3.5.h,
                          color: isDone
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                        ),
                    ],
                  ),
                  SizedBox(width: 3.w),
                  // Timeline info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item['label'] as String,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                isDone ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          item['time'] as String,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
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


