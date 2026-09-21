import 'package:equatable/equatable.dart';

class QuickPhrase extends Equatable {
  const QuickPhrase({
    required this.id,
    required this.text,
    required this.tags,
    required this.isCustom,
  });

  final int id;
  final String text;
  final List<String> tags;

  /// Créée par l'utilisateur, par opposition aux phrases livrées.
  final bool isCustom;

  @override
  List<Object?> get props => [id, text, tags, isCustom];
}
