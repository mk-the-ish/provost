import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class DeliveryMarkerWidget extends StatelessWidget {
  final int index;
  final String status;

  const DeliveryMarkerWidget({
    super.key,
    required this.index,
    required this.status,
  });

  Color _statusColor() {
    switch (status) {
      case 'pending':
        return AppTheme.warningColor;
      case 'picked_up':
        return AppTheme.primaryLight;
      case 'delivered':
        return AppTheme.successColor;
      default:
        return AppTheme.secondaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10.w,
      height: 10.w,
      decoration: BoxDecoration(
        color: _statusColor(),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
