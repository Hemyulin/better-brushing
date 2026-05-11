import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';

import '../models/character.dart';
import '../models/smile_photo.dart';

class SmilePhotoStore {
  const SmilePhotoStore._();

  static const SmilePhotoStore instance = SmilePhotoStore._();

  Future<SmilePhoto?> latestPhoto({required String kidProfileId}) async {
    final photos = await loadPhotos();
    for (final photo in photos.reversed) {
      if (photo.kidProfileId == kidProfileId &&
          await File(photo.path).exists()) {
        return photo;
      }
    }
    return null;
  }

  Future<List<SmilePhoto>> loadPhotos() async {
    try {
      final file = await _indexFile();
      if (!await file.exists()) {
        return const [];
      }

      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List<Object?>) {
        return const [];
      }

      final photos =
          decoded.map(SmilePhoto.fromJson).whereType<SmilePhoto>().toList()
            ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
      return photos;
    } catch (_) {
      return const [];
    }
  }

  Future<SmilePhoto?> saveCapturedPhoto(
    XFile photo, {
    required BrushingCharacter character,
    required String kidProfileId,
  }) async {
    try {
      final capturedAt = DateTime.now();
      final directory = await _photosDirectory();
      await directory.create(recursive: true);
      final savedFile = File(
        '${directory.path}/smile_${capturedAt.microsecondsSinceEpoch}.jpg',
      );
      await File(photo.path).copy(savedFile.path);

      final smilePhoto = SmilePhoto(
        path: savedFile.path,
        capturedAt: capturedAt,
        character: character,
        kidProfileId: kidProfileId,
      );
      final photos = await loadPhotos();
      photos.add(smilePhoto);
      await _savePhotos(photos);
      return smilePhoto;
    } catch (_) {
      return null;
    }
  }

  Future<void> _savePhotos(List<SmilePhoto> photos) async {
    final file = await _indexFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode(photos.map((p) => p.toJson()).toList()),
    );
  }

  Future<File> _indexFile() async {
    final directory = await _storageDirectory();
    return File('${directory.path}/smile_photos.json');
  }

  Future<Directory> _photosDirectory() async {
    final directory = await _storageDirectory();
    return Directory('${directory.path}/smile_photos');
  }

  Future<Directory> _storageDirectory() async {
    final home =
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.systemTemp.path;
    return Directory('$home/.better_brushing');
  }
}
