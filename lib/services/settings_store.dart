import '../models/app_settings.dart';
import 'settings_store_impl.dart';

class SettingsStore {
  const SettingsStore();

  Future<AppSettings> load() => loadSettings();

  Future<void> save(AppSettings settings) => saveSettings(settings);
}
