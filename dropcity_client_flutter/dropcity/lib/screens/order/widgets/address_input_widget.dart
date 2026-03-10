import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class AddressInputWidget extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onLocationTap;

  const AddressInputWidget({
    super.key,
    required this.label,
    required this.controller,
    required this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 0.8.h),
        TextField(
          controller: controller,
          maxLines: 2,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Enter ${label.toLowerCase()}',
            hintStyle: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            prefixIcon: Icon(
              label.contains('Pickup') ? Icons.location_on : Icons.pin_drop,
              color: label.contains('Pickup')
                  ? const Color(0xFF10B981)
                  : const Color(0xFFDC2626),
            ),
            suffixIcon: IconButton(
              icon: CustomIconWidget(
                iconName: 'map',
                color: theme.colorScheme.primary,
                size: 20,
              ),
              onPressed: onLocationTap,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
          ),
        ),
      ],
    );
  }
}

