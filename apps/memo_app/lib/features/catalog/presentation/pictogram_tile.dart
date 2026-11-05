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
    this.accent,
    this.labelInImage = false,
    this.labelSize = 14,
    this.selected = false,
    super.key,
  });

  final String label;
  final String? imageAsset;
  final IconData? icon;

  /// Couleur de la catégorie : fond teinté, bordure épaisse et icône, pour
  /// reconnaître la catégorie d'un coup d'œil (favoris, tableau mélangés).
  final Color? accent;

  /// Le mot est déjà dans l'image : pas de légende en double.
  final bool labelInImage;

  /// Taille de l'étiquette en points logiques (voir `labelSize`).
  final double labelSize;
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
      child: Stack(
        children: [
          Material(
            // ponytail: teinte légère, le texte sombre garde son contraste.
            color: accent == null
                ? AppColors.card
                : Color.alphaBlend(
                    accent!.withValues(alpha: 0.14),
                    AppColors.card,
                  ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: selected
                    ? AppColors.terracotta
                    : accent ?? AppColors.border,
                width: selected || accent != null ? 4 : 2,
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
                              ? Image.asset(
                                  imageAsset!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => _fallbackIcon(),
                                )
                              : _fallbackIcon(),
                        ),
                      ),
                      if (!labelInImage) ...[
                        const SizedBox(height: 4),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: labelSize,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Favori : l'étoile le distingue même quand la couleur de la
          // catégorie est proche de celle de la sélection.
          if (selected)
            const Positioned(
              top: 6,
              right: 6,
              child: IgnorePointer(
                child: Icon(Icons.star, size: 20, color: AppColors.terracotta),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fallbackIcon() => Icon(
    icon ?? Icons.image_outlined,
    size: 40,
    color: accent ?? AppColors.terracotta,
  );
}
