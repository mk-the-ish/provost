import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Navigation items for the courier delivery app bottom bar
enum BottomNavItem { dashboard, orders, profile }

class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x28000000) : const Color(0x1464748B),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF2563EB),
          unselectedItemColor: isDark
              ? const Color(0xFF94A3B8)
              : const Color(0xFF64748B),
          selectedLabelStyle: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
          ),
          items: [
            BottomNavigationBarItem(
              icon: _NavIcon(
                icon: Icons.map_outlined,
                isActive: currentIndex == 0,
                isDark: isDark,
              ),
              activeIcon: _NavIcon(
                icon: Icons.map_rounded,
                isActive: true,
                isDark: isDark,
              ),
              label: 'Dashboard',
              tooltip: 'Active Delivery Dashboard',
            ),
            BottomNavigationBarItem(
              icon: _NavIcon(
                icon: Icons.receipt_long_outlined,
                isActive: currentIndex == 1,
                isDark: isDark,
              ),
              activeIcon: _NavIcon(
                icon: Icons.receipt_long_rounded,
                isActive: true,
                isDark: isDark,
              ),
              label: 'Orders',
              tooltip: 'Route Declaration & Orders',
            ),
            BottomNavigationBarItem(
              icon: _NavIcon(
                icon: Icons.person_outline_rounded,
                isActive: currentIndex == 2,
                isDark: isDark,
              ),
              activeIcon: _NavIcon(
                icon: Icons.person_rounded,
                isActive: true,
                isDark: isDark,
              ),
              label: 'Profile',
              tooltip: 'Sync Status & Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final bool isDark;

  const _NavIcon({
    required this.icon,
    required this.isActive,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF2563EB).withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        icon,
        size: 24,
        color: isActive
            ? const Color(0xFF2563EB)
            : isDark
            ? const Color(0xFF94A3B8)
            : const Color(0xFF64748B),
      ),
    );
  }
}
