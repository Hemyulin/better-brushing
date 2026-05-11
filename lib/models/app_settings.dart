import 'package:flutter/widgets.dart';

import 'brushing_zone.dart';
import 'kid_profile.dart';

enum AppLanguage { system, english, german }

enum PauseControl { screen, volumeButtons, screenAndVolumeButtons }

enum MouthTargetMode { static, dynamic }

enum PlaqueVisualStyle { dots, bacteria, food }

enum FoodVisualCategory { everything, vegetarian, vegan }

class AppSettings {
  const AppSettings({
    this.brushingDurationSeconds = 120,
    this.startCountdownSeconds = 3,
    this.language = AppLanguage.system,
    this.pauseControl = PauseControl.screen,
    this.pauseLockEnabled = false,
    this.mouthTargetMode = MouthTargetMode.dynamic,
    this.plaqueVisualStyle = PlaqueVisualStyle.dots,
    this.plaqueVisualScale = defaultPlaqueVisualScale,
    this.foodVisualCategory = FoodVisualCategory.everything,
    this.kidProfiles = const [KidProfile.defaultProfile],
    this.activeKidProfileId = KidProfile.defaultProfileId,
    this.zoneOrder = defaultZoneOrder,
    this.foxEarHeightOffset = 0,
    this.foxEarSpacingOffset = 0,
    this.gatorHorizontalOffset = 0,
    this.gatorVerticalOffset = 0,
    this.trackingHorizontalOffset = 0,
    this.trackingVerticalOffset = 0,
  });

  static const defaultZoneOrder = [
    BrushingZone.topLeft,
    BrushingZone.topRight,
    BrushingZone.bottomLeft,
    BrushingZone.bottomRight,
  ];

  final int brushingDurationSeconds;
  final int startCountdownSeconds;
  final AppLanguage language;
  final PauseControl pauseControl;
  final bool pauseLockEnabled;
  final MouthTargetMode mouthTargetMode;
  final PlaqueVisualStyle plaqueVisualStyle;
  final double plaqueVisualScale;
  final FoodVisualCategory foodVisualCategory;
  final List<KidProfile> kidProfiles;
  final String activeKidProfileId;
  final List<BrushingZone> zoneOrder;
  final double foxEarHeightOffset;
  final double foxEarSpacingOffset;
  final double gatorHorizontalOffset;
  final double gatorVerticalOffset;
  final double trackingHorizontalOffset;
  final double trackingVerticalOffset;

  static const minDurationSeconds = 60;
  static const maxDurationSeconds = 300;
  static const durationStepSeconds = 30;
  static const countdownOptionsSeconds = [0, 3, 5, 10];
  static const minPlaqueVisualScale = 1.0;
  static const maxPlaqueVisualScale = 3.0;
  static const defaultPlaqueVisualScale = 2.5;
  static const minCharacterOffset = -1.0;
  static const maxCharacterOffset = 1.0;

  Locale? get locale => switch (language) {
    AppLanguage.system => null,
    AppLanguage.english => const Locale('en'),
    AppLanguage.german => const Locale('de'),
  };

  bool get allowsScreenPause =>
      pauseControl == PauseControl.screen ||
      pauseControl == PauseControl.screenAndVolumeButtons;

  bool get allowsVolumePause =>
      pauseControl == PauseControl.volumeButtons ||
      pauseControl == PauseControl.screenAndVolumeButtons;

  KidProfile get activeKidProfile {
    for (final profile in kidProfiles) {
      if (profile.id == activeKidProfileId) {
        return profile;
      }
    }
    return kidProfiles.first;
  }

