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
}
