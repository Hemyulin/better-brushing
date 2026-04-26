import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/character.dart';
import '../widgets/character_card.dart';
import 'camera_game_screen.dart';

class CharacterSelectionScreen extends StatelessWidget {
  const CharacterSelectionScreen({super.key, required this.availableCameras});

  final List<CameraDescription> availableCameras;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF6E9), Color(0xFFFFE0B5), Color(0xFFB8F2E6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      l10n.chooseYourCharacter,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.characterSelectionSubtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF5D5A88),
                      ),
                    ),
                    const SizedBox(height: 28),
                    CharacterCard(
                      name: l10n.characterName(BrushingCharacter.fox),
                      emoji: BrushingCharacter.fox.emoji,
                      subtitle: l10n.foxDescription,
                      color: const Color(0xFFF28B50),
                      onTap: () => _openGame(context, BrushingCharacter.fox),
                    ),
                    const SizedBox(height: 20),
                    CharacterCard(
                      name: l10n.characterName(BrushingCharacter.gator),
                      emoji: BrushingCharacter.gator.emoji,
                      subtitle: l10n.gatorDescription,
                      color: const Color(0xFF43B49D),
                      onTap: () => _openGame(context, BrushingCharacter.gator),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openGame(BuildContext context, BrushingCharacter character) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CameraGameScreen(
          character: character,
          availableCameras: availableCameras,
        ),
      ),
    );
  }
}
