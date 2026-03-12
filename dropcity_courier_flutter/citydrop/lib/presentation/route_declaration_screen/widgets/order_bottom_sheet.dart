import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class OrderBottomSheetWidget extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final Function(Map<String, dynamic>) onOrderTap;

  const OrderBottomSheetWidget({
    super.key,
    required this.orders,
    required this.onOrderTap,
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
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                child: Container(
                  width: 10.w,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'inventory_2',
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Matched Orders (${orders.length})',
                      style: theme.textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Within 500m',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 2.h),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => SizedBox(height: 1.5.h),
                  itemBuilder: (_, index) {
                    final order = orders[index];
                    final size = order['sizeCategory'] as String? ?? 'Medium';
                    final pickupAddress =
                        order['pickupAddress'] as String? ?? '';
                    final orderId = order['id'] as String? ?? '';
                    return GestureDetector(
                      onTap: () => onOrderTap(order),
                      onLongPress: () => _showQuickActions(context, order),
                      child: Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10.w,
                              height: 10.w,
                              decoration: BoxDecoration(
                                color: _sizeCategoryColor(
                                  size,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: _sizeCategoryColor(size),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          orderId,
                                          style: theme.textTheme.titleSmall,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 2.w,
                                          vertical: 0.3.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _sizeCategoryColor(
                                            size,
                                          ).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          size,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: _sizeCategoryColor(size),
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 0.5.h),
                                  Row(
                                    children: [
                                      CustomIconWidget(
                                        iconName: 'store',
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                        size: 14,
                                      ),
                                      SizedBox(width: 1.w),
                                      Expanded(
                                        child: Text(
                                          pickupAddress,
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
                            CustomIconWidget(
                              iconName: 'chevron_right',
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQuickActions(BuildContext context, Map<String, dynamic> order) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Quick Actions', style: theme.textTheme.titleMedium),
              SizedBox(height: 2.h),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'info_outline',
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                title: const Text('View Details'),
                onTap: () {
                  Navigator.pop(ctx);
                  onOrderTap(order);
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'skip_next',
                  color: AppTheme.warningColor,
                  size: 22,
                ),
                title: const Text('Skip Order'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
