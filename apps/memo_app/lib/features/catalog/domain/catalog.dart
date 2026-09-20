import 'package:equatable/equatable.dart';

enum Level { beginner, intermediate, advanced }

enum Audience { child, teen, adult, all }

class Category extends Equatable {
  const Category({
    required this.id,
    required this.code,
    required this.label,
    required this.sortOrder,
    this.iconName,
  });

  final int id;
  final String code;
  final String label;
  final String? iconName;
  final int sortOrder;

  @override
  List<Object?> get props => [id, code, label, iconName, sortOrder];
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
  ];
}
