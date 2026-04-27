import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'controllers/app_settings_controller.dart';
import 'l10n/app_localizations.dart';
import 'screens/character_selection_screen.dart';

class BrushingApp extends StatefulWidget {
  const BrushingApp({
    super.key,
    required this.availableCameras,
    this.settingsController,
  });

  final List<CameraDescription> availableCameras;
  final AppSettingsController? settingsController;

  @override
  State<BrushingApp> createState() => _BrushingAppState();
}

class _BrushingAppState extends State<BrushingApp> {
  late final AppSettingsController _settingsController;
  late final bool _ownsSettingsController;

  @override
  void initState() {
    super.initState();
    _ownsSettingsController = widget.settingsController == null;
    _settingsController = widget.settingsController ?? AppSettingsController();
    if (_ownsSettingsController) {
      _settingsController.load();
    }
  }

  @override
  void dispose() {
    if (_ownsSettingsController) {
      _settingsController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF8A5B),
        primary: const Color(0xFFFF8A5B),
        secondary: const Color(0xFF49B7A5),
        surface: const Color(0xFFFFF6E9),
      ),
      scaffoldBackgroundColor: const Color(0xFFFFF6E9),
      useMaterial3: true,
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: const Color(0xFF2C2A4A),
        displayColor: const Color(0xFF2C2A4A),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );

    return AnimatedBuilder(
      animation: _settingsController,
      builder: (context, _) => MaterialApp(
        title: 'Brush Buddies',
        debugShowCheckedModeBanner: false,
        theme: theme,
        locale: _settingsController.settings.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: CharacterSelectionScreen(
          availableCameras: widget.availableCameras,
          settingsController: _settingsController,
        ),
      ),
    );
  }
}
