import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class AddressInputWidget extends StatelessWidget {
  final TextEditingController pickupController;
  final TextEditingController deliveryController;

  const AddressInputWidget({
    super.key,
    required this.pickupController,
    required this.deliveryController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Addresses',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        _AddressField(
          controller: pickupController,
          label: 'Pickup Location',
          hint: 'Enter pickup address',
          iconName: 'location_on',
          iconColor: const Color(0xFF059669),
        ),
        SizedBox(height: 1.5.h),
        _AddressField(
          controller: deliveryController,
          label: 'Delivery Location',
          hint: 'Enter delivery address',
          iconName: 'flag',
          iconColor: const Color(0xFFDC2626),
        ),
      ],
    );
  }
}

class _AddressField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String iconName;
  final Color iconColor;

  const _AddressField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.iconName,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: CustomIconWidget(
            iconName: iconName,
            color: iconColor,
            size: 20,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      ),
    );
  }
}