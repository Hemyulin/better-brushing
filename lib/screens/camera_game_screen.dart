import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mediapipe_face_mesh/mediapipe_face_mesh.dart';

import '../controllers/brushing_session_controller.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../models/brushing_zone.dart';
import '../models/character.dart';
import '../services/volume_button_service.dart';
import '../utils/face_mesh_camera_image_adapter.dart';

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
    with TickerProviderStateMixin {
  late final BrushingSessionController _controller;
  late final AnimationController _characterAnimation;
  late final AnimationController _zoneChangeAnimation;
  StreamSubscription<void>? _volumeButtonSubscription;
  CameraController? _cameraController;
  Future<void>? _cameraFuture;
  FaceDetectorProcessor? _faceDetector;
  Rect? _trackedFaceBounds;
  late BrushingZone _lastAnimatedZone;
  DateTime _lastFaceFrameStartedAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _isProcessingFaceFrame = false;
  bool _isStreamingCameraImages = false;

  static const Map<DeviceOrientation, int> _deviceOrientationDegrees = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void initState() {
    super.initState();
    _controller = BrushingSessionController(
      brushingDurationSeconds: widget.settings.brushingDurationSeconds,
      zoneOrder: widget.settings.zoneOrder,
    )..start();
    _lastAnimatedZone = _controller.currentZone;
    _controller.addListener(_handleSessionChanged);
    _configureVolumePause();
    _characterAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.94,
      upperBound: 1.05,
    )..repeat(reverse: true);
    _zoneChangeAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
      value: 1,
    );
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
      imageFormatGroup: Platform.isIOS
          ? ImageFormatGroup.bgra8888
          : ImageFormatGroup.nv21,
    );
    _cameraController = controller;
    _cameraFuture = controller.initialize().then((_) => _startFaceTracking());
  }

  Future<void> _startFaceTracking() async {
    final controller = _cameraController;
    if (controller == null || controller.value.isStreamingImages) {
      return;
    }

    try {
      _faceDetector ??= await FaceDetectorProcessor.create(
        delegate: FaceMeshDelegate.xnnpack,
        maxResults: 1,
        minDetectionConfidence: 0.45,
        roiScaleY: 1.7,
        roiShiftY: -0.2,
      );
      await controller.startImageStream(_processCameraImage);
      _isStreamingCameraImages = true;
    } catch (_) {
      _isStreamingCameraImages = false;
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessingFaceFrame || !mounted) {
      return;
    }
    final now = DateTime.now();
    if (now.difference(_lastFaceFrameStartedAt).inMilliseconds < 70) {
      return;
    }

    final detector = _faceDetector;
    final controller = _cameraController;
    final rotationDegrees = controller == null
        ? null
        : _rotationCompensationDegrees(controller);
    if (detector == null || controller == null || rotationDegrees == null) {
      return;
    }

    _isProcessingFaceFrame = true;
    _lastFaceFrameStartedAt = now;
    try {
      final isFrontCamera =
          controller.description.lensDirection == CameraLensDirection.front;
      FaceDetectionResult? result;
      if (Platform.isAndroid) {
        final nv21Image = FaceMeshCameraImageAdapter.toNv21(image);
        if (nv21Image == null) {
          return;
        }
        result = detector.processNv21(
          nv21Image,
          rotationDegrees: rotationDegrees,
          mirrorHorizontal: isFrontCamera,
        );
      } else if (Platform.isIOS) {
        final bgraImage = FaceMeshCameraImageAdapter.toBgra(image);
        if (bgraImage == null) {
          return;
        }
        result = detector.process(
          bgraImage,
          rotationDegrees: rotationDegrees,
          mirrorHorizontal: isFrontCamera,
        );
      }

      final faceBounds = _faceBoundsFromDetection(result?.primaryDetection);
      final adjustedFaceBounds = faceBounds == null
          ? null
          : _shiftFaceBounds(
              faceBounds,
              horizontal: widget.settings.trackingHorizontalOffset,
              vertical: widget.settings.trackingVerticalOffset,
            );
      if (!mounted) {
        return;
      }
      setState(() {
        _trackedFaceBounds = _smoothFaceBounds(
          _trackedFaceBounds,
          adjustedFaceBounds,
        );
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _trackedFaceBounds = null;
        });
      }
    } finally {
      _isProcessingFaceFrame = false;
    }
  }

  int? _rotationCompensationDegrees(CameraController controller) {
    final deviceRotation =
        _deviceOrientationDegrees[controller.value.deviceOrientation];
    if (deviceRotation == null) {
      return null;
    }
    final sensorOrientation = controller.description.sensorOrientation;
    if (Platform.isAndroid) {
      if (controller.description.lensDirection == CameraLensDirection.front) {
        return (sensorOrientation + deviceRotation) % 360;
      }
      return (sensorOrientation - deviceRotation + 360) % 360;
    }
    if (Platform.isIOS) {
      return deviceRotation;
    }
    return null;
  }

  Rect? _faceBoundsFromDetection(FaceDetection? detection) {
    if (detection == null) {
      return null;
    }

    return Rect.fromLTRB(
      detection.left.clamp(0.0, 1.0),
      detection.top.clamp(0.0, 1.0),
      detection.right.clamp(0.0, 1.0),
      detection.bottom.clamp(0.0, 1.0),
    );
  }

  Rect _shiftFaceBounds(
    Rect bounds, {
    required double horizontal,
    required double vertical,
  }) {
    final dx = horizontal * 0.18;
    final dy = vertical * 0.18;
    final shiftedLeft = (bounds.left + dx).clamp(0.0, 1.0 - bounds.width);
    final shiftedTop = (bounds.top + dy).clamp(0.0, 1.0 - bounds.height);
    return Rect.fromLTWH(shiftedLeft, shiftedTop, bounds.width, bounds.height);
  }

  Rect? _smoothFaceBounds(Rect? previous, Rect? next) {
    if (next == null) {
      return null;
    }
    if (previous == null) {
      return next;
    }

    const response = 0.62;
    return Rect.fromLTRB(
      _lerp(previous.left, next.left, response),
      _lerp(previous.top, next.top, response),
      _lerp(previous.right, next.right, response),
      _lerp(previous.bottom, next.bottom, response),
    );
  }

  double _lerp(double from, double to, double t) {
    return from + (to - from) * t;
  }

  void _handleSessionChanged() {
    if (!mounted) {
      return;
    }
    if (_controller.phase == SessionPhase.brushing &&
        _controller.currentZone != _lastAnimatedZone) {
      _lastAnimatedZone = _controller.currentZone;
      _zoneChangeAnimation.forward(from: 0);
    }
    setState(() {});
  }

  @override
  void dispose() {
    VolumeButtonService.instance.setEnabled(false);
    _volumeButtonSubscription?.cancel();
    if (_isStreamingCameraImages == true) {
      _cameraController?.stopImageStream();
    }
    _faceDetector?.close();
    _controller
      ..removeListener(_handleSessionChanged)
      ..dispose();
    _cameraController?.dispose();
    _characterAnimation.dispose();
    _zoneChangeAnimation.dispose();
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
                              child: CharacterThemeOverlay(
                                character: widget.character,
                                faceBounds: _trackedFaceBounds,
                                zoneChangeAnimation: _zoneChangeAnimation,
                                settings: widget.settings,
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

class CharacterThemeOverlay extends StatelessWidget {
  const CharacterThemeOverlay({
    super.key,
    required this.character,
    required this.faceBounds,
    required this.zoneChangeAnimation,
    required this.settings,
  });

  final BrushingCharacter character;
  final Rect? faceBounds;
  final Animation<double> zoneChangeAnimation;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: zoneChangeAnimation,
      builder: (context, _) {
        return IgnorePointer(
          child: switch (character) {
            BrushingCharacter.fox => _FoxThemeOverlay(
              faceBounds: faceBounds,
              zoneChangeProgress: zoneChangeAnimation.value,
              earHeightOffset: settings.foxEarHeightOffset,
              earSpacingOffset: settings.foxEarSpacingOffset,
            ),
            BrushingCharacter.gator => _GatorThemeOverlay(
              faceBounds: faceBounds,
              zoneChangeProgress: zoneChangeAnimation.value,
              horizontalOffset: settings.gatorHorizontalOffset,
              verticalOffset: settings.gatorVerticalOffset,
            ),
          },
        );
      },
    );
  }
}

