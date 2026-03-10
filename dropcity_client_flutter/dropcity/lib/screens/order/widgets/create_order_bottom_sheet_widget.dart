import '../../../core/app_export.dart';

class CreateOrderBottomSheetWidget extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final VoidCallback onSubmit;
  final ThemeData theme;

  const CreateOrderBottomSheetWidget({
    super.key,
    required this.orderData,
    required this.onSubmit,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Order Summary',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 2.h),
          _SummaryRow(
            label: 'Pickup',
            value: orderData["pickup"] as String,
            theme: theme,
          ),
          SizedBox(height: 1.5.h),
          _SummaryRow(
            label: 'Delivery',
            value: orderData["delivery"] as String,
            theme: theme,
          ),
          SizedBox(height: 1.5.h),
          _SummaryRow(
            label: 'Size',
            value: orderData["size"] as String,
            theme: theme,
          ),
          SizedBox(height: 1.5.h),
          _SummaryRow(
            label: 'Estimated Cost',
            value: orderData["cost"] as String,
            theme: theme,
            isHighlight: true,
          ),
          SizedBox(height: 3.h),
          SizedBox(
            width: double.infinity,
            height: 5.5.h,
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Confirm Order',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final bool isHighlight;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.theme,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isHighlight ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}