  AppSettings copyWith({
    int? brushingDurationSeconds,
    int? startCountdownSeconds,
    AppLanguage? language,
    PauseControl? pauseControl,
    bool? pauseLockEnabled,
    MouthTargetMode? mouthTargetMode,
    PlaqueVisualStyle? plaqueVisualStyle,
    double? plaqueVisualScale,
    FoodVisualCategory? foodVisualCategory,
    List<KidProfile>? kidProfiles,
    String? activeKidProfileId,
    List<BrushingZone>? zoneOrder,
    double? foxEarHeightOffset,
    double? foxEarSpacingOffset,
    double? gatorHorizontalOffset,
    double? gatorVerticalOffset,
    double? trackingHorizontalOffset,
    double? trackingVerticalOffset,
  }) {
    return AppSettings(
      brushingDurationSeconds:
          brushingDurationSeconds ?? this.brushingDurationSeconds,
      startCountdownSeconds:
          startCountdownSeconds ?? this.startCountdownSeconds,
      language: language ?? this.language,
      pauseControl: pauseControl ?? this.pauseControl,
      pauseLockEnabled: pauseLockEnabled ?? this.pauseLockEnabled,
      mouthTargetMode: mouthTargetMode ?? this.mouthTargetMode,
      plaqueVisualStyle: plaqueVisualStyle ?? this.plaqueVisualStyle,
      plaqueVisualScale: plaqueVisualScale ?? this.plaqueVisualScale,
      foodVisualCategory: foodVisualCategory ?? this.foodVisualCategory,
      kidProfiles: kidProfiles ?? this.kidProfiles,
      activeKidProfileId: activeKidProfileId ?? this.activeKidProfileId,
      zoneOrder: zoneOrder ?? this.zoneOrder,
      foxEarHeightOffset: foxEarHeightOffset ?? this.foxEarHeightOffset,
      foxEarSpacingOffset: foxEarSpacingOffset ?? this.foxEarSpacingOffset,
      gatorHorizontalOffset:
          gatorHorizontalOffset ?? this.gatorHorizontalOffset,
      gatorVerticalOffset: gatorVerticalOffset ?? this.gatorVerticalOffset,
      trackingHorizontalOffset:
          trackingHorizontalOffset ?? this.trackingHorizontalOffset,
      trackingVerticalOffset:
          trackingVerticalOffset ?? this.trackingVerticalOffset,
    );
  }

  Map<String, Object> toJson() {
    return <String, Object>{
      'brushingDurationSeconds': brushingDurationSeconds,
      'startCountdownSeconds': startCountdownSeconds,
      'language': language.name,
      'pauseControl': pauseControl.name,
      'pauseLockEnabled': pauseLockEnabled,
      'mouthTargetMode': mouthTargetMode.name,
      'plaqueVisualStyle': plaqueVisualStyle.name,
      'plaqueVisualScale': plaqueVisualScale,
      'foodVisualCategory': foodVisualCategory.name,
      'kidProfiles': kidProfiles.map((profile) => profile.toJson()).toList(),
      'activeKidProfileId': activeKidProfileId,
      'zoneOrder': zoneOrder.map((zone) => zone.name).toList(),
      'foxEarHeightOffset': foxEarHeightOffset,
      'foxEarSpacingOffset': foxEarSpacingOffset,
      'gatorHorizontalOffset': gatorHorizontalOffset,
      'gatorVerticalOffset': gatorVerticalOffset,
      'trackingHorizontalOffset': trackingHorizontalOffset,
      'trackingVerticalOffset': trackingVerticalOffset,
    };
  }

  factory AppSettings.fromJson(Map<String, Object?> json) {
    return AppSettings(
      brushingDurationSeconds: _readDuration(json['brushingDurationSeconds']),
      startCountdownSeconds: _readCountdown(json['startCountdownSeconds']),
      language: _readEnum(
        AppLanguage.values,
        json['language'],
        AppLanguage.system,
      ),
      pauseControl: _readEnum(
        PauseControl.values,
        json['pauseControl'],
        PauseControl.screen,
      ),
      pauseLockEnabled: json['pauseLockEnabled'] == true,
      mouthTargetMode: _readEnum(
        MouthTargetMode.values,
        json['mouthTargetMode'],
        MouthTargetMode.dynamic,
      ),
      plaqueVisualStyle: _readEnum(
        PlaqueVisualStyle.values,
        json['plaqueVisualStyle'],
        PlaqueVisualStyle.dots,
      ),
      plaqueVisualScale: _readPlaqueVisualScale(json['plaqueVisualScale']),
      foodVisualCategory: _readEnum(
        FoodVisualCategory.values,
        json['foodVisualCategory'],
        FoodVisualCategory.everything,
      ),
      kidProfiles: _readKidProfiles(json['kidProfiles']),
      activeKidProfileId: _readActiveKidProfileId(
        json['activeKidProfileId'],
        json['kidProfiles'],
      ),
      zoneOrder: _readZoneOrder(json),
      foxEarHeightOffset: _readCharacterOffset(json['foxEarHeightOffset']),
      foxEarSpacingOffset: _readCharacterOffset(json['foxEarSpacingOffset']),
      gatorHorizontalOffset: _readCharacterOffset(
        json['gatorHorizontalOffset'],
      ),
      gatorVerticalOffset: _readCharacterOffset(json['gatorVerticalOffset']),
      trackingHorizontalOffset: _readCharacterOffset(
        json['trackingHorizontalOffset'],
      ),
      trackingVerticalOffset: _readCharacterOffset(
        json['trackingVerticalOffset'],
      ),
    );
  }

