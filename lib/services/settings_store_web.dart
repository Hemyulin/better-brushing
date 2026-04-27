import '../models/app_settings.dart';

AppSettings _settings = const AppSettings();

Future<AppSettings> loadSettings() async => _settings;

Future<void> saveSettings(AppSettings settings) async {
  _settings = settings;
}
