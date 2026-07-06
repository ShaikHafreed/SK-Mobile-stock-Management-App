import 'package:flutter/material.dart';

class MagicNavItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const MagicNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

/// Floating pill-shaped bottom navigation bar with a
/// raised circular highlight on the active item.
class MagicNavBar extends StatelessWidget {
  final List<MagicNavItem> items;
  final int currentIndex;
  final Color color;

  const MagicNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    this.color = const Color(0xFF1565C0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceEvenly,
          children: [
            for (int i = 0; i < items.length; i++)
              _MagicNavIcon(
                item: items[i],
                isActive: i == currentIndex,
              ),
          ],
        ),
      ),
    );
  }
}

class _MagicNavIcon extends StatelessWidget {
  final MagicNavItem item;
  final bool isActive;

  const _MagicNavIcon({
    required this.item,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        height: 68,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(
                  0, isActive ? -14 : 0, 0),
              width: isActive ? 48 : 32,
              height: isActive ? 48 : 32,
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white
                    : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                item.icon,
                color: isActive
                    ? Colors.blue.shade900
                    : Colors.white70,
                size: isActive ? 24 : 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
