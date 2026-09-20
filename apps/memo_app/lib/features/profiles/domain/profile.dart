import 'package:equatable/equatable.dart';
import 'package:memo/features/catalog/domain/catalog.dart';

enum ProfileType {
  child,
  teen,
  adult,
  caregiver;

  Audience get audience => switch (this) {
        ProfileType.child => Audience.child,
        ProfileType.teen => Audience.teen,
        ProfileType.adult => Audience.adult,
        ProfileType.caregiver => Audience.all,
      };
}

class Profile extends Equatable {
  const Profile({
    required this.id,
    required this.name,
    required this.type,
    required this.level,
    required this.language,
  });

  final int id;
  final String name;
  final ProfileType type;
  final Level level;
  final String language;

  @override
  List<Object?> get props => [id, name, type, level, language];
}
