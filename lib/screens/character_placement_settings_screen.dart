import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mediapipe_face_mesh/mediapipe_face_mesh.dart';

import '../controllers/app_settings_controller.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../models/character.dart';
import '../utils/face_mesh_camera_image_adapter.dart';
import 'camera_game_screen.dart';

class CharacterPlacementSettingsScreen extends StatefulWidget {
  const CharacterPlacementSettingsScreen({
    super.key,
    required this.availableCameras,
    required this.settingsController,
  });

  final List<CameraDescription> availableCameras;
  final AppSettingsController settingsController;

  @override
  State<CharacterPlacementSettingsScreen> createState() =>
      _CharacterPlacementSettingsScreenState();
}

class _CharacterPlacementSettingsScreenState
    extends State<CharacterPlacementSettingsScreen> {
  CameraController? _cameraController;
  Future<void>? _cameraFuture;
  FaceDetectorProcessor? _faceDetector;
  Rect? _trackedFaceBounds;
  DateTime _lastFaceFrameStartedAt = DateTime.fromMillisecondsSinceEpoch(0);
  BrushingCharacter _selectedCharacter = BrushingCharacter.fox;
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
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
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
    if (mounted) {
      setState(() {});
    }
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
              horizontal:
                  widget.settingsController.settings.trackingHorizontalOffset,
              vertical:
                  widget.settingsController.settings.trackingVerticalOffset,
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

  @override
  void dispose() {
    if (_isStreamingCameraImages) {
      _cameraController?.stopImageStream();
    }
    _faceDetector?.close();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AnimatedBuilder(
      animation: widget.settingsController,
      builder: (context, _) {
        final settings = widget.settingsController.settings;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(l10n.characterPlacementTitle),
            foregroundColor: Colors.white,
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              _buildCameraLayer(context),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.38),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.62),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              CharacterThemeOverlay(
                character: _selectedCharacter,
                faceBounds: _trackedFaceBounds,
                zoneChangeAnimation: const AlwaysStoppedAnimation(1),
                settings: settings,
              ),
              SafeArea(child: _buildControls(context, settings)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCameraLayer(BuildContext context) {
    final cameraFuture = _cameraFuture;
    final controller = _cameraController;

    if (cameraFuture == null || controller == null) {
      return _CalibrationFallback(message: context.l10n.cameraPreviewFallback);
    }

    return FutureBuilder<void>(
      future: cameraFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            !controller.value.isInitialized) {
          return const ColoredBox(
            color: Color(0xFF1C1B2F),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.previewSize?.height ?? 1,
            height: controller.value.previewSize?.width ?? 1,
            child: CameraPreview(controller),
          ),
        );
      },
    );
  }

  Widget _buildControls(BuildContext context, AppSettings settings) {
    final l10n = context.l10n;

    final leftSliders = _selectedCharacter == BrushingCharacter.fox
        ? [
            _EdgeSlider(
              label: l10n.foxEarHeightLabel,
              topLabel: l10n.placementHigher,
              bottomLabel: l10n.placementLower,
              topIsMax: false,
              value: settings.foxEarHeightOffset,
              onChanged: (value) =>
                  _update(settings.copyWith(foxEarHeightOffset: value)),
            ),
            _EdgeSlider(
              label: l10n.trackingVerticalLabel,
              topLabel: l10n.placementHigher,
              bottomLabel: l10n.placementLower,
              topIsMax: false,
              value: settings.trackingVerticalOffset,
              onChanged: (value) =>
                  _update(settings.copyWith(trackingVerticalOffset: value)),
            ),
          ]
        : [
            _EdgeSlider(
              label: l10n.gatorVerticalLabel,
              topLabel: l10n.placementHigher,
              bottomLabel: l10n.placementLower,
              topIsMax: false,
              value: settings.gatorVerticalOffset,
              onChanged: (value) =>
                  _update(settings.copyWith(gatorVerticalOffset: value)),
            ),
            _EdgeSlider(
              label: l10n.trackingVerticalLabel,
              topLabel: l10n.placementHigher,
              bottomLabel: l10n.placementLower,
              topIsMax: false,
              value: settings.trackingVerticalOffset,
              onChanged: (value) =>
                  _update(settings.copyWith(trackingVerticalOffset: value)),
            ),
          ];

    final rightSliders = _selectedCharacter == BrushingCharacter.fox
        ? [
            _EdgeSlider(
              label: l10n.foxEarSpacingLabel,
              topLabel: l10n.placementFarther,
              bottomLabel: l10n.placementCloser,
              value: settings.foxEarSpacingOffset,
              onChanged: (value) =>
                  _update(settings.copyWith(foxEarSpacingOffset: value)),
            ),
            _EdgeSlider(
              label: l10n.trackingHorizontalLabel,
              topLabel: l10n.placementRight,
              bottomLabel: l10n.placementLeft,
              value: settings.trackingHorizontalOffset,
              onChanged: (value) =>
                  _update(settings.copyWith(trackingHorizontalOffset: value)),
            ),
          ]
        : [
            _EdgeSlider(
              label: l10n.gatorHorizontalLabel,
              topLabel: l10n.placementRight,
              bottomLabel: l10n.placementLeft,
              value: settings.gatorHorizontalOffset,
              onChanged: (value) =>
                  _update(settings.copyWith(gatorHorizontalOffset: value)),
            ),
            _EdgeSlider(
              label: l10n.trackingHorizontalLabel,
              topLabel: l10n.placementRight,
              bottomLabel: l10n.placementLeft,
              value: settings.trackingHorizontalOffset,
              onChanged: (value) =>
                  _update(settings.copyWith(trackingHorizontalOffset: value)),
            ),
          ];

    return Stack(
      fit: StackFit.expand,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _SliderRail(sliders: leftSliders),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: _SliderRail(sliders: rightSliders),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => setState(
                      () => _selectedCharacter = BrushingCharacter.fox,
                    ),
                    icon: Text(BrushingCharacter.fox.emoji),
                    label: Text(l10n.characterName(BrushingCharacter.fox)),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          _selectedCharacter == BrushingCharacter.fox
                          ? const Color(0xFFF28B50)
                          : const Color(0xFF786F91),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => setState(
                      () => _selectedCharacter = BrushingCharacter.gator,
                    ),
                    icon: Text(BrushingCharacter.gator.emoji),
                    label: Text(l10n.characterName(BrushingCharacter.gator)),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          _selectedCharacter == BrushingCharacter.gator
                          ? const Color(0xFF43B49D)
                          : const Color(0xFF786F91),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _update(AppSettings settings) {
    return widget.settingsController.update(settings);
  }
}

class _SliderRail extends StatelessWidget {
  const _SliderRail({required this.sliders});

  final List<_EdgeSlider> sliders;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 92),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final slider in sliders) ...[
            slider,
            if (slider != sliders.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _EdgeSlider extends StatelessWidget {
  const _EdgeSlider({
    required this.label,
    required this.topLabel,
    required this.bottomLabel,
    this.topIsMax = true,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String topLabel;
  final String bottomLabel;
  final bool topIsMax;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            topLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          SizedBox(
            height: 164,
            child: RotatedBox(
              quarterTurns: -1,
              child: Slider(
                value: topIsMax ? value : -value,
                min: AppSettings.minCharacterOffset,
                max: AppSettings.maxCharacterOffset,
                divisions: 8,
                label: value.toStringAsFixed(2),
                onChanged: (value) => onChanged(topIsMax ? value : -value),
              ),
            ),
          ),
          Text(
            bottomLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _CalibrationFallback extends StatelessWidget {
  const _CalibrationFallback({required this.message});

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
