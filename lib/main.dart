import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  List<CameraDescription> cameras = const <CameraDescription>[];
  try {
    cameras = await availableCameras();
  } catch (_) {
    cameras = const <CameraDescription>[];
  }

  runApp(BrushingApp(availableCameras: cameras));
}
