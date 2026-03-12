import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PickupHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final bool isOfflineMode;
  final VoidCallback onBack;
  final VoidCallback onToggleOffline;

  const PickupHeaderWidget({
    super.key,
    required this.orderData,
    required this.isOfflineMode,
    required this.onBack,
    required this.onToggleOffline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.outline,
                    width: 1,
                  ),
                ),
                child: CustomIconWidget(
                  iconName: 'arrow_back',
                  color: theme.colorScheme.onSurface,
                  size: 20,
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pickup Workflow',
                    style: theme.textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    orderData["orderId"] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onToggleOffline,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.6.h),
                decoration: BoxDecoration(
                  color: isOfflineMode
                      ? AppTheme.warningColor.withValues(alpha: 0.12)
                      : AppTheme.successColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOfflineMode
                        ? AppTheme.warningColor.withValues(alpha: 0.4)
                        : AppTheme.successColor.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOfflineMode
                            ? AppTheme.warningColor
                            : AppTheme.successColor,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      isOfflineMode ? 'Offline' : 'Online',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isOfflineMode
                            ? AppTheme.warningColor
                            : AppTheme.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outline, width: 1),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'person',
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      orderData["customerName"] as String,
                      style: theme.textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.4.h,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      orderData["packageSize"] as String,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomIconWidget(
                    iconName: 'location_on',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      orderData["pickupAddress"] as String,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 0.8.h),
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'inventory_2',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    orderData["packageWeight"] as String,
                    style: theme.textTheme.bodySmall,
                  ),
                  SizedBox(width: 4.w),
                  CustomIconWidget(
                    iconName: 'note',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                  SizedBox(width: 1.w),
                  Expanded(
                    child: Text(
                      orderData["notes"] as String,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
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
