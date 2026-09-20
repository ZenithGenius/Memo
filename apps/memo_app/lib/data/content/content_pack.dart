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
  });
  final String code;
  final int sortOrder;
  final String? iconName;
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
  });
  final String code;
  final String categoryCode;
  final int minLevel;
  final String audience;
  final int sortOrder;
  final String? imageAsset;
  final Map<String, PackLabel> labels;
}

/// Paquet de contenu versionné : même format pour le contenu embarqué (M1)
/// et les futures mises à jour téléchargées (M2).
class ContentPack {
  const ContentPack({
    required this.version,
    required this.categories,
    required this.pictograms,
  });

  factory ContentPack.fromJson(Map<String, Object?> json) {
    final categories = (json['categories']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .map(
          (c) => PackCategory(
            code: c['code']! as String,
            sortOrder: c['sortOrder']! as int,
            iconName: c['icon'] as String?,
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
    return ContentPack(
      version: json['version']! as int,
      categories: categories,
      pictograms: pictograms,
    );
  }

  final int version;
  final List<PackCategory> categories;
  final List<PackPictogram> pictograms;
}
