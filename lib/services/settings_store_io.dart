import 'dart:convert';
import 'dart:io';

import '../models/app_settings.dart';

Future<AppSettings> loadSettings() async {
  try {
    final file = await _settingsFile();
    if (!await file.exists()) {
      return const AppSettings();
    }
    final content = await file.readAsString();
    final decoded = jsonDecode(content);
    if (decoded is Map<String, Object?>) {
      return AppSettings.fromJson(decoded);
    }
  } catch (_) {
    return const AppSettings();
  }
  return const AppSettings();
}

Future<void> saveSettings(AppSettings settings) async {
  try {
    final file = await _settingsFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(settings.toJson()));
  } catch (_) {
    // Settings are nice-to-have; the app should keep running if storage fails.
  }
}

Future<File> _settingsFile() async {
  final home =
      Platform.environment['HOME'] ??
      Platform.environment['USERPROFILE'] ??
      Directory.systemTemp.path;
  return File('$home/.better_brushing/settings.json');
}
