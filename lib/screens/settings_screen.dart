import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../controllers/app_settings_controller.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import 'character_placement_settings_screen.dart';
import 'zone_sequence_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.availableCameras,
    required this.settingsController,
  });

  final List<CameraDescription> availableCameras;
  final AppSettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsController,
      builder: (context, _) {
        final settings = settingsController.settings;
        final l10n = context.l10n;

        return Scaffold(
          appBar: AppBar(title: Text(l10n.settingsTitle)),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _SettingsSection(
                title: l10n.timerSettingsTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.brushingDurationMinutes(
                        _formatMinutes(settings.brushingDurationSeconds),
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Slider(
                      value: settings.brushingDurationSeconds.toDouble(),
                      min: AppSettings.minDurationSeconds.toDouble(),
                      max: AppSettings.maxDurationSeconds.toDouble(),
                      divisions:
                          (AppSettings.maxDurationSeconds -
                              AppSettings.minDurationSeconds) ~/
                          AppSettings.durationStepSeconds,
                      label: _formatMinutes(settings.brushingDurationSeconds),
                      onChanged: (value) => _update(
                        settings.copyWith(
                          brushingDurationSeconds:
                              (value / AppSettings.durationStepSeconds)
                                  .round() *
                              AppSettings.durationStepSeconds,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.startCountdownLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<int>(
                        segments: [
                          for (final seconds
                              in AppSettings.countdownOptionsSeconds)
                            ButtonSegment(
                              value: seconds,
                              label: Text(
                                seconds == 0
                                    ? l10n.startCountdownOff
                                    : l10n.startCountdownSeconds(seconds),
                              ),
                            ),
                        ],
                        selected: {settings.startCountdownSeconds},
                        onSelectionChanged: (selection) => _update(
                          settings.copyWith(
                            startCountdownSeconds: selection.first,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: l10n.languageSettingsTitle,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<AppLanguage>(
                    segments: [
                      ButtonSegment(
                        value: AppLanguage.system,
                        label: Text(l10n.languageSystem),
                      ),
                      ButtonSegment(
                        value: AppLanguage.english,
                        label: Text(l10n.languageEnglish),
                      ),
                      ButtonSegment(
                        value: AppLanguage.german,
                        label: Text(l10n.languageGerman),
                      ),
                    ],
                    selected: {settings.language},
                    onSelectionChanged: (selection) =>
                        _update(settings.copyWith(language: selection.first)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: l10n.zoneSequenceTitle,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.zoneSequenceCurrentOrder),
                  subtitle: Text(
                    settings.zoneOrder
                        .map((zone) => l10n.zoneName(zone))
                        .join('  •  '),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openZoneSequenceSettings(context),
                ),
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: l10n.characterPlacementTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.characterPlacementOpen),
                      subtitle: Text(l10n.characterPlacementDescription),
                      trailing: const Icon(Icons.camera_alt_rounded),
                      onTap: () => _openCharacterPlacementSettings(context),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.mouthTargetModeLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<MouthTargetMode>(
                        segments: [
                          ButtonSegment(
                            value: MouthTargetMode.static,
                            label: Text(l10n.mouthTargetStatic),
                          ),
                          ButtonSegment(
                            value: MouthTargetMode.dynamic,
                            label: Text(l10n.mouthTargetDynamic),
                          ),
                        ],
                        selected: {settings.mouthTargetMode},
                        onSelectionChanged: (selection) => _update(
                          settings.copyWith(mouthTargetMode: selection.first),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.plaqueVisualStyleLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<PlaqueVisualStyle>(
                        segments: [
                          ButtonSegment(
                            value: PlaqueVisualStyle.dots,
                            label: Text(l10n.plaqueVisualDots),
                          ),
                          ButtonSegment(
                            value: PlaqueVisualStyle.bacteria,
                            label: Text(l10n.plaqueVisualBacteria),
                          ),
                          ButtonSegment(
                            value: PlaqueVisualStyle.food,
                            label: Text(l10n.plaqueVisualFood),
                          ),
                        ],
                        selected: {settings.plaqueVisualStyle},
                        onSelectionChanged: (selection) => _update(
                          settings.copyWith(plaqueVisualStyle: selection.first),
                        ),
                      ),
                    ),
                    if (settings.plaqueVisualStyle == PlaqueVisualStyle.food)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SegmentedButton<FoodVisualCategory>(
                            segments: [
                              ButtonSegment(
                                value: FoodVisualCategory.everything,
                                label: Text(l10n.foodCategoryEverything),
                              ),
                              ButtonSegment(
                                value: FoodVisualCategory.vegetarian,
                                label: Text(l10n.foodCategoryVegetarian),
                              ),
                              ButtonSegment(
                                value: FoodVisualCategory.vegan,
                                label: Text(l10n.foodCategoryVegan),
                              ),
                            ],
                            selected: {settings.foodVisualCategory},
                            onSelectionChanged: (selection) => _update(
                              settings.copyWith(
                                foodVisualCategory: selection.first,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: l10n.pauseSettingsTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.pauseControlLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<PauseControl>(
                        segments: [
                          ButtonSegment(
                            value: PauseControl.screen,
                            label: Text(l10n.pauseByScreen),
                          ),
                          ButtonSegment(
                            value: PauseControl.volumeButtons,
                            label: Text(l10n.pauseByVolume),
                          ),
                          ButtonSegment(
                            value: PauseControl.screenAndVolumeButtons,
                            label: Text(l10n.pauseByBoth),
                          ),
                        ],
                        selected: {settings.pauseControl},
                        onSelectionChanged: (selection) => _update(
                          settings.copyWith(pauseControl: selection.first),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.pauseLockTitle),
                      subtitle: Text(l10n.pauseLockDescription),
                      value: settings.pauseLockEnabled,
                      onChanged: (value) =>
                          _update(settings.copyWith(pauseLockEnabled: value)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _update(AppSettings settings) =>
      settingsController.update(settings);

  void _openZoneSequenceSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ZoneSequenceSettingsScreen(settingsController: settingsController),
      ),
    );
  }

  void _openCharacterPlacementSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CharacterPlacementSettingsScreen(
          availableCameras: availableCameras,
          settingsController: settingsController,
        ),
      ),
    );
  }

  String _formatMinutes(int seconds) {
    final wholeMinutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (remainingSeconds == 0) {
      return '$wholeMinutes';
    }
    return '$wholeMinutes.5';
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
