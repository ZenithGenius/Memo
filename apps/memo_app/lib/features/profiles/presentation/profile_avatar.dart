import 'package:flutter/material.dart';
import 'package:memo/core/theme/app_colors.dart';

/// Initiale du prénom dans un carré sombre, comme dans la maquette.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({required this.name, this.size = 40, super.key});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty
        ? '?'
        : String.fromCharCode(trimmed.runes.first).toUpperCase();
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(size * 0.25),
        ),
        child: Text(
          initial,
          style: TextStyle(
            color: AppColors.sand,
            fontSize: size * 0.45,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
