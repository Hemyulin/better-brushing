// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get start => 'Start';

  @override
  String get chooseYourCharacter => 'Choose your character';

  @override
  String get characterSelectionSubtitle =>
      'Pick a brushing buddy and begin your calm two-minute clean.';

  @override
  String get foxName => 'Fox';

  @override
  String get gatorName => 'Gator';

  @override
  String get foxDescription =>
      'Warm, cheerful, and ready to swish away snack crumbs.';

  @override
  String get gatorDescription =>
      'Cool, steady, and happy to help with every side.';

  @override
  String get kidProfilesTitle => 'Who is brushing?';

  @override
  String get addKidProfileTooltip => 'Add kid profile';

  @override
  String get addKidProfileTitle => 'Add kid profile';

  @override
  String get editKidProfileTooltip => 'Edit kid profile';

  @override
  String get editKidProfileTitle => 'Edit kid profile';

  @override
  String get kidProfileNameHint => 'Kid\'s name';

  @override
  String get kidProfileAvatarLabel => 'Choose a smiley';

  @override
  String get removeKidProfileTooltip => 'Remove kid profile';

  @override
  String get save => 'Save';

  @override
  String get remove => 'Remove';

  @override
  String get cancel => 'Cancel';

  @override
  String get letsCleanThisSide => 'Let\'s clean this side!';

  @override
  String get greatJob => 'Great job!';

  @override
  String get keepGoing => 'Keep going!';

  @override
  String get almostDone => 'Almost done!';

  @override
  String get nowItsYourParentsTurn => 'Now it\'s your parent\'s turn!';

  @override
  String get plusThirtySeconds => '+30 seconds';

  @override
  String get finished => 'Finished!';

  @override
  String get parentsTurnNow => 'Parent check time';

  @override
  String get keepBrushingTogether =>
      'Keep brushing together for a little longer.';

  @override
  String get zoneProgressHint =>
      'Keep brushing this side and it will sparkle clean.';

  @override
  String get sessionComplete => 'All clean for now.';

  @override
  String get timeRemaining => 'Time left';

  @override
  String get currentZone => 'Current zone';

  @override
  String get parentsTurn => 'Parent turn';

  @override
  String get backToCharacters => 'Back to characters';

  @override
  String smileChallengeTitle(String name) {
    return 'Can $name beat this smile today?';
  }

  @override
  String get smileChallengeSubtitle =>
      'Brush well, then take a fresh victory photo.';

  @override
  String get smileChallengeStart => 'Start brushing';

  @override
  String get smileCaptureTitle => 'Take your victory smile';

  @override
  String get smileCaptureSubtitle =>
      'This will become tomorrow\'s challenge photo.';

  @override
  String get smileCaptureButton => 'Take smile photo';

  @override
  String get smileCaptureSavedTitle => 'Smile saved!';

  @override
  String get smileCaptureSavedSubtitle =>
      'It is ready for the next brushing challenge.';

  @override
  String get cameraPreviewFallback =>
      'Camera preview is not available right now, but the brushing game can still run.';

  @override
  String get banubaTokenHint =>
      'Add a Banuba trial token via --dart-define=BANUBA_CLIENT_TOKEN=... to enable AR filters.';

  @override
  String get banubaArUnavailable => 'Banuba AR could not start yet.';

  @override
  String get banubaPermissionRequired =>
      'Camera access is required for AR preview.';

  @override
  String get zoneTopLeft => 'Top left';

  @override
  String get zoneTopRight => 'Top right';

  @override
  String get zoneBottomLeft => 'Bottom left';

  @override
  String get zoneBottomRight => 'Bottom right';

  @override
  String cleanZoneInstruction(String zone) {
    return 'Clean the $zone side.';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get timerSettingsTitle => 'Timer';

  @override
  String brushingDurationMinutes(String minutes) {
    return '$minutes minutes';
  }

  @override
  String get startCountdownLabel => 'Start countdown';

  @override
  String get startCountdownOff => 'Off';

  @override
  String startCountdownSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get countdownReady => 'Get ready';

  @override
  String get countdownStartsSoon => 'Brushing starts soon.';

  @override
  String get languageSettingsTitle => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGerman => 'German';

  @override
  String get pauseSettingsTitle => 'Pause';

  @override
  String get pauseControlLabel => 'Pause with';

  @override
  String get pauseByScreen => 'Screen';

  @override
  String get pauseByVolume => 'Volume';

  @override
  String get pauseByBoth => 'Both';

  @override
  String get pauseLockTitle => 'Lock pausing';

  @override
  String get pauseLockDescription =>
      'Screen pauses need a long press, and volume buttons are disabled.';

  @override
  String get paused => 'Paused';

  @override
  String get tapToResume => 'Tap to resume';

  @override
  String get longPressToResume => 'Long press to resume';

  @override
  String get zoneSequenceTitle => 'Side order';

  @override
  String get zoneSequenceCurrentOrder => 'Current order';

  @override
  String get zoneSequencePatternLabel => 'Pattern';

  @override
  String get zoneSequenceStartLabel => 'Start at';

  @override
  String get zoneSequenceClockwise => 'Clockwise';

  @override
  String get zoneSequenceCounterClockwise => 'Counter-clockwise';

  @override
  String get zoneSequenceZFormation => 'Z formation';

  @override
  String get zoneSequenceClear => 'Clear';

  @override
  String get zoneSequenceReset => 'Reset';

  @override
  String get characterPlacementTitle => 'Character placement';

  @override
  String get characterPlacementOpen => 'Open camera placement';

  @override
  String get characterPlacementDescription =>
      'Tune character and tracking positions against the live camera.';

  @override
  String get mouthTargetModeLabel => 'Mouth target';

  @override
  String get mouthTargetStatic => 'Static';

  @override
  String get mouthTargetDynamic => 'Dynamic';

  @override
  String get plaqueVisualStyleLabel => 'Bacteria look';

  @override
  String get plaqueVisualDots => 'Dots';

  @override
  String get plaqueVisualBacteria => 'Bacteria';

  @override
  String get plaqueVisualFood => 'Food';

  @override
  String get plaqueVisualSizeLabel => 'Plaque size';

  @override
  String get foodCategoryEverything => 'Everything';

  @override
  String get foodCategoryVegetarian => 'Vegetarian';

  @override
  String get foodCategoryVegan => 'Vegan';

  @override
  String get foxEarHeightLabel => 'Fox ear height';

  @override
  String get foxEarSpacingLabel => 'Fox ear distance';

  @override
  String get gatorHorizontalLabel => 'Gator horizontal position';

  @override
  String get gatorVerticalLabel => 'Gator vertical position';

  @override
  String get trackingHorizontalLabel => 'Tracking center horizontal';

  @override
  String get trackingVerticalLabel => 'Tracking center vertical';

  @override
  String get placementHigher => 'Higher';

  @override
  String get placementLower => 'Lower';

  @override
  String get placementCloser => 'Closer';

  @override
  String get placementFarther => 'Farther';

  @override
  String get placementLeft => 'Left';

  @override
  String get placementRight => 'Right';
}
