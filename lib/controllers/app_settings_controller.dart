import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../services/settings_store.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController({SettingsStore store = const SettingsStore()})
    : _store = store;

  final SettingsStore _store;

  AppSettings _settings = const AppSettings();
  bool _isLoaded = false;

  AppSettings get settings => _settings;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    _settings = await _store.load();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> update(AppSettings settings) async {
    _settings = settings;
    notifyListeners();
    await _store.save(settings);
  }
}
