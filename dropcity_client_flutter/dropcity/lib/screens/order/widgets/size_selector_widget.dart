import '../../../core/app_export.dart';

class SizeSelectorWidget extends StatefulWidget {
  final Function(String) onSizeSelected;

  const SizeSelectorWidget({
    super.key,
    required this.onSizeSelected,
  });

  @override
  State<SizeSelectorWidget> createState() => _SizeSelectorWidgetState();
}

class _SizeSelectorWidgetState extends State<SizeSelectorWidget> {
  String _selectedSize = 'small';

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
          ),
        ),
        SizedBox(height: 1.2.h),
        Row(
          children: [
            _SizeOption(
              label: 'Small',
              value: 'small',
              isSelected: _selectedSize == 'small',
              theme: theme,
              onTap: () {
                setState(() => _selectedSize = 'small');
                widget.onSizeSelected('small');
              },
            ),
            SizedBox(width: 2.w),
            _SizeOption(
              label: 'Medium',
              value: 'medium',
              isSelected: _selectedSize == 'medium',
              theme: theme,
              onTap: () {
                setState(() => _selectedSize = 'medium');
                widget.onSizeSelected('medium');
              },
            ),
            SizedBox(width: 2.w),
            _SizeOption(
              label: 'Large',
              value: 'large',
              isSelected: _selectedSize == 'large',
              theme: theme,
              onTap: () {
                setState(() => _selectedSize = 'large');
                widget.onSizeSelected('large');
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _SizeOption extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final ThemeData theme;
  final VoidCallback onTap;

  const _SizeOption({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 1.2.h),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : theme.colorScheme.surface,
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

