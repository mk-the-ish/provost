import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

class BottomTrackingCardWidget extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final ThemeData theme;

  const BottomTrackingCardWidget({
    super.key,
    required this.orderData,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Delivery Details', style: theme.textTheme.titleSmall),
        SizedBox(height: 1.5.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAddressRow(
                context,
                'Pickup',
                orderData['pickupAddress'] as String,
                'check_circle',
              ),
              SizedBox(height: 2.h),
              _buildAddressRow(
                context,
                'Delivery',
                orderData['deliveryAddress'] as String,
                'location_on',
              ),
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(2.5.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery PIN',
                      style: theme.textTheme.labelSmall,
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      orderData['deliveryPin'] as String,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressRow(
    BuildContext context,
    String label,
    String address,
    String iconName,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomIconWidget(
          iconName: iconName,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelSmall),
              SizedBox(height: 0.3.h),
              Text(
                address,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
