import 'package:equatable/equatable.dart';

enum Level { beginner, intermediate, advanced }

enum Audience { child, teen, adult, all }

/// Palier du contenu : gratuit (livré) ou payant (téléchargé, ADR-008).
enum Tier { free, premium }

class Category extends Equatable {
  const Category({
    required this.id,
    required this.code,
    required this.label,
    required this.sortOrder,
    this.iconName,
    this.colorArgb,
  });

  final int id;
  final String code;
  final String label;
  final String? iconName;
  final int sortOrder;

  /// Couleur ARGB de la catégorie, sans dépendance à Flutter.
  final int? colorArgb;

  @override
  List<Object?> get props => [id, code, label, iconName, sortOrder, colorArgb];
}

class Pictogram extends Equatable {
  const Pictogram({
    required this.id,
    required this.code,
    required this.categoryId,
    required this.label,
    required this.spokenText,
    required this.minLevel,
    required this.audience,
    required this.sortOrder,
    this.imageAsset,
    this.tier = Tier.free,
    this.colorArgb,
    this.labelInImage = false,
  });

  final int id;
  final String code;
  final int categoryId;
  final String label;
  final String spokenText;
  final String? imageAsset;
  final Level minLevel;
  final Audience audience;
  final int sortOrder;
  final Tier tier;

  /// Couleur de la catégorie du pictogramme.
  final int? colorArgb;

  /// Le mot est déjà écrit dans l'image (démonstration) : pas de légende.
  final bool labelInImage;

  @override
  List<Object?> get props => [
    id,
    code,
    categoryId,
    label,
    spokenText,
    imageAsset,
    minLevel,
    audience,
    sortOrder,
    tier,
    colorArgb,
    labelInImage,
  ];
}
