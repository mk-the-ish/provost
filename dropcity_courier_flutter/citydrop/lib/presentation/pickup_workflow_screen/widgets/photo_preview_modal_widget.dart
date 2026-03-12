import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PhotoPreviewModalWidget extends StatelessWidget {
  final XFile? capturedPhoto;
  final VoidCallback onRetake;
  final VoidCallback onConfirm;

  const PhotoPreviewModalWidget({
    super.key,
    required this.capturedPhoto,
    required this.onRetake,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 1.h),
              width: 10.w,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Review Photo',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text('Confirm or retake', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outline),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: capturedPhoto != null
                          ? (kIsWeb
                                ? Container(
                                    width: double.infinity,
                                    color: theme.colorScheme.outline.withValues(
                                      alpha: 0.15,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CustomIconWidget(
                                          iconName: 'image',
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                          size: 48,
                                        ),
                                        SizedBox(height: 1.h),
                                        Text(
                                          'Photo captured',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  )
                                : Image.file(
                                    File(capturedPhoto!.path),
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    semanticLabel:
                                        'Preview of captured package pickup photo showing the package to be collected',
                                  ))
                          : Container(
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.15,
                              ),
                              child: Center(
                                child: CustomIconWidget(
                                  iconName: 'broken_image',
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 48,
                                ),
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'info_outline',
                          color: theme.colorScheme.primary,
                          size: 16,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            'Ensure the package label and condition are clearly visible',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onRetake,
                          icon: CustomIconWidget(
                            iconName: 'replay',
                            color: theme.colorScheme.primary,
                            size: 18,
                          ),
                          label: const Text('Retake'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 1.5.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: onConfirm,
                          icon: CustomIconWidget(
                            iconName: 'cloud_upload',
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text('Confirm & Upload'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 1.5.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
