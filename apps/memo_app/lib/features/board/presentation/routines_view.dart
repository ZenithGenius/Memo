import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/core/theme/app_colors.dart';
import 'package:memo/features/board/domain/routine.dart';
import 'package:memo/features/board/presentation/board_screen.dart';
import 'package:memo/features/caregiver/presentation/caregiver_gate.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/catalog/presentation/pictogram_tile.dart';
import 'package:memo/features/message/presentation/message_notifier.dart';
import 'package:memo/features/settings/domain/app_settings.dart';
import 'package:memo/features/settings/presentation/settings_providers.dart';
import 'package:memo/l10n/app_localizations.dart';

/// Routines du profil (#37) : une ligne d'étapes par moment de la journée.
/// L'enfant touche une étape pour l'entendre et la coche quand elle est faite ;
/// créer, renommer, modifier ou supprimer une routine est réservé à
/// l'accompagnant. Les étapes cochées repartent à zéro chaque jour.
class RoutinesView extends ConsumerWidget {
  const RoutinesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final routines = ref.watch(routinesProvider).value;
    final pictograms = ref.watch(routinePictogramsProvider).value ?? const {};
    if (routines == null) return const SizedBox.shrink();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (routines.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              l10n.routineEmpty,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedText),
            ),
          ),
        for (final r in routines)
          _RoutineCard(routine: r, pictograms: pictograms),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _create(context, ref),
          icon: const Icon(Icons.add),
          label: Text(l10n.routineNew),
        ),
      ],
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(activeProfileProvider).value;
    if (profile == null || !await requireCaregiver(context, ref)) return;
    if (!context.mounted) return;
    final name = await _askName(context);
    if (name == null || !context.mounted) return;
    final repo = ref.read(routineRepositoryProvider);
    final id = await repo.create(profile.id, name);
    if (!context.mounted) return;
    await _editSteps(context, Routine(id: id, name: name, steps: const []));
  }
}

