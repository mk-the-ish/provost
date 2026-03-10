import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Navigation items for the delivery tracking app bottom bar
enum BottomNavItem { createOrder, track, orders, profile }

/// Extension to provide metadata for each nav item
extension BottomNavItemExtension on BottomNavItem {
  String get label {
    switch (this) {
      case BottomNavItem.createOrder:
        return 'Create';
      case BottomNavItem.track:
        return 'Track';
      case BottomNavItem.orders:
        return 'Orders';
      case BottomNavItem.profile:
        return 'Profile';
    }
  }

  IconData get icon {
    switch (this) {
      case BottomNavItem.createOrder:
        return Icons.add_circle_outline_rounded;
      case BottomNavItem.track:
        return Icons.location_on_outlined;
      case BottomNavItem.orders:
        return Icons.list_alt_outlined;
      case BottomNavItem.profile:
        return Icons.person_outline_rounded;
    }
  }

  IconData get activeIcon {
    switch (this) {
      case BottomNavItem.createOrder:
        return Icons.add_circle_rounded;
      case BottomNavItem.track:
        return Icons.location_on_rounded;
      case BottomNavItem.orders:
        return Icons.list_alt_rounded;
      case BottomNavItem.profile:
        return Icons.person_rounded;
    }
  }
}

/// A reusable, parameterized bottom navigation bar for the delivery tracking app.
///
/// Usage:
/// ```dart
/// CustomBottomBar(
///   currentIndex: _currentIndex,
///   onTap: (index) => setState(() => _currentIndex = index),
/// )
/// ```
class CustomBottomBar extends StatelessWidget {
  /// The index of the currently selected tab.
  final int currentIndex;

  /// Callback invoked when a tab is tapped.
  final Function(int) onTap;

  /// Optional badge counts for each navigation item (index-based).
  /// Pass null or 0 to hide badge.
  final Map<int, int>? badgeCounts;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.badgeCounts,
  });

  void _handleTap(BuildContext context, int index) {
    HapticFeedback.lightImpact();
    onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final selectedColor = theme.colorScheme.primary;
    final unselectedColor = isDark
        ? const Color(0xFF64748B)
        : const Color(0xFF94A3B8);
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x29000000) : const Color(0x0F000000),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(BottomNavItem.values.length, (index) {
              final item = BottomNavItem.values[index];
              final isSelected = currentIndex == index;
              final badgeCount = badgeCounts?[index] ?? 0;

              return Expanded(
                child: _NavBarItem(
                  item: item,
                  isSelected: isSelected,
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                  badgeCount: badgeCount,
                  onTap: () => _handleTap(context, index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final BottomNavItem item;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? selectedColor : unselectedColor;

    return Semantics(
      label: item.label,
      selected: isSelected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? selectedColor.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isSelected ? item.activeIcon : item.icon,
                        key: ValueKey(isSelected),
                        color: color,
                        size: 24,
                      ),
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        top: -4,
                        right: -6,
                        child: _Badge(count: badgeCount),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: color,
                  letterSpacing: 0.2,
                ),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;

  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
