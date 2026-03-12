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

  @override
  Widget build(BuildContext context) {
    // Map of available icons
    final Map<String, IconData> iconMap = {
      'menu': Icons.menu,
      'close': Icons.close,
      'arrow_back': Icons.arrow_back,
      'arrow_forward': Icons.arrow_forward,
      'phone': Icons.phone,
      'check_circle': Icons.check_circle,
      'skip_next': Icons.skip_next,
      'person': Icons.person,
      'location_on': Icons.location_on,
      'inventory_2': Icons.inventory_2,
      'access_time': Icons.access_time,
      'navigation': Icons.navigation,
      'wifi': Icons.wifi,
      'wifi_off': Icons.wifi_off,
      'local_shipping': Icons.local_shipping,
      'my_location': Icons.my_location,
      'sync': Icons.sync,
      'report_problem': Icons.report_problem,
      'emergency': Icons.emergency_share,
      'camera_alt': Icons.camera_alt,
      'photo_library': Icons.photo_library,
      'lock': Icons.lock,
      'image': Icons.image,
      'route': Icons.route,
      'list_alt': Icons.list_alt,
      'map_outlined': Icons.map_outlined,
      'map_rounded': Icons.map_rounded,
      'receipt_long_outlined': Icons.receipt_long_outlined,
      'receipt_long_rounded': Icons.receipt_long_rounded,
      'person_outline_rounded': Icons.person_outline_rounded,
      'person_rounded': Icons.person_rounded,
      'checklist': Icons.checklist,
      'verified': Icons.verified,
      'radio_button_unchecked': Icons.radio_button_unchecked,
      'check': Icons.check,
      'cloud_done': Icons.cloud_done,
      'schedule': Icons.schedule,
      'gps_fixed': Icons.gps_fixed,
      'lightbulb_outline': Icons.lightbulb_outline,
      'cloud_off': Icons.cloud_off,
      'note': Icons.note,
      'info_outline': Icons.info_outline,
      'cloud_upload': Icons.cloud_upload,
      'replay': Icons.replay,
      'edit_location_alt': Icons.edit_location_alt,
      'trip_origin': Icons.trip_origin,
      'flag': Icons.flag,
      'store': Icons.store,
      'chevron_right': Icons.chevron_right,
      'broken_image': Icons.broken_image,
      'scale': Icons.scale,
      'lightbulb': Icons.lightbulb,
    };

    return Icon(
      iconMap[iconName] ?? Icons.help,
      size: size,
      color: color,
    );
  }
}
