import 'package:flutter/widgets.dart';

import 'app_localizations.dart';
import '../models/brushing_zone.dart';
import '../models/character.dart';

extension AppLocalizationsX on AppLocalizations {
  String characterName(BrushingCharacter character) => switch (character) {
    BrushingCharacter.fox => foxName,
    BrushingCharacter.gator => gatorName,
  };

  String zoneName(BrushingZone zone) => switch (zone) {
    BrushingZone.topLeft => zoneTopLeft,
    BrushingZone.topRight => zoneTopRight,
    BrushingZone.bottomLeft => zoneBottomLeft,
    BrushingZone.bottomRight => zoneBottomRight,
  };
}

extension BuildContextL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
