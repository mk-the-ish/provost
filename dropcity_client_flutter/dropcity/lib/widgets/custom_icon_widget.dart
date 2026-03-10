import 'package:flutter/material.dart';

class CustomIconWidget extends StatelessWidget {
  final String iconName;
  final double size;
  final Color? color;

  const CustomIconWidget({
    super.key,
    required this.iconName,
    this.size = 24,
    this.color,
  });

  static const Map<String, IconData> _iconMap = {
    'add': Icons.add,
    'arrow_back': Icons.arrow_back,
    'arrow_forward': Icons.arrow_forward,
    'call': Icons.call,
    'chat': Icons.chat,
    'check_circle': Icons.check_circle,
    'clock': Icons.access_time,
    'description': Icons.description,
    'error_outline': Icons.error_outline,
    'flag': Icons.flag,
    'local_shipping': Icons.local_shipping,
    'location_on': Icons.location_on,
    'lock': Icons.lock,
    'map': Icons.map,
    'message': Icons.message,
    'my_location': Icons.my_location,
    'radio_button_checked': Icons.radio_button_checked,
    'refresh': Icons.refresh,
    'star': Icons.star,
    'star_filled': Icons.star,
  };

  @override
  Widget build(BuildContext context) {
    return Icon(
      _iconMap[iconName] ?? Icons.help_outline,
      size: size,
      color: color ?? (_iconMap.containsKey(iconName) ? null : Colors.grey),
      semanticLabel: _iconMap.containsKey(iconName)
          ? iconName
          : 'Icon not found: $iconName',
    );
  }
}
