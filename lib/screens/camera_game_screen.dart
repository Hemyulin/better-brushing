import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../controllers/brushing_session_controller.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../models/brushing_zone.dart';
import '../models/character.dart';
import '../services/volume_button_service.dart';

class CameraGameScreen extends StatefulWidget {
  const CameraGameScreen({
    super.key,
    required this.character,
    required this.availableCameras,
    required this.settings,
  });

  final BrushingCharacter character;
  final List<CameraDescription> availableCameras;
  final AppSettings settings;

  @override
  State<CameraGameScreen> createState() => _CameraGameScreenState();
}

class _CameraGameScreenState extends State<CameraGameScreen>
    with SingleTickerProviderStateMixin {
  late final BrushingSessionController _controller;
  late final AnimationController _characterAnimation;
  StreamSubscription<void>? _volumeButtonSubscription;
  CameraController? _cameraController;
  Future<void>? _cameraFuture;

  @override
  void initState() {
    super.initState();
    _controller = BrushingSessionController(
      brushingDurationSeconds: widget.settings.brushingDurationSeconds,
      zoneOrder: widget.settings.zoneOrder,
    )..start();
    _controller.addListener(_handleSessionChanged);
    _configureVolumePause();
    _characterAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.94,
      upperBound: 1.05,
    )..repeat(reverse: true);
    _initializePlainCamera();
  }

  void _configureVolumePause() {
    final volumePauseEnabled =
        widget.settings.allowsVolumePause && !widget.settings.pauseLockEnabled;
    VolumeButtonService.instance.setEnabled(volumePauseEnabled);
    if (!volumePauseEnabled) {
      return;
    }
    _volumeButtonSubscription = VolumeButtonService.instance.presses.listen((
      _,
    ) {
      _controller.togglePause();
    });
  }

  Future<void> _initializePlainCamera() async {
    CameraDescription? frontCamera;
    for (final camera in widget.availableCameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        frontCamera = camera;
        break;
      }
    }

    if (frontCamera == null) {
      return;
    }

    final controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _cameraController = controller;
    _cameraFuture = controller.initialize();
  }

  void _handleSessionChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    VolumeButtonService.instance.setEnabled(false);
    _volumeButtonSubscription?.cancel();
    _controller
      ..removeListener(_handleSessionChanged)
      ..dispose();
    _cameraController?.dispose();
    _characterAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _screenPauseEnabled ? _controller.togglePause : null,
        onLongPress: _screenPauseLocked ? _controller.togglePause : null,
        child: Stack(
          children: [
            Positioned.fill(child: _buildPlainCameraLayer(context)),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.transparent,
                      _themeColor.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _SessionHeader(controller: _controller),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: _CharacterThemeOverlay(
                                character: widget.character,
                              ),
                            ),
                            Positioned.fill(
                              child: _BrushingGuideOverlay(
                                zone: _controller.currentZone,
                                remainingPlaque: _controller.remainingPlaque,
                                color: _themeColor,
                              ),
                            ),
                            if (_controller.isPaused)
                              Positioned.fill(
                                child: _PausedOverlay(
                                  locked: widget.settings.pauseLockEnabled,
                                ),
                              ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: _CharacterReaction(
                                animation: _characterAnimation,
                                character: widget.character,
                                encouragement: _encouragement(context.l10n),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_controller.canAddParentTime)
                        FilledButton(
                          onPressed: _controller.addParentTime,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2C2A4A),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 16,
                            ),
                          ),
                          child: Text(context.l10n.plusThirtySeconds),
                        ),
                      if (_controller.phase == SessionPhase.done)
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(context.l10n.backToCharacters),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _screenPauseEnabled =>
      widget.settings.allowsScreenPause && !widget.settings.pauseLockEnabled;

  bool get _screenPauseLocked =>
      widget.settings.allowsScreenPause && widget.settings.pauseLockEnabled;

  Color get _themeColor => switch (widget.character) {
    BrushingCharacter.fox => const Color(0xFFF28B50),
    BrushingCharacter.gator => const Color(0xFF43B49D),
  };

  Widget _buildPlainCameraLayer(BuildContext context) {
    if (_cameraController == null || _cameraFuture == null) {
      return _FallbackCameraBackground(
        message: context.l10n.cameraPreviewFallback,
      );
    }

    return FutureBuilder<void>(
      future: _cameraFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraController!.value.previewSize?.height ?? 1,
              height: _cameraController!.value.previewSize?.width ?? 1,
              child: CameraPreview(_cameraController!),
            ),
          );
        }

        if (snapshot.hasError) {
          return _FallbackCameraBackground(
            message: context.l10n.cameraPreviewFallback,
          );
        }

        return const ColoredBox(
          color: Color(0xFFB8F2E6),
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  String _encouragement(AppLocalizations l10n) {
    if (_controller.phase == SessionPhase.waitingForParent) {
      return l10n.nowItsYourParentsTurn;
    }
    if (_controller.phase == SessionPhase.done) {
      return l10n.greatJob;
    }
    if (_controller.isPaused) {
      return l10n.paused;
    }
    if (_controller.remainingPlaque <= 2) {
      return l10n.almostDone;
    }
    return l10n.keepGoing;
  }
}

