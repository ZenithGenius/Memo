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

/// Choisi à la création du profil : les pictogrammes qui représentent une
/// personne s'affichent alors au féminin ou au masculin (#19).
enum Gender { unspecified, feminine, masculine }

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
    this.imageFeminine,
    this.imageMasculine,
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

  /// Variantes au féminin et au masculin, quand le pictogramme représente une
  /// personne. Absentes : l'image commune sert pour tous.
  final String? imageFeminine;
  final String? imageMasculine;
  final Level minLevel;
  final Audience audience;
  final int sortOrder;
  final Tier tier;

  /// Couleur de la catégorie du pictogramme.
  final int? colorArgb;

  /// Le mot est déjà écrit dans l'image (démonstration) : pas de légende.
  final bool labelInImage;

  /// Image affichée pour un profil : la variante de son genre si elle
  /// existe, sinon l'image commune.
  Pictogram forGender(Gender gender) {
    final variant = switch (gender) {
      Gender.feminine => imageFeminine,
      Gender.masculine => imageMasculine,
      Gender.unspecified => null,
    };
    if (variant == null) return this;
    return Pictogram(
      id: id,
      code: code,
      categoryId: categoryId,
      label: label,
      spokenText: spokenText,
      minLevel: minLevel,
      audience: audience,
      sortOrder: sortOrder,
      imageAsset: variant,
      imageFeminine: imageFeminine,
      imageMasculine: imageMasculine,
      tier: tier,
      colorArgb: colorArgb,
      labelInImage: labelInImage,
    );
  }

  @override
  List<Object?> get props => [
    id,
    code,
    categoryId,
    label,
    spokenText,
    imageAsset,
    imageFeminine,
    imageMasculine,
    minLevel,
    audience,
    sortOrder,
    tier,
    colorArgb,
    labelInImage,
  ];
}
