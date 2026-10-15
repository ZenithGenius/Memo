import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memo/core/theme/app_colors.dart';
import 'package:memo/core/ui/adaptive_grid.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/l10n/app_localizations.dart';

/// Délai avant d'afficher un état de chargement : les lectures locales
/// (SQLite) finissent presque toujours avant, l'écran ne clignote pas.
const loadingRevealDelay = Duration(milliseconds: 200);

/// Emplacements statiques à la forme des tuiles, à la place d'un indicateur
/// qui tourne. Pas d'animation : public sensible aux stimulations visuelles.
class LoadingTiles extends StatefulWidget {
  const LoadingTiles({
    super.key,
    this.level = Level.intermediate,
    this.count = 6,
  }) : rows = false;

  /// Variante en lignes, pour les écrans de liste (phrases, statistiques).
  const LoadingTiles.rows({super.key, this.count = 5})
    : level = Level.intermediate,
      rows = true;

  final Level level;
  final int count;
  final bool rows;

  @override
  State<LoadingTiles> createState() => _LoadingTilesState();
}

class _LoadingTilesState extends State<LoadingTiles> {
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(loadingRevealDelay, () => setState(() => _visible = true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).loadingContent,
      liveRegion: true,
      child: !_visible
          ? const SizedBox.expand()
          : ExcludeSemantics(
              child: widget.rows
                  ? ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.count,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, _) =>
                          const SizedBox(height: 64, child: _Placeholder()),
                    )
                  : GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      gridDelegate: adaptiveGridDelegate(widget.level),
                      itemCount: widget.count,
                      itemBuilder: (_, _) => const _Placeholder(),
                    ),
            ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.border.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(18),
    ),
  );
}

/// État d'erreur d'un écran : message compréhensible et bouton pour
/// réessayer. L'erreur technique va au journal, jamais à l'écran (un enfant
/// ou un accompagnant n'a que faire d'une trace SQLite).
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    debugPrint('ErrorState: $error');
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: AppColors.mutedText,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.errorTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.errorHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedText,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                style: FilledButton.styleFrom(minimumSize: const Size(160, 48)),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.errorRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
