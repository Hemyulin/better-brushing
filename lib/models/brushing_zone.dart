import 'package:flutter/widgets.dart';

enum BrushingZone { topLeft, topRight, bottomLeft, bottomRight }

extension BrushingZoneLayout on BrushingZone {
  Alignment get alignment => switch (this) {
    BrushingZone.topLeft => Alignment.topLeft,
    BrushingZone.topRight => Alignment.topRight,
    BrushingZone.bottomLeft => Alignment.bottomLeft,
    BrushingZone.bottomRight => Alignment.bottomRight,
  };

  Alignment get plaqueAlignment => switch (this) {
    BrushingZone.topLeft => const Alignment(-0.62, -0.72),
    BrushingZone.topRight => const Alignment(0.62, -0.72),
    BrushingZone.bottomLeft => const Alignment(-0.62, 0.28),
    BrushingZone.bottomRight => const Alignment(0.62, 0.28),
  };
}
