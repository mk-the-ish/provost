import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class OrderCardWidget extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback? onDismiss;
  final VoidCallback? onPickup;

  const OrderCardWidget({
    super.key,
    required this.order,
    this.onDismiss,
    this.onPickup,
  });

  Color _sizeCategoryColor(String size) {
    switch (size) {
      case 'Small':
        return AppTheme.successColor;
      case 'Medium':
        return AppTheme.primaryLight;
      case 'Large':
        return AppTheme.warningColor;
      case 'XL':
        return AppTheme.accentColor;
      default:
        return AppTheme.secondaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = order['sizeCategory'] as String? ?? 'Medium';
    final pickupAddress = order['pickupAddress'] as String? ?? '';
    final deliveryAddress = order['deliveryAddress'] as String? ?? '';
    final orderId = order['id'] as String? ?? '';
    final recipientName = order['recipientName'] as String? ?? '';
    final weight = order['weight'] as String? ?? '';

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 10.w,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: Text(orderId, style: theme.textTheme.titleMedium),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _sizeCategoryColor(size).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _sizeCategoryColor(size).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  size,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: _sizeCategoryColor(size),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          _InfoRow(icon: 'person', label: recipientName, theme: theme),
          SizedBox(height: 0.8.h),
          _InfoRow(icon: 'scale', label: weight, theme: theme),
          SizedBox(height: 0.8.h),
          _InfoRow(icon: 'store', label: pickupAddress, theme: theme),
          SizedBox(height: 0.8.h),
          _InfoRow(icon: 'flag', label: deliveryAddress, theme: theme),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDismiss,
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                  label: const Text('Skip'),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushNamed('/pickup-workflow-screen');
                  },
                  icon: CustomIconWidget(
                    iconName: 'local_shipping',
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text('Pickup'),
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
  final String icon;
  final String label;
  final ThemeData theme;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomIconWidget(
          iconName: icon,
          color: theme.colorScheme.onSurfaceVariant,
          size: 16,
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
