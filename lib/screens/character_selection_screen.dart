import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../controllers/app_settings_controller.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../models/character.dart';
import '../models/kid_profile.dart';
import '../services/app_audio_service.dart';
import '../widgets/character_card.dart';
import 'camera_game_screen.dart';
import 'settings_screen.dart';

class CharacterSelectionScreen extends StatelessWidget {
  const CharacterSelectionScreen({
    super.key,
    required this.availableCameras,
    required this.settingsController,
  });

  final List<CameraDescription> availableCameras;
  final AppSettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AnimatedBuilder(
      animation: settingsController,
      builder: (context, _) {
        final settings = settingsController.settings;
        return Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFF6E9),
                  Color(0xFFFFE0B5),
                  Color(0xFFB8F2E6),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton.filledTonal(
                            tooltip: l10n.settingsTitle,
                            onPressed: () => _openSettings(context),
                            icon: const Icon(Icons.settings_rounded),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.chooseYourCharacter,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.characterSelectionSubtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: const Color(0xFF5D5A88)),
                        ),
                        const SizedBox(height: 24),
                        _ProfileSelector(
                          settings: settings,
                          onSelect: (profileId) => settingsController.update(
                            settings.copyWith(activeKidProfileId: profileId),
                          ),
                          onAdd: () => _addKidProfile(context),
                          onEdit: (profile) =>
                              _editKidProfile(context, profile),
                        ),
                        const SizedBox(height: 24),
                        CharacterCard(
                          name: l10n.characterName(BrushingCharacter.fox),
                          emoji: BrushingCharacter.fox.emoji,
                          subtitle: l10n.foxDescription,
                          color: const Color(0xFFF28B50),
                          onTap: () =>
                              _openGame(context, BrushingCharacter.fox),
                        ),
                        const SizedBox(height: 20),
                        CharacterCard(
                          name: l10n.characterName(BrushingCharacter.gator),
                          emoji: BrushingCharacter.gator.emoji,
                          subtitle: l10n.gatorDescription,
                          color: const Color(0xFF43B49D),
                          onTap: () =>
                              _openGame(context, BrushingCharacter.gator),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _addKidProfile(BuildContext context) async {
    AppAudioService.instance.play(AppSound.click);
    final profile = await showDialog<_KidProfileDraft>(
      context: context,
      builder: (_) => const _AddKidProfileDialog(),
    );

    final trimmedName = profile?.name.trim();
    if (trimmedName == null || trimmedName.isEmpty) {
      return;
    }

    final settings = settingsController.settings;
    final profileId = 'kid_${DateTime.now().microsecondsSinceEpoch}';
    await settingsController.update(
      settings.copyWith(
        kidProfiles: [
          ...settings.kidProfiles,
          KidProfile(
            id: profileId,
            name: trimmedName,
            avatarEmoji: profile?.avatarEmoji ?? KidProfile.defaultAvatarEmoji,
          ),
        ],
        activeKidProfileId: profileId,
      ),
    );
  }

  Future<void> _editKidProfile(BuildContext context, KidProfile profile) async {
    AppAudioService.instance.play(AppSound.click);
    final editedProfile = await showDialog<_KidProfileDraft>(
      context: context,
      builder: (_) => _AddKidProfileDialog(
        title: context.l10n.editKidProfileTitle,
        initialName: profile.name,
        initialAvatarEmoji: profile.avatarEmoji,
        allowRemove: settingsController.settings.kidProfiles.length > 1,
      ),
    );

    if (editedProfile?.shouldRemove == true) {
      await _removeKidProfile(profile.id);
      return;
    }

    final trimmedName = editedProfile?.name.trim();
    if (trimmedName == null || trimmedName.isEmpty) {
      return;
    }

    final settings = settingsController.settings;
    await settingsController.update(
      settings.copyWith(
        kidProfiles: [
          for (final currentProfile in settings.kidProfiles)
            if (currentProfile.id == profile.id)
              currentProfile.copyWith(
                name: trimmedName,
                avatarEmoji: editedProfile?.avatarEmoji,
              )
            else
              currentProfile,
        ],
      ),
    );
  }

  Future<void> _removeKidProfile(String profileId) async {
    final settings = settingsController.settings;
    if (settings.kidProfiles.length <= 1) {
      return;
    }

    AppAudioService.instance.play(AppSound.click);
    final remainingProfiles = settings.kidProfiles
        .where((profile) => profile.id != profileId)
        .toList();
    if (remainingProfiles.isEmpty) {
      return;
    }

    await settingsController.update(
      settings.copyWith(
        kidProfiles: remainingProfiles,
        activeKidProfileId: settings.activeKidProfileId == profileId
            ? remainingProfiles.first.id
            : settings.activeKidProfileId,
      ),
    );
  }

  void _openGame(BuildContext context, BrushingCharacter character) {
    final settings = settingsController.settings;
    AppAudioService.instance.play(AppSound.click);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CameraGameScreen(
          character: character,
          kidProfile: settings.activeKidProfile,
          availableCameras: availableCameras,
          settings: settings,
        ),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    AppAudioService.instance.play(AppSound.click);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(
          availableCameras: availableCameras,
          settingsController: settingsController,
        ),
      ),
    );
  }
}

