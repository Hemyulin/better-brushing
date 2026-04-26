enum BrushingCharacter { fox, gator }

extension BrushingCharacterVisuals on BrushingCharacter {
  String get emoji => switch (this) {
    BrushingCharacter.fox => '🦊',
    BrushingCharacter.gator => '🐊',
  };

  String get accentEmoji => switch (this) {
    BrushingCharacter.fox => '✨',
    BrushingCharacter.gator => '🌊',
  };
}