class _FoxThemeOverlay extends StatelessWidget {
  const _FoxThemeOverlay({
    required this.faceBounds,
    required this.zoneChangeProgress,
    required this.earHeightOffset,
    required this.earSpacingOffset,
  });

  final Rect? faceBounds;
  final double zoneChangeProgress;
  final double earHeightOffset;
  final double earSpacingOffset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final face = faceBounds;
        const earWidth = 74.0;
        const earHeight = 88.0;
        final faceWidth = face == null
            ? constraints.maxWidth * 0.54
            : face.width * constraints.maxWidth;
        final faceHeight = face == null
            ? constraints.maxHeight * 0.34
            : face.height * constraints.maxHeight;
        final headCenterX = face == null
            ? constraints.maxWidth * 0.5
            : face.center.dx * constraints.maxWidth;
        final headTop = face == null
            ? constraints.maxHeight * 0.18
            : (face.top * constraints.maxHeight - faceHeight * 0.82);
        final maxEarGap = math.max(110.0, constraints.maxWidth - earWidth - 16);
        final earGap = (faceWidth * 0.92 + earSpacingOffset * 90).clamp(
          110.0,
          maxEarGap,
        );
        final earTop =
            (headTop -
                    earHeight * 1.02 +
                    earHeightOffset * constraints.maxHeight * 0.16)
                .clamp(8.0, constraints.maxHeight - earHeight);
        final outwardTurn =
            math.sin(Curves.easeInOut.transform(zoneChangeProgress) * math.pi) *
            0.48;
        final groupWidth = earGap + earWidth;
        final clampedHeadCenterX = headCenterX.clamp(
          groupWidth / 2 + 8,
          constraints.maxWidth - groupWidth / 2 - 8,
        );
        final leftEarLeft = clampedHeadCenterX - earGap / 2 - earWidth * 0.5;
        final rightEarRight =
            constraints.maxWidth -
            (clampedHeadCenterX + earGap / 2 + earWidth * 0.5);

