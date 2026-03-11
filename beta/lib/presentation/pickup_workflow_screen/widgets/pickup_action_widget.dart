import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PickupActionWidget extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final bool isWithinGeofence;
  final bool isPickupConfirmed;
  final bool isUploading;
  final bool isUploadComplete;
  final XFile? capturedPhoto;
  final String? pickupPhotoUrl;
  final String? captureTimestamp;
  final String? captureGpsCoords;
  final VoidCallback onConfirmPickup;
  final VoidCallback onPickFromGallery;

  const PickupActionWidget({
    super.key,
    required this.orderData,
    required this.isWithinGeofence,
    required this.isPickupConfirmed,
    required this.isUploading,
    required this.isUploadComplete,
    required this.capturedPhoto,
    required this.pickupPhotoUrl,
    required this.captureTimestamp,
    required this.captureGpsCoords,
    required this.onConfirmPickup,
    required this.onPickFromGallery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final double distance = (orderData["courierDistance"] as double?) ?? 999.0;

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
                iconName: 'my_location',
                color: isWithinGeofence
                    ? AppTheme.successColor
                    : AppTheme.warningColor,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isWithinGeofence
                          ? 'Within Pickup Zone'
                          : 'Approaching Pickup Zone',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: isWithinGeofence
                            ? AppTheme.successColor
                            : AppTheme.warningColor,
                      ),
                    ),
                    Text(
                      isWithinGeofence
                          ? '${distance.toStringAsFixed(0)}m from pickup point'
                          : '${distance.toStringAsFixed(0)}m away — move closer to activate',
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          // Geofence indicator bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: isWithinGeofence ? 1.0 : (distance / 500).clamp(0.0, 1.0),
              backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                isWithinGeofence
                    ? AppTheme.successColor
                    : AppTheme.warningColor,
              ),
              minHeight: 6,
            ),
          ),
          SizedBox(height: 2.h),
          // Confirm Pickup Button
          isUploadComplete
              ? _buildSuccessState(theme)
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isWithinGeofence && !isUploading
                        ? onConfirmPickup
                        : null,
                    icon: CustomIconWidget(
                      iconName: isWithinGeofence ? 'camera_alt' : 'lock',
                      color: Colors.white,
                      size: 20,
                    ),
                    label: Text(
                      isWithinGeofence
                          ? 'Confirm Pickup & Capture Photo'
                          : 'Move Closer to Activate',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isWithinGeofence
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.3,
                            ),
                      padding: EdgeInsets.symmetric(vertical: 1.8.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
          if (isWithinGeofence && !isUploadComplete && !isUploading) ...[
            SizedBox(height: 1.h),
            Center(
              child: TextButton.icon(
                onPressed: onPickFromGallery,
                icon: CustomIconWidget(
                  iconName: 'photo_library',
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
                label: Text(
                  'Use Gallery Instead',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccessState(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: AppTheme.successColor,
              size: 22,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                'Photo Uploaded Successfully',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.successColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.5.h),
        if (capturedPhoto != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: kIsWeb
                    ? Container(
                        width: 18.w,
                        height: 18.w,
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                        child: Center(
                          child: CustomIconWidget(
                            iconName: 'image',
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 28,
                          ),
                        ),
                      )
                    : Image.file(
                        File(capturedPhoto!.path),
                        width: 18.w,
                        height: 18.w,
                        fit: BoxFit.cover,
                        semanticLabel:
                            'Captured pickup photo of package at ${capturedPhoto!.path}',
                      ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (captureTimestamp != null)
                      _infoRow(theme, 'schedule', captureTimestamp!),
                    SizedBox(height: 0.5.h),
                    if (captureGpsCoords != null)
                      _infoRow(theme, 'gps_fixed', captureGpsCoords!),
                    SizedBox(height: 0.5.h),
                    _infoRow(theme, 'cloud_done', 'Status: PICKED_UP'),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _infoRow(ThemeData theme, String icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomIconWidget(
          iconName: icon,
          color: theme.colorScheme.onSurfaceVariant,
          size: 14,
        ),
        SizedBox(width: 1.w),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.labelSmall,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