class _CharacterThemeOverlay extends StatelessWidget {
  const _CharacterThemeOverlay({required this.character});

  final BrushingCharacter character;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: switch (character) {
        BrushingCharacter.fox => const _FoxThemeOverlay(),
        BrushingCharacter.gator => const _GatorThemeOverlay(),
      },
    );
  }
}

class _FoxThemeOverlay extends StatelessWidget {
  const _FoxThemeOverlay();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(
          top: 36,
          left: 28,
          child: _FoxEarDecoration(flip: false),
        ),
        const Positioned(
          top: 36,
          right: 28,
          child: _FoxEarDecoration(flip: true),
        ),
        Positioned(
          left: 18,
          top: 136,
          child: _GlowOrb(
            size: 68,
            color: const Color(0xFFF28B50).withValues(alpha: 0.22),
          ),
        ),
        Positioned(
          right: 14,
          top: 184,
          child: _GlowOrb(
            size: 54,
            color: const Color(0xFFFFC37A).withValues(alpha: 0.22),
          ),
        ),
      ],
    );
  }
}

class _GatorThemeOverlay extends StatelessWidget {
  const _GatorThemeOverlay();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(
          top: 24,
          left: 18,
          right: 18,
          child: _GatorBrowDecoration(),
        ),
        Positioned(
          left: 22,
          top: 146,
          child: _GlowOrb(
            size: 54,
            color: const Color(0xFF43B49D).withValues(alpha: 0.18),
          ),
        ),
        Positioned(
          right: 22,
          top: 162,
          child: _GlowOrb(
            size: 46,
            color: const Color(0xFF7AD9C5).withValues(alpha: 0.18),
          ),
        ),
      ],
    );
  }
}

class _BrushingGuideOverlay extends StatelessWidget {
  const _BrushingGuideOverlay({
    required this.zone,
    required this.remainingPlaque,
    required this.color,
  });

  final BrushingZone zone;
  final int remainingPlaque;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _BrushingGuidePainter(
          zone: zone,
          remainingPlaque: remainingPlaque,
          color: color,
        ),
      ),
    );
  }
}

class _BrushingGuidePainter extends CustomPainter {
  const _BrushingGuidePainter({
    required this.zone,
    required this.remainingPlaque,
    required this.color,
  });

  final BrushingZone zone;
  final int remainingPlaque;
  final Color color;

