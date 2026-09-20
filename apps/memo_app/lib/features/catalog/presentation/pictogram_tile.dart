import 'package:flutter/material.dart';
import 'package:memo/core/theme/app_colors.dart';

/// Tuile de grille : image (ou icône provisoire) et mot séparé sous l'image.
class PictogramTile extends StatelessWidget {
  const PictogramTile({
    required this.label,
    required this.onTap,
    this.onLongPress,
    this.imageAsset,
    this.icon,
    this.selected = false,
    super.key,
  });

  final String label;
  final String? imageAsset;
  final IconData? icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      selected: selected,
      excludeSemantics: true,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? AppColors.terracotta : AppColors.border,
            width: 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          onLongPress: onLongPress,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 96, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: imageAsset != null
                          ? Image.asset(imageAsset!, fit: BoxFit.contain)
                          : Icon(
                              icon ?? Icons.image_outlined,
                              size: 40,
                              color: AppColors.terracotta,
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
