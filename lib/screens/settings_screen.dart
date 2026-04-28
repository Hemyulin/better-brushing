import 'package:flutter/material.dart';

import '../controllers/app_settings_controller.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import 'zone_sequence_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.settingsController});

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
                  children: [
                    _PlacementSlider(
                      label: l10n.foxEarHeightLabel,
                      leadingLabel: l10n.placementHigher,
                      trailingLabel: l10n.placementLower,
                      value: settings.foxEarHeightOffset,
                      onChanged: (value) =>
                          _update(settings.copyWith(foxEarHeightOffset: value)),
                    ),
                    _PlacementSlider(
                      label: l10n.foxEarSpacingLabel,
                      leadingLabel: l10n.placementCloser,
                      trailingLabel: l10n.placementFarther,
                      value: settings.foxEarSpacingOffset,
                      onChanged: (value) => _update(
                        settings.copyWith(foxEarSpacingOffset: value),
                      ),
                    ),
                    _PlacementSlider(
                      label: l10n.gatorHorizontalLabel,
                      leadingLabel: l10n.placementLeft,
                      trailingLabel: l10n.placementRight,
                      value: settings.gatorHorizontalOffset,
                      onChanged: (value) => _update(
                        settings.copyWith(gatorHorizontalOffset: value),
                      ),
                    ),
                    _PlacementSlider(
                      label: l10n.gatorVerticalLabel,
                      leadingLabel: l10n.placementHigher,
                      trailingLabel: l10n.placementLower,
                      value: settings.gatorVerticalOffset,
                      onChanged: (value) => _update(
                        settings.copyWith(gatorVerticalOffset: value),
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

  String _formatMinutes(int seconds) {
    final wholeMinutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (remainingSeconds == 0) {
      return '$wholeMinutes';
    }
    return '$wholeMinutes.5';
  }
}

class _PlacementSlider extends StatelessWidget {
  const _PlacementSlider({
    required this.label,
    required this.leadingLabel,
    required this.trailingLabel,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String leadingLabel;
  final String trailingLabel;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Slider(
            value: value,
            min: AppSettings.minCharacterOffset,
            max: AppSettings.maxCharacterOffset,
            divisions: 8,
            label: value.toStringAsFixed(2),
            onChanged: onChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(leadingLabel, style: Theme.of(context).textTheme.bodySmall),
              Text(trailingLabel, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
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