  static const _offsets = <Offset>[
    Offset(-0.22, -0.18),
    Offset(0.0, -0.22),
    Offset(0.2, -0.12),
    Offset(-0.16, 0.04),
    Offset(0.12, 0.06),
    Offset(-0.04, 0.18),
    Offset(0.2, 0.16),
    Offset(-0.22, 0.22),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final mouthArea = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.56),
      width: size.width * 0.46,
      height: size.height * 0.22,
    );

    final zoneRect = switch (zone) {
      BrushingZone.topLeft => Rect.fromLTWH(
        mouthArea.left,
        mouthArea.top,
        mouthArea.width / 2,
        mouthArea.height / 2,
      ),
      BrushingZone.topRight => Rect.fromLTWH(
        mouthArea.center.dx,
        mouthArea.top,
        mouthArea.width / 2,
        mouthArea.height / 2,
      ),
      BrushingZone.bottomLeft => Rect.fromLTWH(
        mouthArea.left,
        mouthArea.center.dy,
        mouthArea.width / 2,
        mouthArea.height / 2,
      ),
      BrushingZone.bottomRight => Rect.fromLTWH(
        mouthArea.center.dx,
        mouthArea.center.dy,
        mouthArea.width / 2,
        mouthArea.height / 2,
      ),
    }.deflate(6);

    final guidePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(mouthArea, const Radius.circular(36)),
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(mouthArea, const Radius.circular(36)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(zoneRect, const Radius.circular(26)),
      guidePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(zoneRect, const Radius.circular(26)),
      borderPaint,
    );

    for (var i = 0; i < _offsets.length; i++) {
      if (i >= remainingPlaque) {
        continue;
      }
      final center = Offset(
        zoneRect.center.dx + zoneRect.width * _offsets[i].dx,
        zoneRect.center.dy + zoneRect.height * _offsets[i].dy,
      );
      final radius = i.isEven ? zoneRect.width * 0.11 : zoneRect.width * 0.095;
      _paintPlaque(canvas, center, radius);
    }
  }

  void _paintPlaque(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFFFF4C1));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFFFD166)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(
      center,
      radius * 0.18,
      Paint()..color = const Color(0xFFC98400),
    );
  }

  @override
  bool shouldRepaint(covariant _BrushingGuidePainter oldDelegate) {
    return oldDelegate.zone != zone ||
        oldDelegate.remainingPlaque != remainingPlaque ||
        oldDelegate.color != color;
  }
}

class _FoxEarDecoration extends StatelessWidget {
  const _FoxEarDecoration({required this.flip});

  final bool flip;

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(flip ? -1.0 : 1.0, 1.0, 1.0),
      child: CustomPaint(size: const Size(74, 88), painter: _FoxEarPainter()),
    );
  }
}

class _FoxEarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final outer = Path()
      ..moveTo(size.width * 0.2, size.height)
      ..lineTo(size.width * 0.72, size.height * 0.06)
      ..lineTo(size.width, size.height)
      ..close();
    final inner = Path()
      ..moveTo(size.width * 0.42, size.height * 0.76)
      ..lineTo(size.width * 0.7, size.height * 0.22)
      ..lineTo(size.width * 0.84, size.height * 0.8)
      ..close();

    canvas.drawPath(
      outer,
      Paint()..color = const Color(0xFFF28B50).withValues(alpha: 0.92),
    );
    canvas.drawPath(
      inner,
      Paint()..color = const Color(0xFFFFD7C2).withValues(alpha: 0.96),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GatorBrowDecoration extends StatelessWidget {
  const _GatorBrowDecoration();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3.4,
      child: CustomPaint(painter: _GatorBrowPainter()),
    );
  }
}

