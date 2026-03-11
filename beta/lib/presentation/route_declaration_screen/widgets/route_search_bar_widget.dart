import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class RouteSearchBarWidget extends StatelessWidget {
  final bool isOffline;
  final bool isSelectingStart;
  final LatLng? startLocation;
  final LatLng? endLocation;
  final VoidCallback onToggleSelection;

  const RouteSearchBarWidget({
    super.key,
    required this.isOffline,
    required this.isSelectingStart,
    required this.startLocation,
    required this.endLocation,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _LocationRow(
            icon: 'trip_origin',
            iconColor: Colors.green,
            label: startLocation != null
                ? '${startLocation!.latitude.toStringAsFixed(4)}, ${startLocation!.longitude.toStringAsFixed(4)}'
                : 'Tap map to set start',
            isActive: isSelectingStart,
            onTap: () {
              if (!isSelectingStart) onToggleSelection();
            },
            theme: theme,
          ),
          Divider(height: 1.5.h, color: theme.colorScheme.outline),
          _LocationRow(
            icon: 'location_on',
            iconColor: Colors.red,
            label: endLocation != null
                ? '${endLocation!.latitude.toStringAsFixed(4)}, ${endLocation!.longitude.toStringAsFixed(4)}'
                : 'Tap map to set end',
            isActive: !isSelectingStart,
            onTap: () {
              if (isSelectingStart) onToggleSelection();
            },
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final String icon;
  final Color iconColor;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final ThemeData theme;

  const _LocationRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                )
              : null,
        ),
        child: Row(
          children: [
            CustomIconWidget(iconName: icon, color: iconColor, size: 20),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            isActive
                ? CustomIconWidget(
                    iconName: 'edit_location_alt',
                    color: theme.colorScheme.primary,
                    size: 18,
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
