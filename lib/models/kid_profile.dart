class KidProfile {
  const KidProfile({
    required this.id,
    required this.name,
    this.avatarEmoji = defaultAvatarEmoji,
  });

  static const defaultProfileId = 'default';
  static const defaultAvatarEmoji = '👶';
  static const avatarOptions = ['👶', '😊', '😄', '🤩', '😎'];
  static const defaultProfile = KidProfile(id: defaultProfileId, name: 'Kid');

  final String id;
  final String name;
  final String avatarEmoji;

  KidProfile copyWith({String? name, String? avatarEmoji}) {
    return KidProfile(
      id: id,
      name: name ?? this.name,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
    );
  }

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'avatarEmoji': avatarEmoji,
  };

  static KidProfile? fromJson(Object? json) {
    if (json is! Map) {
      return null;
    }

    final id = json['id'];
    final name = json['name'];
    final avatarEmoji = json['avatarEmoji'];
    if (id is! String || id.isEmpty || name is! String || name.isEmpty) {
      return null;
    }

    return KidProfile(
      id: id,
      name: name,
      avatarEmoji: avatarEmoji is String && avatarEmoji.isNotEmpty
          ? avatarEmoji
          : defaultAvatarEmoji,
    );
  }
}
