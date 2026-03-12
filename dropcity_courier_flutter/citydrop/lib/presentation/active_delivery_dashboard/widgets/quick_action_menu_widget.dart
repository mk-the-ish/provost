import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class QuickActionMenuWidget extends StatelessWidget {
  final VoidCallback onManualSync;
  final VoidCallback onReportIssue;
  final VoidCallback onEmergencyContact;

  const QuickActionMenuWidget({
    super.key,
    required this.onManualSync,
    required this.onReportIssue,
    required this.onEmergencyContact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.elevatedShadow,
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActionItem(
            iconName: 'sync',
            label: 'Manual Sync',
            color: theme.colorScheme.primary,
            onTap: onManualSync,
          ),
          Divider(height: 1.h, color: theme.dividerColor),
          _ActionItem(
            iconName: 'report_problem',
            label: 'Report Issue',
            color: AppTheme.warningColor,
            onTap: onReportIssue,
          ),
          Divider(height: 1.h, color: theme.dividerColor),
          _ActionItem(
            iconName: 'emergency',
            label: 'Emergency Contact',
            color: AppTheme.errorLight,
            onTap: onEmergencyContact,
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final String iconName;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.iconName,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(iconName: iconName, color: color, size: 20),
            SizedBox(width: 2.w),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