class _RoutineCard extends ConsumerWidget {
  const _RoutineCard({required this.routine, required this.pictograms});
  final Routine routine;
  final Map<int, Pictogram> pictograms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(routineRepositoryProvider);
    // ponytail: jour lu à chaque construction ; un écran resté ouvert passé
    // minuit se met à jour au prochain affichage.
    final now = DateTime.now();
    final steps = routine.steps;
    final done = steps.where((s) => s.doneOnDay(now)).length;
    final finished = steps.isNotEmpty && done == steps.length;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    routine.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (steps.isNotEmpty)
                  Text(
                    l10n.routineProgress(done, steps.length),
                    style: const TextStyle(color: AppColors.mutedText),
                  ),
                if (done > 0)
                  IconButton(
                    tooltip: l10n.routineRestart,
                    icon: const Icon(Icons.replay),
                    onPressed: () => repo.reset(routine.id),
                  ),
                _menu(context, ref, l10n),
              ],
            ),
            if (finished)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.routineFinished,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            if (steps.isEmpty)
              Text(
                l10n.routineNoSteps,
                style: const TextStyle(color: AppColors.mutedText),
              )
            else
              SizedBox(
                height: 184,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 12),
                  itemCount: steps.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) =>
                      _step(context, ref, l10n, i, steps[i], now),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _step(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    int index,
    RoutineStep step,
    DateTime now,
  ) {
    final p = pictograms[step.pictogramId];
    final isDone = step.doneOnDay(now);
    return SizedBox(
      width: 120,
      child: Column(
        children: [
          Expanded(
            // Deux cibles distinctes pour les lecteurs d'écran : entendre
            // l'étape, la cocher.
            child: Semantics(
              container: true,
              child: Opacity(
                opacity: isDone ? 0.45 : 1,
                child: PictogramTile(
                  label: p?.label ?? '',
                  imageAsset: p?.imageAsset,
                  labelInImage: p?.labelInImage ?? false,
                  accent: p?.colorArgb == null ? null : Color(p!.colorArgb!),
                  icon: Icons.chat_bubble_outline,
                  onTap: () {
                    if (p == null) return;
                    final language =
                        ref.read(activeProfileProvider).value?.language ?? 'fr';
                    ref
                        .read(speechServiceProvider)
                        .speak(p.spokenText, language: language);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            container: true,
            label: l10n.routineStep(
              index + 1,
              routine.steps.length,
              p?.label ?? '',
            ),
            child: FilterChip(
              label: Text(l10n.routineStepDone),
              selected: isDone,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              onSelected: (_) {
                final settings =
                    ref.read(appSettingsProvider).asData?.value ??
                    AppSettings.defaults;
                if (settings.hapticsEnabled) HapticFeedback.selectionClick();
                ref
                    .read(routineRepositoryProvider)
                    .toggleStep(routine.id, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _menu(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final repo = ref.read(routineRepositoryProvider);
    return IconButton(
      tooltip: l10n.routineOptions(routine.name),
      icon: const Icon(Icons.more_vert),
      onPressed: () async {
        if (!await requireCaregiver(context, ref) || !context.mounted) return;
        final action = await showModalBottomSheet<String>(
          context: context,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_note),
                  title: Text(l10n.routineEditSteps),
                  onTap: () => Navigator.of(context).pop('steps'),
                ),
                ListTile(
                  leading: const Icon(Icons.drive_file_rename_outline),
                  title: Text(l10n.routineRename),
                  onTap: () => Navigator.of(context).pop('rename'),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: Text(l10n.routineDelete),
                  onTap: () => Navigator.of(context).pop('delete'),
                ),
              ],
            ),
          ),
        );
        if (!context.mounted) return;
        switch (action) {
          case 'steps':
            await _editSteps(context, routine);
          case 'rename':
            final name = await _askName(context, initial: routine.name);
            if (name != null) await repo.rename(routine.id, name);
          case 'delete':
            final ok = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                content: Text(l10n.routineDeleteConfirm(routine.name)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(l10n.routineDelete),
                  ),
                ],
              ),
            );
            if (ok ?? false) await repo.delete(routine.id);
        }
      },
    );
  }
}

Future<String?> _askName(BuildContext context, {String initial = ''}) =>
    showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(initial: initial),
    );

/// Le champ vit avec la boîte de dialogue : son contrôleur n'est libéré
/// qu'une fois l'animation de fermeture terminée.
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.routineName),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 40,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: l10n.routineNameHint),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(onPressed: _submit, child: Text(l10n.routineSave)),
      ],
    );
  }
}

Future<void> _editSteps(BuildContext context, Routine routine) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => _StepsEditor(routine: routine)));

/// Étapes d'une routine : ajouter, retirer, réordonner. Chaque changement
/// est enregistré aussitôt.
class _StepsEditor extends ConsumerStatefulWidget {
  const _StepsEditor({required this.routine});
  final Routine routine;

  @override
  ConsumerState<_StepsEditor> createState() => _StepsEditorState();
}

class _StepsEditorState extends ConsumerState<_StepsEditor> {
  late final List<int> _ids = [
    for (final s in widget.routine.steps) s.pictogramId,
  ];

  Future<void> _save() => ref
      .read(routineRepositoryProvider)
      .setSteps(widget.routine.id, List.of(_ids));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pictograms = ref.watch(routinePictogramsProvider).value ?? const {};
    return Scaffold(
      appBar: AppBar(title: Text(l10n.routineStepsTitle(widget.routine.name))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final picked = await showPictogramPicker(context, allowClear: false);
          final id = picked?.id;
          if (id == null) return;
          setState(() => _ids.add(id));
          await _save();
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.routineAddStep),
      ),
      body: _ids.isEmpty
          ? Center(child: Text(l10n.routineNoSteps))
          : ReorderableListView(
              padding: const EdgeInsets.only(bottom: 96),
              onReorderItem: (from, to) {
                setState(() => _ids.insert(to, _ids.removeAt(from)));
                _save();
              },
              children: [
                for (final (i, id) in _ids.indexed)
                  ListTile(
                    key: ValueKey('$i-$id'),
                    leading: CircleAvatar(child: Text('${i + 1}')),
                    title: Text(pictograms[id]?.label ?? ''),
                    trailing: IconButton(
                      tooltip: l10n.routineRemoveStep(
                        pictograms[id]?.label ?? '',
                      ),
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        setState(() => _ids.removeAt(i));
                        _save();
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}
