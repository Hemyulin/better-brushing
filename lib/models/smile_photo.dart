import 'character.dart';

class SmilePhoto {
  const SmilePhoto({
    required this.path,
    required this.capturedAt,
    required this.character,
    required this.kidProfileId,
  });

  final String path;
  final DateTime capturedAt;
  final BrushingCharacter character;
  final String kidProfileId;

  Map<String, Object?> toJson() => {
    'path': path,
    'capturedAt': capturedAt.toIso8601String(),
    'character': character.name,
    'kidProfileId': kidProfileId,
  };

  static SmilePhoto? fromJson(Object? json) {
    if (json is! Map) {
      return null;
    }

    final path = json['path'];
    final capturedAt = DateTime.tryParse('${json['capturedAt']}');
    final character = _readCharacter(json['character']);
    final kidProfileId = json['kidProfileId'] is String
        ? json['kidProfileId'] as String
        : 'default';
    if (path is! String || path.isEmpty || capturedAt == null) {
      return null;
    }

    return SmilePhoto(
      path: path,
      capturedAt: capturedAt,
      character: character,
      kidProfileId: kidProfileId,
    );
  }

  static BrushingCharacter _readCharacter(Object? value) {
    for (final character in BrushingCharacter.values) {
      if (character.name == value) {
        return character;
      }
    }
    return BrushingCharacter.fox;
  }
}
