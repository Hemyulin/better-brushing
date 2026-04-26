import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'screens/character_selection_screen.dart';

class BrushingApp extends StatelessWidget {
  const BrushingApp({super.key, required this.availableCameras});

  final List<CameraDescription> availableCameras;

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

    return MaterialApp(
      title: 'Brush Buddies',
      debugShowCheckedModeBanner: false,
      theme: theme,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: CharacterSelectionScreen(availableCameras: availableCameras),
    );
  }
}
