import '../../core/app_export.dart';
import '../custom_icon_widget.dart';

class SizeSelectorWidget extends StatelessWidget {
  final String selectedSize;
  final ValueChanged<String> onSizeChanged;

  const SizeSelectorWidget({
    super.key,
    required this.selectedSize,
    required this.onSizeChanged,
  });

  static const List<Map<String, dynamic>> _sizes = [
    {
      'label': 'Small',
      'subtitle': 'Envelope',
      'icon': 'mail_outline',
      'description': 'Up to 0.5 kg',
    },
    {
      'label': 'Medium',
      'subtitle': 'Shoe box',
      'icon': 'inventory_2',
      'description': 'Up to 5 kg',
    },
    {
      'label': 'Large',
      'subtitle': 'Backpack',
      'icon': 'backpack',
      'description': 'Up to 15 kg',
    },
    {
      'label': 'XL',
      'subtitle': 'Suitcase',
      'icon': 'business_center',
      'description': 'Up to 30 kg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Package Size',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        SizedBox(
          height: 11.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _sizes.length,
            separatorBuilder: (_, __) => SizedBox(width: 2.w),
            itemBuilder: (context, index) {
              final size = _sizes[index];
              final isSelected = selectedSize == size['label'];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSizeChanged(size['label'] as String);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20.w,
                  padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: size['icon'] as String,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        size['label'] as String,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        size['subtitle'] as String,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