class _KidProfileDraft {
  const _KidProfileDraft({
    required this.name,
    required this.avatarEmoji,
    this.shouldRemove = false,
  });

  final String name;
  final String avatarEmoji;
  final bool shouldRemove;
}

class _AddKidProfileDialog extends StatefulWidget {
  const _AddKidProfileDialog({
    this.title,
    this.initialName = '',
    this.initialAvatarEmoji = KidProfile.defaultAvatarEmoji,
    this.allowRemove = false,
  });

  final String? title;
  final String initialName;
  final String initialAvatarEmoji;
  final bool allowRemove;

  @override
  State<_AddKidProfileDialog> createState() => _AddKidProfileDialogState();
}

class _AddKidProfileDialogState extends State<_AddKidProfileDialog> {
  late final TextEditingController _controller;
  String _avatarEmoji = KidProfile.defaultAvatarEmoji;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _avatarEmoji = widget.initialAvatarEmoji;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(widget.title ?? l10n.addKidProfileTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(hintText: l10n.kidProfileNameHint),
            onSubmitted: _save,
          ),
          const SizedBox(height: 18),
          Text(
            l10n.kidProfileAvatarLabel,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final avatar in KidProfile.avatarOptions)
                ChoiceChip(
                  label: Text(avatar, style: const TextStyle(fontSize: 22)),
                  selected: avatar == _avatarEmoji,
                  onSelected: (_) => setState(() => _avatarEmoji = avatar),
                ),
            ],
          ),
        ],
      ),
      actions: [
        if (widget.allowRemove)
          TextButton.icon(
            onPressed: _remove,
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(l10n.remove),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => _save(_controller.text),
          child: Text(l10n.save),
        ),
      ],
    );
  }

  void _save(String value) {
    Navigator.of(
      context,
    ).pop(_KidProfileDraft(name: value, avatarEmoji: _avatarEmoji));
  }

  void _remove() {
    Navigator.of(context).pop(
      _KidProfileDraft(
        name: _controller.text,
        avatarEmoji: _avatarEmoji,
        shouldRemove: true,
      ),
    );
  }
}

class _ProfileSelector extends StatelessWidget {
  const _ProfileSelector({
    required this.settings,
    required this.onSelect,
    required this.onAdd,
    required this.onEdit,
  });

  final AppSettings settings;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdd;
  final ValueChanged<KidProfile> onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.kidProfilesTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            IconButton.filledTonal(
              tooltip: l10n.addKidProfileTooltip,
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_alt_1_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final profile in settings.kidProfiles)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPress: () => onEdit(profile),
                child: InputChip(
                  avatar: Text(
                    profile.avatarEmoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                  label: Text(profile.name),
                  selected: profile.id == settings.activeKidProfileId,
                  onPressed: () => onSelect(profile.id),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
