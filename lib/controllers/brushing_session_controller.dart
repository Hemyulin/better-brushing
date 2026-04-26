import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/brushing_zone.dart';

enum SessionPhase { brushing, waitingForParent, parentExtension, done }

class BrushingSessionController extends ChangeNotifier {
  static const int baseDurationSeconds = 120;
  static const int extraDurationSeconds = 30;
  static const int zoneDurationSeconds = 30;
  static const int plaquePerZone = 8;

  Timer? _timer;
  SessionPhase _phase = SessionPhase.brushing;
  int _secondsRemaining = baseDurationSeconds;
  int _completedZones = 0;

  SessionPhase get phase => _phase;
  int get secondsRemaining => _secondsRemaining;
  int get remainingPlaque {
    if (_phase != SessionPhase.brushing) {
      return 0;
    }

    final cleanedPlaque = (zoneProgress * plaquePerZone).floor();
    return max(0, plaquePerZone - cleanedPlaque);
  }

  int get completedZones => _completedZones;
  bool get isFinished =>
      _phase == SessionPhase.waitingForParent || _phase == SessionPhase.done;
  bool get canAddParentTime => _phase == SessionPhase.waitingForParent;
  bool get isSessionActive =>
      _phase == SessionPhase.brushing || _phase == SessionPhase.parentExtension;

  BrushingZone get currentZone {
    final zoneIndex = min(
      (baseDurationSeconds - _secondsRemaining) ~/ zoneDurationSeconds,
      BrushingZone.values.length - 1,
    );
    return BrushingZone.values[zoneIndex];
  }

  double get zoneProgress {
    if (_phase != SessionPhase.brushing) {
      return 1;
    }
    final elapsedInZone =
        (baseDurationSeconds - _secondsRemaining) % zoneDurationSeconds;
    return elapsedInZone / zoneDurationSeconds;
  }

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_secondsRemaining <= 1) {
      _handlePhaseEnd();
      return;
    }

    final previousZone = _phase == SessionPhase.brushing ? currentZone : null;
    _secondsRemaining -= 1;

    if (_phase == SessionPhase.brushing &&
        previousZone != null &&
        previousZone != currentZone) {
      _completedZones += 1;
    }

    notifyListeners();
  }

  void _handlePhaseEnd() {
    if (_phase == SessionPhase.brushing) {
      _completedZones = BrushingZone.values.length;
      _secondsRemaining = 0;
      _phase = SessionPhase.waitingForParent;
      _timer?.cancel();
      notifyListeners();
      return;
    }

    if (_phase == SessionPhase.parentExtension) {
      _secondsRemaining = 0;
      _phase = SessionPhase.done;
      _timer?.cancel();
      notifyListeners();
    }
  }

  void addParentTime() {
    if (!canAddParentTime) {
      return;
    }

    _phase = SessionPhase.parentExtension;
    _secondsRemaining = extraDurationSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
