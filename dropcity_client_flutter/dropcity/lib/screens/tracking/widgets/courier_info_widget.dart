import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_image_widget.dart';
import '../../../widgets/custom_icon_widget.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Courier Information', style: theme.textTheme.titleSmall),
        SizedBox(height: 1.5.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CustomImageWidget(
                imageUrl: orderData['courierAvatar'] as String,
                semanticLabel: orderData['courierAvatarLabel'] as String,
                width: 60,
                height: 60,
                radius: BorderRadius.circular(30),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orderData['courierName'] as String,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'star',
                          color: Colors.amber,
                          size: 16,
                        ),
                        SizedBox(width: 1.w),
                        Text('4.8 (150 reviews)',
                            style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'ETA',
                    style: theme.textTheme.labelSmall,
                  ),
                  Text(
                    orderData['estimatedArrival'] as String,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
