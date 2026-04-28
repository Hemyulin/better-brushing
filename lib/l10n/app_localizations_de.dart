// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get start => 'Start';

  @override
  String get chooseYourCharacter => 'Wähle deine Figur';

  @override
  String get characterSelectionSubtitle =>
      'Such dir einen Putzfreund aus und starte ruhig in zwei Zahnputz-Minuten.';

  @override
  String get foxName => 'Fuchs';

  @override
  String get gatorName => 'Krokodil';

  @override
  String get foxDescription =>
      'Fröhlich, freundlich und bereit, Essensreste wegzuwischen.';

  @override
  String get gatorDescription => 'Ruhig, stark und bei jeder Seite mit dabei.';

  @override
  String get letsCleanThisSide => 'Lass uns diese Seite putzen!';

  @override
  String get greatJob => 'Super gemacht!';

  @override
  String get keepGoing => 'Weiter so!';

  @override
  String get almostDone => 'Fast geschafft!';

  @override
  String get nowItsYourParentsTurn => 'Jetzt sind deine Eltern dran!';

  @override
  String get plusThirtySeconds => '+30 Sekunden';

  @override
  String get finished => 'Geschafft!';

  @override
  String get parentsTurnNow => 'Jetzt schauen die Eltern';

  @override
  String get keepBrushingTogether =>
      'Putzt noch ein kleines bisschen zusammen weiter.';

  @override
  String get zoneProgressHint =>
      'Putze diese Seite weiter, dann wird sie sauber und blank.';

  @override
  String get sessionComplete => 'Für jetzt sind die Zähne sauber.';

  @override
  String get timeRemaining => 'Verbleibende Zeit';

  @override
  String get currentZone => 'Aktuelle Zone';

  @override
  String get parentsTurn => 'Eltern';

  @override
  String get backToCharacters => 'Zurück zur Auswahl';

  @override
  String get cameraPreviewFallback =>
      'Die Kameravorschau ist gerade nicht verfügbar, aber das Putzspiel kann trotzdem laufen.';

  @override
  String get banubaTokenHint =>
      'Füge ein Banuba-Test-Token per --dart-define=BANUBA_CLIENT_TOKEN=... hinzu, um AR-Filter zu aktivieren.';

  @override
  String get banubaArUnavailable =>
      'Banuba AR konnte noch nicht gestartet werden.';

  @override
  String get banubaPermissionRequired =>
      'Für die AR-Vorschau wird Kamerazugriff benötigt.';

  @override
  String get zoneTopLeft => 'Oben links';

  @override
  String get zoneTopRight => 'Oben rechts';

  @override
  String get zoneBottomLeft => 'Unten links';

  @override
  String get zoneBottomRight => 'Unten rechts';

  @override
  String cleanZoneInstruction(String zone) {
    return 'Putze die Seite $zone.';
  }

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get timerSettingsTitle => 'Timer';

  @override
  String brushingDurationMinutes(String minutes) {
    return '$minutes Minuten';
  }

  @override
  String get languageSettingsTitle => 'Sprache';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'Englisch';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get pauseSettingsTitle => 'Pause';

  @override
  String get pauseControlLabel => 'Pausieren mit';

  @override
  String get pauseByScreen => 'Display';

  @override
  String get pauseByVolume => 'Lautstärke';

  @override
  String get pauseByBoth => 'Beides';

  @override
  String get pauseLockTitle => 'Pausieren sperren';

  @override
  String get pauseLockDescription =>
      'Pausieren per Display braucht langes Drücken, Lautstärketasten sind aus.';

  @override
  String get paused => 'Pausiert';

  @override
  String get tapToResume => 'Tippen zum Fortsetzen';

  @override
  String get longPressToResume => 'Lange drücken zum Fortsetzen';

  @override
  String get zoneSequenceTitle => 'Reihenfolge der Seiten';

  @override
  String get zoneSequenceCurrentOrder => 'Aktuelle Reihenfolge';

  @override
  String get zoneSequencePatternLabel => 'Muster';

  @override
  String get zoneSequenceStartLabel => 'Start bei';

  @override
  String get zoneSequenceClockwise => 'Im Uhrzeigersinn';

  @override
  String get zoneSequenceCounterClockwise => 'Gegen den Uhrzeigersinn';

  @override
  String get zoneSequenceZFormation => 'Z-Form';

  @override
  String get zoneSequenceClear => 'Leeren';

  @override
  String get zoneSequenceReset => 'Zurücksetzen';

  @override
  String get characterPlacementTitle => 'Figurenplatzierung';

  @override
  String get foxEarHeightLabel => 'Höhe der Fuchsohren';

  @override
  String get foxEarSpacingLabel => 'Abstand der Fuchsohren';

  @override
  String get gatorHorizontalLabel => 'Krokodil horizontal';

  @override
  String get gatorVerticalLabel => 'Krokodil vertikal';

  @override
  String get placementHigher => 'Höher';

  @override
  String get placementLower => 'Tiefer';

  @override
  String get placementCloser => 'Näher';

  @override
  String get placementFarther => 'Weiter';

  @override
  String get placementLeft => 'Links';

  @override
  String get placementRight => 'Rechts';
}
