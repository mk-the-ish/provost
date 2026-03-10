import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DeliveryDetailSheetWidget extends StatelessWidget {
  final Map<String, dynamic> delivery;
  final VoidCallback onNavigate;
  final VoidCallback onCallCustomer;
  final VoidCallback onMarkArrived;
  final VoidCallback onSkipDelivery;

  const DeliveryDetailSheetWidget({
    super.key,
    required this.delivery,
    required this.onNavigate,
    required this.onCallCustomer,
    required this.onMarkArrived,
    required this.onSkipDelivery,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.warningColor;
      case 'picked_up':
        return AppTheme.primaryLight;
      case 'delivered':
        return AppTheme.successColor;
      default:
        return AppTheme.secondaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final status = delivery['status'] as String;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                delivery['id'] as String,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.6.h),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.replaceAll('_', ' ').toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: _statusColor(status),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _InfoRow(
            iconName: 'person',
            label: 'Customer',
            value: delivery['customer'] as String,
          ),
          SizedBox(height: 1.h),
          _InfoRow(
            iconName: 'location_on',
            label: 'Address',
            value: delivery['address'] as String,
          ),
          SizedBox(height: 1.h),
          _InfoRow(
            iconName: 'inventory_2',
            label: 'Package Size',
            value: delivery['packageSize'] as String,
          ),
          SizedBox(height: 1.h),
          _InfoRow(
            iconName: 'access_time',
            label: 'ETA',
            value: delivery['eta'] as String,
          ),
          SizedBox(height: 3.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onNavigate,
              icon: CustomIconWidget(
                iconName: 'navigation',
                color: Colors.white,
                size: 20,
              ),
              label: const Text('Navigate'),
            ),
          ),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCallCustomer,
                  icon: CustomIconWidget(
                    iconName: 'phone',
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                  label: const Text('Call'),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onMarkArrived,
                  icon: CustomIconWidget(
                    iconName: 'check_circle',
                    color: AppTheme.successColor,
                    size: 18,
                  ),
                  label: const Text('Arrived'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.successColor,
                    side: BorderSide(color: AppTheme.successColor),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSkipDelivery,
                  icon: CustomIconWidget(
                    iconName: 'skip_next',
                    color: AppTheme.warningColor,
                    size: 18,
                  ),
                  label: const Text('Skip'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.warningColor,
                    side: BorderSide(color: AppTheme.warningColor),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String iconName;
  final String label;
  final String value;

  const _InfoRow({
    required this.iconName,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomIconWidget(
          iconName: iconName,
          color: theme.colorScheme.onSurfaceVariant,
          size: 18,
        ),
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
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
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
