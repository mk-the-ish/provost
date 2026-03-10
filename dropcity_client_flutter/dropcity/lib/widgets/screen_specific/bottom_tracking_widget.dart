import '../../core/app_export.dart';
import '../custom_icon_widget.dart';

class BottomTrackingCardWidget extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final ThemeData theme;

  const BottomTrackingCardWidget({
    super.key,
    required this.orderData,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          _AddressRow(
            iconName: 'radio_button_checked',
            iconColor: const Color(0xFF10B981),
            label: 'Pickup',
            address: orderData["pickupAddress"] as String,
            theme: theme,
          ),
          Padding(
            padding: EdgeInsets.only(left: 5.w, top: 4, bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 1.5,
                  height: 20,
                  color: theme.colorScheme.outlineVariant,
                ),
              ],
            ),
          ),
          _AddressRow(
            iconName: 'location_on',
            iconColor: const Color(0xFFDC2626),
            label: 'Delivery',
            address: orderData["deliveryAddress"] as String,
            theme: theme,
          ),
          Divider(height: 2.h, color: theme.colorScheme.outlineVariant),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'lock',
                      color: const Color(0xFFF59E0B),
                      size: 16,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Delivery PIN',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: const Color(0xFFF59E0B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      orderData["deliveryPin"] as String,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFFF59E0B),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 6,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.8.h),
                Text(
                  'Share this PIN with the courier only after you have inspected and received your package.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final String iconName;
  final Color iconColor;
  final String label;
  final String address;
  final ThemeData theme;

  const _AddressRow({
    required this.iconName,
    required this.iconColor,
    required this.label,
    required this.address,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomIconWidget(iconName: iconName, color: iconColor, size: 18),
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
                address,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}


