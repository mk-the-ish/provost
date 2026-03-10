import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../custom_icon_widget.dart';
import '../custom_image_widget.dart';

class CourierInfoCardWidget extends StatelessWidget {
  final Map<String, dynamic> courierData;
  final ThemeData theme;

  const CourierInfoCardWidget({
    super.key,
    required this.courierData,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final rating = (courierData['rating'] as num?)?.toDouble() ?? 0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 7.w,
            backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
            child: ClipOval(
              child: CustomImageWidget(
                imageUrl: courierData['profileImage'] as String?,
                width: 14.w,
                height: 14.w,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        (courierData['name'] as String?) ?? 'Unknown courier',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'star',
                            color: const Color(0xFFFCD34D),
                            size: 14,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            '${rating.toStringAsFixed(1)}/5',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'location_on',
                      color: const Color(0xFF6366F1),
                      size: 14,
                    ),
                    SizedBox(width: 1.w),
                    Expanded(
                      child: Text(
                        (courierData['vehicle'] as String?) ??
                            'Vehicle details unavailable',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