  static int _readDuration(Object? value) {
    final duration = value is num ? value.round() : 120;
    return duration.clamp(minDurationSeconds, maxDurationSeconds);
  }

  static int _readCountdown(Object? value) {
    final seconds = value is num ? value.round() : 3;
    return countdownOptionsSeconds.contains(seconds) ? seconds : 3;
  }

  static double _readPlaqueVisualScale(Object? value) {
    final scale = value is num ? value.toDouble() : defaultPlaqueVisualScale;
    return scale.clamp(minPlaqueVisualScale, maxPlaqueVisualScale);
  }

  static double _readCharacterOffset(Object? value) {
    final offset = value is num ? value.toDouble() : 0.0;
    return offset.clamp(minCharacterOffset, maxCharacterOffset);
  }

  static T _readEnum<T extends Enum>(
    List<T> values,
    Object? value,
    T fallback,
  ) {
    if (value is! String) {
      return fallback;
    }
    for (final enumValue in values) {
      if (enumValue.name == value) {
        return enumValue;
      }
    }
    return fallback;
  }

  static List<KidProfile> _readKidProfiles(Object? value) {
    if (value is List) {
      final profiles = <KidProfile>[];
      for (final item in value) {
        final profile = KidProfile.fromJson(item);
        if (profile != null && !profiles.any((p) => p.id == profile.id)) {
          profiles.add(profile);
        }
      }
      if (profiles.isNotEmpty) {
        return profiles;
      }
    }
    return const [KidProfile.defaultProfile];
  }

  static String _readActiveKidProfileId(Object? value, Object? profilesValue) {
    final profiles = _readKidProfiles(profilesValue);
    if (value is String && profiles.any((profile) => profile.id == value)) {
      return value;
    }
    return profiles.first.id;
  }

  static List<BrushingZone> _readZoneOrder(Map<String, Object?> json) {
    final savedOrder = json['zoneOrder'];
    if (savedOrder is List) {
      final zones = <BrushingZone>[];
      for (final value in savedOrder) {
        final zone = _readEnum(
          BrushingZone.values,
          value,
          BrushingZone.topLeft,
        );
        if (!zones.contains(zone)) {
          zones.add(zone);
        }
      }
      return _completeZoneOrder(zones);
    }

    return _legacyZoneOrder(json);
  }

  static List<BrushingZone> _legacyZoneOrder(Map<String, Object?> json) {
    final pattern = _readEnum(
      _LegacyZoneSequencePattern.values,
      json['zoneSequencePattern'],
      _LegacyZoneSequencePattern.zFormation,
    );
    final start = _readEnum(
      BrushingZone.values,
      json['zoneSequenceStart'],
      BrushingZone.topLeft,
    );
    final baseOrder = switch (pattern) {
      _LegacyZoneSequencePattern.clockwise => const [
        BrushingZone.topLeft,
        BrushingZone.topRight,
        BrushingZone.bottomRight,
        BrushingZone.bottomLeft,
      ],
      _LegacyZoneSequencePattern.counterClockwise => const [
        BrushingZone.topLeft,
        BrushingZone.bottomLeft,
        BrushingZone.bottomRight,
        BrushingZone.topRight,
      ],
      _LegacyZoneSequencePattern.zFormation => defaultZoneOrder,
    };
    final startIndex = baseOrder.indexOf(start);
    return <BrushingZone>[
      ...baseOrder.skip(startIndex),
      ...baseOrder.take(startIndex),
    ];
  }

  static List<BrushingZone> _completeZoneOrder(List<BrushingZone> zones) {
    return <BrushingZone>[
      ...zones,
      for (final zone in defaultZoneOrder)
        if (!zones.contains(zone)) zone,
    ];
  }
}

enum _LegacyZoneSequencePattern { clockwise, counterClockwise, zFormation }
