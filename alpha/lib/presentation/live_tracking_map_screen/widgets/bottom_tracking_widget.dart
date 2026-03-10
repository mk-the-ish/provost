import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

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
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppTheme.radiusMedium,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          _AddressRow(
            iconName: 'radio_button_checked',
            iconColor: AppTheme.successColor,
            label: 'Pickup',
            address: orderData["pickupAddress"] as String,
            theme: theme,
          ),
          Padding(
            padding: EdgeInsets.only(left: 5.w, top: 4, bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 1.5,
                  height: 20,
                  color: theme.colorScheme.outlineVariant,
                ),
              ],
            ),
          ),
          _AddressRow(
            iconName: 'location_on',
            iconColor: AppTheme.errorLight,
            label: 'Delivery',
            address: orderData["deliveryAddress"] as String,
            theme: theme,
          ),
          Divider(height: 2.h, color: theme.colorScheme.outlineVariant),
          // Security PIN card
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.08),
              borderRadius: AppTheme.radiusSmall,
              border: Border.all(
                color: AppTheme.warningColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'lock',
                      color: AppTheme.warningColor,
                      size: 16,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Delivery PIN',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      orderData["deliveryPin"] as String,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 6,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.8.h),
                Text(
                  'Share this PIN with the courier only after you have inspected and received your package.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.warningColor.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final String iconName;
  final Color iconColor;
  final String label;
  final String address;
  final ThemeData theme;

  const _AddressRow({
    required this.iconName,
    required this.iconColor,
    required this.label,
    required this.address,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomIconWidget(iconName: iconName, color: iconColor, size: 18),
        SizedBox(width: 2.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                address,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