        return Stack(
          children: [
            Positioned(
              top: earTop,
              left: leftEarLeft,
              child: _FoxEarDecoration(flip: false, outwardTurn: outwardTurn),
            ),
            Positioned(
              top: earTop,
              right: rightEarRight,
              child: _FoxEarDecoration(flip: true, outwardTurn: outwardTurn),
            ),
          ],
        );
      },
    );
  }
}

class _GatorThemeOverlay extends StatelessWidget {
  const _GatorThemeOverlay({
    required this.faceBounds,
    required this.zoneChangeProgress,
    required this.horizontalOffset,
    required this.verticalOffset,
  });

  final Rect? faceBounds;
  final double zoneChangeProgress;
  final double horizontalOffset;
  final double verticalOffset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final face = faceBounds;
        final faceWidth = face == null
            ? constraints.maxWidth * 0.54
            : face.width * constraints.maxWidth;
        final faceHeight = face == null
            ? constraints.maxHeight * 0.34
            : face.height * constraints.maxHeight;
        final headCenterX = face == null
            ? constraints.maxWidth * 0.5
            : face.center.dx * constraints.maxWidth +
                  horizontalOffset * constraints.maxWidth * 0.18;
        final headTop = face == null
            ? constraints.maxHeight * 0.18
            : (face.top * constraints.maxHeight -
                  faceHeight * 0.82 +
                  verticalOffset * constraints.maxHeight * 0.16);
        final browWidth = face == null
            ? constraints.maxWidth - 36
            : (faceWidth * 1.78).clamp(250.0, constraints.maxWidth - 16);
        final browHeight = browWidth / 3.4;
        final browLeft = face == null
            ? 18.0
            : (headCenterX - browWidth / 2).clamp(
                18.0,
                constraints.maxWidth - browWidth - 18,
              );
        final browTop = face == null
            ? 24.0
            : headTop.clamp(8.0, constraints.maxHeight - browHeight);
        final happyEyes = math.sin(zoneChangeProgress * math.pi);

        return Stack(
          children: [
            Positioned(
              top: browTop,
              left: browLeft,
              width: browWidth,
              child: _GatorBrowDecoration(happyEyes: happyEyes),
            ),
          ],
        );
      },
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
  const _FoxEarDecoration({required this.flip, required this.outwardTurn});

  final bool flip;
  final double outwardTurn;

  @override
  Widget build(BuildContext context) {
    final turnDirection = flip ? -1.0 : 1.0;
    return Transform(
      alignment: flip ? Alignment.centerLeft : Alignment.centerRight,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(outwardTurn * turnDirection)
        ..multiply(Matrix4.diagonal3Values(flip ? -1.0 : 1.0, 1.0, 1.0)),
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
  const _GatorBrowDecoration({required this.happyEyes});

  final double happyEyes;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3.4,
      child: CustomPaint(painter: _GatorBrowPainter(happyEyes: happyEyes)),
    );
  }
}

class _GatorBrowPainter extends CustomPainter {
  const _GatorBrowPainter({required this.happyEyes});

  final double happyEyes;

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..color = const Color(0xFF43B49D).withValues(alpha: 0.94)
      ..style = PaintingStyle.fill;
    final highlightPaint = Paint()
      ..color = const Color(0xFF76D7C4).withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;
    final eyePaint = Paint()..color = Colors.white.withValues(alpha: 0.96);
    final pupilPaint = Paint()
      ..color = const Color(
        0xFF214C44,
      ).withValues(alpha: (1 - happyEyes).clamp(0.0, 1.0));
    final happyEyePaint = Paint()
      ..color = const Color(
        0xFF214C44,
      ).withValues(alpha: happyEyes.clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (size.width * 0.02).clamp(3.0, 7.0);
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

    if (happyEyes < 0.98) {
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
    }

    canvas.drawArc(
      Rect.fromCenter(
        center: leftEye.center.translate(0, -leftEye.height * 0.04),
        width: leftEye.width * 0.72,
        height: leftEye.height * 0.62,
      ),
      math.pi + 0.2,
      math.pi - 0.4,
      false,
      happyEyePaint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: rightEye.center.translate(0, -rightEye.height * 0.04),
        width: rightEye.width * 0.72,
        height: rightEye.height * 0.62,
      ),
      math.pi + 0.2,
      math.pi - 0.4,
      false,
      happyEyePaint,
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
  bool shouldRepaint(covariant _GatorBrowPainter oldDelegate) {
    return oldDelegate.happyEyes != happyEyes;
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
