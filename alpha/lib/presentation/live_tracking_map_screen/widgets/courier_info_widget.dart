import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CourierInfoWidget extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final ThemeData theme;

  const CourierInfoWidget({
    super.key,
    required this.orderData,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: CustomImageWidget(
            imageUrl: orderData["courierAvatar"] as String,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            semanticLabel: orderData["courierAvatarLabel"] as String,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                orderData["courierName"] as String,
                style: theme.textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 0.4.h),
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'access_time',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 14,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    'ETA: ${orderData["estimatedArrival"]}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: AppTheme.radiusSmall,
          ),
          child: Row(
            children: [
              CustomIconWidget(
                iconName: 'star',
                color: AppTheme.warningColor,
                size: 14,
              ),
              SizedBox(width: 1.w),
              Text(
                '4.8',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
