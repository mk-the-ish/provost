import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PickupChecklistWidget extends StatelessWidget {
  final bool isPhotoCapture;
  final bool isLocationVerified;
  final bool isStatusUpdated;

  const PickupChecklistWidget({
    super.key,
    required this.isPhotoCapture,
    required this.isLocationVerified,
    required this.isStatusUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
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
                iconName: 'checklist',
                color: theme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text('Pickup Checklist', style: theme.textTheme.titleSmall),
            ],
          ),
          SizedBox(height: 1.5.h),
          _ChecklistItem(
            label: 'Photo Captured',
            description: 'Package photo documentation',
            isComplete: isPhotoCapture,
          ),
          SizedBox(height: 1.h),
          _ChecklistItem(
            label: 'Location Verified',
            description: 'Within 50m geofence radius',
            isComplete: isLocationVerified,
          ),
          SizedBox(height: 1.h),
          _ChecklistItem(
            label: 'Status Updated',
            description: 'Firestore: PICKED_UP',
            isComplete: isStatusUpdated,
          ),
          if (isPhotoCapture && isLocationVerified && isStatusUpdated) ...[
            SizedBox(height: 1.5.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.successColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'verified',
                    color: AppTheme.successColor,
                    size: 18,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'All pickup requirements complete!',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final String label;
  final String description;
  final bool isComplete;

  const _ChecklistItem({
    required this.label,
    required this.description,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isComplete
                ? AppTheme.successColor
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            border: Border.all(
              color: isComplete
                  ? AppTheme.successColor
                  : theme.colorScheme.outline,
              width: 1.5,
            ),
          ),
          child: Center(
            child: CustomIconWidget(
              iconName: isComplete ? 'check' : 'radio_button_unchecked',
              color: isComplete
                  ? Colors.white
                  : theme.colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isComplete
                      ? AppTheme.successColor
                      : theme.colorScheme.onSurface,
                ),
              ),
              Text(
                description,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