class _GatorBrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..color = const Color(0xFF43B49D).withValues(alpha: 0.94)
      ..style = PaintingStyle.fill;
    final highlightPaint = Paint()
      ..color = const Color(0xFF76D7C4).withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;
    final eyePaint = Paint()..color = Colors.white.withValues(alpha: 0.96);
    final pupilPaint = Paint()..color = const Color(0xFF214C44);
    final toothPaint = Paint()..color = Colors.white.withValues(alpha: 0.98);

    final ridge = Path()
      ..moveTo(size.width * 0.08, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.2,
        size.height * 0.05,
        size.width * 0.34,
        size.height * 0.12,
      )
      ..lineTo(size.width * 0.46, size.height * 0.22)
      ..quadraticBezierTo(
        size.width * 0.5,
        0,
        size.width * 0.54,
        size.height * 0.22,
      )
      ..lineTo(size.width * 0.66, size.height * 0.12)
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.05,
        size.width * 0.92,
        size.height * 0.78,
      )
      ..lineTo(size.width * 0.82, size.height * 0.88)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.66,
        size.width * 0.18,
        size.height * 0.88,
      )
      ..close();

    canvas.drawShadow(ridge, const Color(0x22000000), 10, false);
    canvas.drawPath(ridge, basePaint);

    final highlight = Path()
      ..moveTo(size.width * 0.15, size.height * 0.68)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.18,
        size.width * 0.39,
        size.height * 0.2,
      )
      ..lineTo(size.width * 0.5, size.height * 0.3)
      ..lineTo(size.width * 0.61, size.height * 0.2)
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.18,
        size.width * 0.85,
        size.height * 0.68,
      )
      ..lineTo(size.width * 0.77, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.56,
        size.width * 0.23,
        size.height * 0.72,
      )
      ..close();
    canvas.drawPath(highlight, highlightPaint);

    final leftEye = Rect.fromCenter(
      center: Offset(size.width * 0.34, size.height * 0.55),
      width: size.width * 0.12,
      height: size.height * 0.18,
    );
    final rightEye = Rect.fromCenter(
      center: Offset(size.width * 0.66, size.height * 0.55),
      width: size.width * 0.12,
      height: size.height * 0.18,
    );
    canvas.drawOval(leftEye, eyePaint);
    canvas.drawOval(rightEye, eyePaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: leftEye.center,
          width: leftEye.width * 0.18,
          height: leftEye.height * 0.84,
        ),
        const Radius.circular(4),
      ),
      pupilPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: rightEye.center,
          width: rightEye.width * 0.18,
          height: rightEye.height * 0.84,
        ),
        const Radius.circular(4),
      ),
      pupilPaint,
    );

    for (final x in <double>[0.26, 0.38, 0.5, 0.62, 0.74]) {
      final tooth = Path()
        ..moveTo(size.width * x - 8, size.height * 0.88)
        ..lineTo(size.width * x + 8, size.height * 0.88)
        ..lineTo(size.width * x, size.height)
        ..close();
      canvas.drawPath(tooth, toothPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _PausedOverlay extends StatelessWidget {
  const _PausedOverlay({required this.locked});

  final bool locked;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.26)),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.pause_circle_filled_rounded,
                  size: 44,
                  color: Color(0xFF2C2A4A),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.paused,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF2C2A4A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  locked ? l10n.longPressToResume : l10n.tapToResume,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5D5A88),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({required this.controller});

  final BrushingSessionController controller;

  @override
  Widget build(BuildContext context) {
    final minutes = (controller.secondsRemaining ~/ 60).toString().padLeft(
      1,
      '0',
    );
    final seconds = (controller.secondsRemaining % 60).toString().padLeft(
      2,
      '0',
    );
    final l10n = context.l10n;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$minutes:$seconds',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF2C2A4A),
                  ),
                ),
                const Spacer(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF8F5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Text(
                      controller.phase == SessionPhase.brushing
                          ? l10n.zoneName(controller.currentZone)
                          : l10n.parentsTurn,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2C2A4A),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 12,
                value: _progressValue(),
                backgroundColor: const Color(0xFFEDE7DA),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF49B7A5),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _supportingText(l10n),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF5D5A88),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _progressValue() {
    return switch (controller.phase) {
      SessionPhase.brushing =>
        (controller.brushingDurationSeconds - controller.secondsRemaining) /
            controller.brushingDurationSeconds,
      SessionPhase.waitingForParent => 1,
      SessionPhase.parentExtension =>
        1 -
            (controller.secondsRemaining /
                BrushingSessionController.extraDurationSeconds),
      SessionPhase.done => 1,
    };
  }

  String _supportingText(AppLocalizations l10n) {
    return switch (controller.phase) {
      SessionPhase.brushing => l10n.cleanZoneInstruction(
        l10n.zoneName(controller.currentZone),
      ),
      SessionPhase.waitingForParent => l10n.nowItsYourParentsTurn,
      SessionPhase.parentExtension => l10n.keepBrushingTogether,
      SessionPhase.done => l10n.sessionComplete,
    };
  }
}

class _CharacterReaction extends StatelessWidget {
  const _CharacterReaction({
    required this.animation,
    required this.character,
    required this.encouragement,
  });

  final Animation<double> animation;
  final BrushingCharacter character;
  final String encouragement;

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: animation,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(character.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                encouragement,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2C2A4A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FallbackCameraBackground extends StatelessWidget {
  const _FallbackCameraBackground({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8ED9C4), Color(0xFFFFD6A5), Color(0xFFF7A072)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2C2A4A),
            ),
          ),
        ),
      ),
    );
  }
}
