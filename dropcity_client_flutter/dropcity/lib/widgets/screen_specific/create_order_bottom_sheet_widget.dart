import '../../core/app_export.dart';
import '../custom_icon_widget.dart';
import './address_input_widget.dart';
import './size_selector_widget.dart';

class CreateOrderBottomSheetWidget extends StatelessWidget {
  final ScrollController scrollController;
  final TextEditingController pickupController;
  final TextEditingController deliveryController;
  final String selectedSize;
  final bool isCreatingOrder;
  final ValueChanged<String> onSizeChanged;
  final VoidCallback onCreateOrder;

  const CreateOrderBottomSheetWidget({
    super.key,
    required this.scrollController,
    required this.pickupController,
    required this.deliveryController,
    required this.selectedSize,
    required this.isCreatingOrder,
    required this.onSizeChanged,
    required this.onCreateOrder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        children: [
          Center(
            child: Container(
              width: 10.w,
              height: 4,
              margin: EdgeInsets.only(bottom: 1.5.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              CustomIconWidget(
                iconName: 'local_shipping',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Create Delivery Order',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          AddressInputWidget(
            pickupController: pickupController,
            deliveryController: deliveryController,
          ),
          SizedBox(height: 2.h),
          SizeSelectorWidget(
            selectedSize: selectedSize,
            onSizeChanged: onSizeChanged,
          ),
          SizedBox(height: 2.h),
          _PricingEstimateWidget(selectedSize: selectedSize),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            height: 6.h,
            child: ElevatedButton(
              onPressed: isCreatingOrder ? null : onCreateOrder,
              child: isCreatingOrder
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        const Text('Creating Order...'),
                      ],
                    )
                  : const Text('Create Order'),
            ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }
}

class _PricingEstimateWidget extends StatelessWidget {
  final String selectedSize;

  const _PricingEstimateWidget({required this.selectedSize});

  String get _estimatedPrice {
    switch (selectedSize) {
      case 'Small':
        return '\$4.99 - \$7.99';
      case 'Medium':
        return '\$8.99 - \$14.99';
      case 'Large':
        return '\$15.99 - \$24.99';
      case 'XL':
        return '\$25.99 - \$39.99';
      default:
        return '\$4.99 - \$7.99';
    }
  }

  String get _estimatedTime {
    switch (selectedSize) {
      case 'Small':
        return '30-45 min';
      case 'Medium':
        return '45-60 min';
      case 'Large':
        return '60-90 min';
      case 'XL':
        return '90-120 min';
      default:
        return '30-45 min';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated Price',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  _estimatedPrice,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 36, color: theme.colorScheme.outline),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated Time',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _estimatedTime,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
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

