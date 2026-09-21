class PackLabel {
  const PackLabel({required this.label, required this.spoken});
  final String label;
  final String spoken;
}

class PackCategory {
  const PackCategory({
    required this.code,
    required this.sortOrder,
    required this.labels,
    this.iconName,
    this.color,
  });
  final String code;
  final int sortOrder;
  final String? iconName;

  /// Couleur de regroupement `#RRGGBB` : les symboles d'une même catégorie
  /// partagent leur couleur, ce qui accélère la recherche visuelle.
  final String? color;
  final Map<String, String> labels;
}

class PackPictogram {
  const PackPictogram({
    required this.code,
    required this.categoryCode,
    required this.minLevel,
    required this.audience,
    required this.sortOrder,
    required this.labels,
    this.imageAsset,
    this.tier = 'free',
    this.labelInImage = false,
  });
  final String code;
  final String categoryCode;
  final int minLevel;
  final String audience;
  final int sortOrder;
  final String? imageAsset;

  /// `free` (livré dans l'application) ou `premium` (ADR-008).
  final String tier;

  /// Vrai si le mot est écrit dans l'image (échantillons de démonstration) :
  /// l'application n'affiche alors pas de légende en double.
  final bool labelInImage;
  final Map<String, PackLabel> labels;
}

class PackPhrase {
  const PackPhrase({
    required this.code,
    required this.sortOrder,
    required this.texts,
  });
  final String code;
  final int sortOrder;

  /// Par langue : texte et thèmes.
  final Map<String, PackPhraseText> texts;
}

class PackPhraseText {
  const PackPhraseText({required this.text, required this.tags});
  final String text;
  final List<String> tags;
}

/// Paquet de contenu versionné : même format pour le contenu embarqué (M1)
/// et les futures mises à jour téléchargées (M2).
class ContentPack {
  const ContentPack({
    required this.version,
    required this.categories,
    required this.pictograms,
    this.phrases = const [],
  });

  factory ContentPack.fromJson(Map<String, Object?> json) {
    final categories = (json['categories']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .map(
          (c) => PackCategory(
            code: c['code']! as String,
            sortOrder: c['sortOrder']! as int,
            iconName: c['icon'] as String?,
            color: c['color'] as String?,
            labels: (c['labels']! as Map<String, Object?>)
                .cast<String, String>(),
          ),
        )
        .toList();
    final pictograms = (json['pictograms']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .map(
          (p) => PackPictogram(
            code: p['code']! as String,
            categoryCode: p['category']! as String,
            minLevel: p['level']! as int,
            audience: p['audience']! as String,
            sortOrder: p['sortOrder']! as int,
            imageAsset: p['image'] as String?,
            tier: (p['tier'] as String?) ?? 'free',
            labelInImage: (p['labelInImage'] as bool?) ?? false,
            labels: (p['labels']! as Map<String, Object?>).map((lang, v) {
              final m = v! as Map<String, Object?>;
              return MapEntry(
                lang,
                PackLabel(
                  label: m['label']! as String,
                  spoken: m['spoken']! as String,
                ),
              );
            }),
          ),
        )
        .toList();
    final phrases = ((json['phrases'] as List<Object?>?) ?? const [])
        .cast<Map<String, Object?>>()
        .map(
          (p) => PackPhrase(
            code: p['code']! as String,
            sortOrder: p['sortOrder']! as int,
            texts: (p['texts']! as Map<String, Object?>).map((lang, v) {
              final m = v! as Map<String, Object?>;
              return MapEntry(
                lang,
                PackPhraseText(
                  text: m['text']! as String,
                  tags: ((m['tags'] as List<Object?>?) ?? const [])
                      .cast<String>(),
                ),
              );
            }),
          ),
        )
        .toList();
    return ContentPack(
      version: json['version']! as int,
      categories: categories,
      pictograms: pictograms,
      phrases: phrases,
    );
  }

  final int version;
  final List<PackCategory> categories;
  final List<PackPictogram> pictograms;
  final List<PackPhrase> phrases;
}
